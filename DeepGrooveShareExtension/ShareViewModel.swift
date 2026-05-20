import Foundation
import Observation
import Security

struct ShareDiscogsResult: Identifiable, Sendable {
    let id: Int
    let discogsTitle: String    // full "Artist - Album" from Discogs
    let albumTitle: String      // just the album part
    let year: String?
    let label: String?
    let thumbURL: String?
    let genres: [String]
}

enum ShareState {
    case loading
    case confirming(
        topMatch: ShareDiscogsResult,
        candidates: [ShareDiscogsResult],
        artist: String,
        album: String,
        year: String?
    )
    case picking(
        candidates: [ShareDiscogsResult],
        artist: String,
        album: String,
        year: String?
    )
    case fallback(artist: String, album: String, year: String?)
    case queued(album: String)
    case error(String)
}

@Observable
final class ShareViewModel: @unchecked Sendable {
    var state: ShareState = .loading

    private weak var extensionContext: NSExtensionContext?

    init(url: URL?, extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
        Task { await resolve(url: url) }
    }

    private func discogsToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.jdonner.deepgroove",
            kSecAttrAccount: "vc_discogs_token",
            kSecAttrAccessGroup: "group.com.jdonner.deepgroove",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func confirmResult(_ result: ShareDiscogsResult) {
        var item: [String: String] = [
            "artist": extractArtist(from: result.discogsTitle),
            "album": result.albumTitle,
            "discogsId": String(result.id),
            "discogsTitle": result.discogsTitle
        ]
        if let year = result.year { item["year"] = year }
        if let label = result.label { item["label"] = label }
        if let thumb = result.thumbURL { item["thumb"] = thumb }
        if !result.genres.isEmpty { item["genres"] = result.genres.joined(separator: ",") }
        UserDefaults(suiteName: "group.com.jdonner.deepgroove")?.set(item, forKey: "pendingWishlistItem")
        state = .queued(album: result.albumTitle)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    func confirmFallback(artist: String, album: String, year: String?) {
        var item: [String: String] = ["artist": artist, "album": album]
        if let year { item["year"] = year }
        UserDefaults(suiteName: "group.com.jdonner.deepgroove")?.set(item, forKey: "pendingWishlistItem")
        state = .queued(album: album)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    func showPicker() {
        guard case let .confirming(_, candidates, artist, album, year) = state else { return }
        state = .picking(candidates: candidates, artist: artist, album: album, year: year)
    }

    func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "DeepGroove", code: 0))
    }

    // MARK: - Private

    private func resolve(url: URL?) async {
        guard let url, url.host == "music.apple.com" else {
            await MainActor.run {
                state = .error("Share a song from Apple Music to add it to your wishlist.")
            }
            return
        }
        guard let albumId = extractAlbumId(from: url) else {
            await MainActor.run {
                state = .error("Couldn't read the Apple Music link. Try again.")
            }
            return
        }
        do {
            let (artist, album, year) = try await lookupiTunes(albumId: albumId)
            let candidates = await searchDiscogs(artist: artist, album: album)
            await MainActor.run {
                if let topMatch = candidates.first {
                    state = .confirming(topMatch: topMatch, candidates: candidates,
                                        artist: artist, album: album, year: year)
                } else {
                    state = .fallback(artist: artist, album: album, year: year)
                }
            }
        } catch {
            await MainActor.run {
                state = .error("Couldn't look up the album. Check your connection and try again.")
            }
        }
    }

    private func extractAlbumId(from url: URL) -> String? {
        let id = url.lastPathComponent
        return id.isEmpty || Int(id) == nil ? nil : id
    }

    private func lookupiTunes(albumId: String) async throws -> (String, String, String?) {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: albumId),
            URLQueryItem(name: "media", value: "music")
        ]
        guard let lookupURL = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: lookupURL)
        let response = try JSONDecoder().decode(ITunesLookupResponse.self, from: data)
        guard let result = response.results.first else { throw URLError(.cannotParseResponse) }
        let year = result.releaseDate.flatMap { extractYear(from: $0) }
        return (result.artistName, result.collectionName ?? result.trackName ?? "Unknown Album", year)
    }

    private func searchDiscogs(artist: String, album: String) async -> [ShareDiscogsResult] {
        var components = URLComponents(string: "https://api.discogs.com/database/search")!
        components.queryItems = [
            URLQueryItem(name: "type", value: "release"),
            URLQueryItem(name: "artist", value: artist),
            URLQueryItem(name: "sort", value: "numhave"),
            URLQueryItem(name: "sort_order", value: "desc"),
            URLQueryItem(name: "per_page", value: "40"),
            URLQueryItem(name: "page", value: "1")
        ]
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue("DeepGroove/1.0", forHTTPHeaderField: "User-Agent")
        if let token = discogsToken() {
            request.setValue("Discogs token=\(token)", forHTTPHeaderField: "Authorization")
        }
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let parsed = try? JSONDecoder().decode(DiscogsSearchAPIResponse.self, from: data) else {
            return []
        }
        let results = parsed.results.map { r -> ShareDiscogsResult in
            let parts = r.title.components(separatedBy: " - ")
            let albumPart = parts.count > 1 ? parts.dropFirst().joined(separator: " - ") : r.title
            return ShareDiscogsResult(
                id: r.id,
                discogsTitle: r.title,
                albumTitle: albumPart,
                year: r.year,
                label: r.label?.first,
                thumbURL: r.thumb,
                genres: r.genre ?? []
            )
        }
        return rankByAlbumTitle(results, target: album)
    }

    private func extractYear(from dateString: String) -> String? {
        let parts = dateString.split(separator: "-")
        guard let yearPart = parts.first, yearPart.count == 4 else { return nil }
        return String(yearPart)
    }

    private func extractArtist(from discogsTitle: String) -> String {
        discogsTitle.components(separatedBy: " - ").first ?? discogsTitle
    }

    // MARK: - Album title ranking (mirrors SearchRecordHandler logic)

    private func rankByAlbumTitle(_ candidates: [ShareDiscogsResult], target: String) -> [ShareDiscogsResult] {
        let normalizedTarget = alphanumericLowercase(target)
        guard !normalizedTarget.isEmpty else { return candidates }
        return candidates.sorted { a, b in
            albumTitleScore(a.albumTitle, target: normalizedTarget) > albumTitleScore(b.albumTitle, target: normalizedTarget)
        }
    }

    private func albumTitleScore(_ albumTitle: String, target: String) -> Int {
        let normalized = alphanumericLowercase(albumTitle)
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

// MARK: - Private decodable types

private struct ITunesLookupResponse: Decodable {
    let results: [ITunesResult]
}

private struct ITunesResult: Decodable {
    let artistName: String
    let collectionName: String?
    let trackName: String?
    let releaseDate: String?
}

private struct DiscogsSearchAPIResponse: Decodable {
    let results: [DiscogsResult]

    struct DiscogsResult: Decodable {
        let id: Int
        let title: String
        let year: String?
        let label: [String]?
        let genre: [String]?
        let thumb: String?
    }
}
