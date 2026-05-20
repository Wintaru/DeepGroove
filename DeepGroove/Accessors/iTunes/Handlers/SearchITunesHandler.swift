import Foundation

final class SearchITunesHandler: IHandler {
    private let networkUtility: NetworkUtility

    init(networkUtility: NetworkUtility) {
        self.networkUtility = networkUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SearchITunesRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        guard !req.artist.isEmpty, !req.albumTitle.isEmpty else {
            return SearchITunesResponse(correlationId: req.correlationId, url: nil)
        }
        do {
            let url = try await findAppleMusicURL(artist: req.artist, albumTitle: req.albumTitle)
            return SearchITunesResponse(correlationId: req.correlationId, url: url)
        } catch {
            return SearchITunesResponse(correlationId: req.correlationId, url: nil)
        }
    }

    // MARK: - Private

    private func findAppleMusicURL(artist: String, albumTitle: String) async throws -> String? {
        let cleanedArtist = stripDiscogsDisambiguation(artist)
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: "\(cleanedArtist) \(albumTitle)"),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "album"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = components.url else { return nil }
        let data = try await networkUtility.get(url: url, headers: ["User-Agent": "DeepGroove/1.0"])
        let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)

        let normalizedArtist = alphanumericLowercase(cleanedArtist)
        let normalizedAlbum = alphanumericLowercase(albumTitle)

        let best = response.results
            .filter { $0.wrapperType == "collection" }
            .map { result -> (score: Int, url: String?) in
                let albumScore = fuzzyScore(alphanumericLowercase(result.collectionName ?? ""),
                                            against: normalizedAlbum)
                let artistBonus = alphanumericLowercase(result.artistName ?? "")
                    .contains(normalizedArtist) ? 20 : 0
                return (albumScore + artistBonus, result.collectionViewUrl)
            }
            .filter { $0.score >= 60 }
            .max { $0.score < $1.score }

        return best?.url
    }

    private func stripDiscogsDisambiguation(_ artist: String) -> String {
        artist.replacingOccurrences(of: #"\s*\(\d+\)\s*$"#, with: "",
                                    options: .regularExpression).trimmingCharacters(in: .whitespaces)
    }

    private func fuzzyScore(_ normalized: String, against target: String) -> Int {
        if normalized == target { return 100 }
        if normalized.hasPrefix(target) || target.hasPrefix(normalized) { return 80 }
        if normalized.contains(target) || target.contains(normalized) { return 60 }
        let targetWords = Set(target.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty })
        let titleWords = Set(normalized.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty })
        return targetWords.intersection(titleWords).count * 10
    }

    private func alphanumericLowercase(_ s: String) -> String {
        s.lowercased().unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map { String($0) }
            .joined()
    }
}

// MARK: - Private decodable types

private struct ITunesSearchResponse: Decodable {
    let results: [ITunesAlbum]
}

private struct ITunesAlbum: Decodable {
    let wrapperType: String?
    let artistName: String?
    let collectionName: String?
    let collectionViewUrl: String?
}
