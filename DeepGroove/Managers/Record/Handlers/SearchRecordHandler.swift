import UIKit

final class SearchRecordHandler: IHandler {
    private let aiVisionAccessor: IAIVisionAccessor
    private let discogsAccessor: IDiscogsAccessor
    private let identificationEngine: IIdentificationEngine
    private let imageUtility: ImageUtility
    private let apiConfiguration: APIConfiguration

    init(
        aiVisionAccessor: IAIVisionAccessor,
        discogsAccessor: IDiscogsAccessor,
        identificationEngine: IIdentificationEngine,
        imageUtility: ImageUtility,
        apiConfiguration: APIConfiguration
    ) {
        self.aiVisionAccessor = aiVisionAccessor
        self.discogsAccessor = discogsAccessor
        self.identificationEngine = identificationEngine
        self.imageUtility = imageUtility
        self.apiConfiguration = apiConfiguration
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SearchRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let config = apiConfiguration
        let (anthropicKey, discogsToken) = await MainActor.run {
            (config.anthropicAPIKey, config.discogsToken)
        }

        switch req.source {
        case .photo(let image):
            if let barcode = imageUtility.detectBarcode(in: image) {
                let candidates = await searchByBarcode(barcode, token: discogsToken, correlationId: req.correlationId)
                if !candidates.isEmpty {
                    return SearchRecordResponse(correlationId: req.correlationId,
                                               candidates: candidates, userPhoto: image)
                }
            }
            let (identification, aiError) = await identifyViaAI(image: image, anthropicKey: anthropicKey)
            if let aiError, identification == nil {
                return SearchRecordResponse(correlationId: req.correlationId, errorMessage: aiError)
            }
            let candidates = await searchByIdentification(identification, token: discogsToken)
            return SearchRecordResponse(correlationId: req.correlationId,
                                        candidates: candidates,
                                        identification: identification,
                                        userPhoto: image)

        case .barcode(let code):
            let candidates = await searchByBarcode(code, token: discogsToken, correlationId: req.correlationId)
            return SearchRecordResponse(correlationId: req.correlationId, candidates: candidates)

        case .text(let artist, let albumTitle):
            let (candidates, correctedArtist, totalPages) = await searchByText(
                artist: artist, albumTitle: albumTitle,
                discogsToken: discogsToken, anthropicKey: anthropicKey,
                page: req.page
            )
            let effectiveArtist = correctedArtist ?? (artist.isEmpty ? nil : artist)
            let identification = AIIdentification(
                artist: effectiveArtist,
                albumTitle: albumTitle.isEmpty ? nil : albumTitle,
                year: nil, label: nil, catalogNumber: nil, genres: [], country: nil, rawJSON: ""
            )
            return SearchRecordResponse(correlationId: req.correlationId,
                                        candidates: candidates,
                                        identification: identification,
                                        currentPage: req.page,
                                        totalPages: totalPages,
                                        correctedArtist: correctedArtist)

        case .manual:
            return SearchRecordResponse(correlationId: req.correlationId, candidates: [])
        }
    }

    // MARK: - Private

    private func searchByText(
        artist: String, albumTitle: String,
        discogsToken: String?, anthropicKey: String, page: Int
    ) async -> (candidates: [DiscogsSearchResult], correctedArtist: String?, totalPages: Int) {
        let (filtered, pages) = await discogsTextSearch(
            artist: artist, albumTitle: albumTitle, token: discogsToken, page: page
        )
        if !filtered.isEmpty { return (filtered, nil, pages) }

        // Zero results after filtering — try AI name correction when we have an artist and key
        guard !artist.isEmpty, !anthropicKey.isEmpty else { return ([], nil, 1) }
        let correctionResponse = await aiVisionAccessor.load(
            CorrectArtistNameRequest(input: artist, apiKey: anthropicKey)
        )
        guard let corrected = (correctionResponse as? CorrectArtistNameResponse)?.correctedName,
              corrected.lowercased() != artist.lowercased() else { return ([], nil, 1) }

        let (retried, retriedPages) = await discogsTextSearch(
            artist: corrected, albumTitle: albumTitle, token: discogsToken, page: page
        )
        return (retried, corrected, retriedPages)
    }

    private func discogsTextSearch(
        artist: String, albumTitle: String,
        token: String?, page: Int
    ) async -> (candidates: [DiscogsSearchResult], totalPages: Int) {
        let discRequest: SearchDiscogsRequest
        if !artist.isEmpty && albumTitle.isEmpty {
            // Artist-only browse: apply country + format filters in the query to get
            // local studio albums, then filter tributes in code.
            discRequest = SearchDiscogsRequest(
                artist: artist,
                sort: "numhave",
                sortOrder: "desc",
                country: localDiscogsCountry(),
                format: "Album",
                token: token,
                page: page,
                perPage: 50
            )
        } else if !artist.isEmpty {
            // Artist + title: precise field search, no format/country filter so
            // box sets and foreign pressings (e.g. Pulse) are still findable.
            discRequest = SearchDiscogsRequest(
                artist: artist,
                releaseTitle: albumTitle,
                sort: "numhave",
                sortOrder: "desc",
                token: token,
                page: page,
                perPage: 50
            )
        } else {
            discRequest = SearchDiscogsRequest(
                query: albumTitle.isEmpty ? nil : albumTitle,
                sort: "numhave",
                sortOrder: "desc",
                token: token,
                page: page,
                perPage: 50
            )
        }
        let response = await discogsAccessor.load(discRequest)
        let discogsResponse = response as? SearchDiscogsResponse
        let raw = discogsResponse?.results ?? []
        let filtered = artist.isEmpty ? raw : filterByArtist(raw, artist: artist)
        let ranked = albumTitle.isEmpty ? filtered : rankByAlbumTitle(filtered, target: albumTitle)
        return (ranked, discogsResponse?.totalPages ?? 1)
    }

    private func localDiscogsCountry() -> String? {
        guard let regionCode = Locale.current.region?.identifier else { return nil }
        let map: [String: String] = [
            "US": "US", "GB": "UK", "CA": "Canada", "AU": "Australia",
            "DE": "Germany", "FR": "France", "JP": "Japan", "IT": "Italy",
            "ES": "Spain", "NL": "Netherlands", "SE": "Sweden", "NO": "Norway",
            "DK": "Denmark", "FI": "Finland", "BE": "Belgium", "CH": "Switzerland",
            "AT": "Austria", "NZ": "New Zealand", "BR": "Brazil", "MX": "Mexico"
        ]
        return map[regionCode]
    }

    // Stable sort: results matching the user's locale country float to the top,
    // preserving relative order within each tier (local vs. other).
    private func preferLocalCountry(_ results: [DiscogsSearchResult]) -> [DiscogsSearchResult] {
        guard let localCountry = localDiscogsCountry()?.lowercased() else { return results }
        var local: [DiscogsSearchResult] = []
        var other: [DiscogsSearchResult] = []
        for result in results {
            if result.country?.lowercased() == localCountry { local.append(result) }
            else { other.append(result) }
        }
        return local + other
    }

    // Keeps only results whose Discogs artist portion (everything before " - ") matches the query.
    // This removes tributes and other-artist releases without needing format= filters.
    private func filterByArtist(_ results: [DiscogsSearchResult], artist: String) -> [DiscogsSearchResult] {
        let needle = artist.lowercased().trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return results }
        return results.filter { result in
            let artistPortion = result.title.lowercased()
                .components(separatedBy: " - ").first ?? ""
            return artistPortion.contains(needle) || needle.contains(artistPortion)
        }
    }

    private func identifyViaAI(image: UIImage, anthropicKey: String) async -> (AIIdentification?, String?) {
        guard !anthropicKey.isEmpty else {
            return (nil, "No Anthropic API key set. Add it in Settings.")
        }
        let response = await aiVisionAccessor.load(
            IdentifyRecordRequest(image: image, apiKey: anthropicKey)
        )
        guard let identified = response as? IdentifyRecordResponse else {
            return (nil, response.errorMessage ?? "AI identification failed.")
        }
        guard let rawJSON = identified.rawJSON else {
            return (nil, identified.errorMessage ?? "Could not identify record from photo.")
        }
        let parseResponse = await identificationEngine.evaluate(
            ParseIdentificationRequest(rawJSON: rawJSON)
        )
        return ((parseResponse as? ParseIdentificationResponse)?.identification, nil)
    }

    private func searchByBarcode(_ barcode: String, token: String?, correlationId: UUID) async -> [DiscogsSearchResult] {
        let response = await discogsAccessor.load(
            SearchDiscogsByBarcodeRequest(barcode: barcode, token: token)
        )
        return (response as? SearchDiscogsResponse)?.results ?? []
    }

    private func searchByIdentification(_ identification: AIIdentification?, token: String?) async -> [DiscogsSearchResult] {
        guard let id = identification, let artist = id.artist, let title = id.albumTitle else {
            return []
        }
        let response = await discogsAccessor.load(
            SearchDiscogsRequest(
                query: "\(artist) \(title)",
                sort: "numhave",
                sortOrder: "desc",
                token: token,
                perPage: 100
            )
        )
        let raw = (response as? SearchDiscogsResponse)?.results ?? []
        return preferLocalCountry(filterByArtist(raw, artist: artist))
    }

    // Ranks candidates so the best album-title match floats to the top.
    // Discogs titles are "Artist - Album Title"; we strip to the album part before comparing.
    private func rankByAlbumTitle(_ candidates: [DiscogsSearchResult], target: String) -> [DiscogsSearchResult] {
        let normalizedTarget = alphanumericLowercase(target)
        guard !normalizedTarget.isEmpty else { return candidates }
        return candidates.sorted { a, b in
            albumTitleScore(a.title, target: normalizedTarget) > albumTitleScore(b.title, target: normalizedTarget)
        }
    }

    private func albumTitleScore(_ discogsTitle: String, target: String) -> Int {
        let album = discogsTitle.components(separatedBy: " - ").dropFirst().joined(separator: " - ")
        let normalized = alphanumericLowercase(album.isEmpty ? discogsTitle : album)
        if normalized == target { return 100 }
        if normalized.hasPrefix(target) || target.hasPrefix(normalized) { return 80 }
        if normalized.contains(target) || target.contains(normalized) { return 60 }
        let targetWords = Set(target.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
        let albumWords = Set(normalized.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
        return targetWords.intersection(albumWords).count * 10
    }

    private func alphanumericLowercase(_ s: String) -> String {
        s.lowercased().unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map { String($0) }
            .joined()
    }
}
