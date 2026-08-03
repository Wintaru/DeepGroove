import Foundation
import Observation

enum ShareState {
    case loading
    case confirming(
        topMatch: DiscogsSearchResult,
        candidates: [DiscogsSearchResult],
        artist: String,
        album: String,
        year: String?
    )
    case picking(
        candidates: [DiscogsSearchResult],
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

    func confirmResult(_ result: DiscogsSearchResult) {
        guard PendingWishlistQueue.enqueue(PendingWishlistItem(chosenResult: result)) else {
            state = .error("Couldn't queue this for your wishlist. Try again.")
            return
        }
        let album = StringUtility().splitDiscogsTitle(result.title).album
        state = .queued(album: album.isEmpty ? result.title : album)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    func confirmFallback(artist: String, album: String, year: String?) {
        let queued = PendingWishlistQueue.enqueue(PendingWishlistItem(
            artistOverride: artist,
            albumTitleOverride: album,
            yearOverride: year.flatMap(Int.init)
        ))
        guard queued else {
            state = .error("Couldn't queue this for your wishlist. Try again.")
            return
        }
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

    // No shared handler covers Apple Music ID -> metadata lookup (SearchITunesHandler goes the
    // other direction: artist+album -> Apple Music URL, for enriching an already-chosen record).
    // This one has no in-app counterpart to converge with.
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

    // Runs through the same SearchRecordHandler the in-app search uses (field-based
    // artist+title search, album-title ranking, AI artist-name correction on zero results)
    // instead of a separate hand-rolled Discogs query + ranking implementation.
    private func searchDiscogs(artist: String, album: String) async -> [DiscogsSearchResult] {
        let handler = await makeSearchRecordHandler()
        let response = await handler.handle(SearchRecordRequest(source: .text(artist: artist, albumTitle: album)))
        return (response as? SearchRecordResponse)?.candidates ?? []
    }

    // The extension's own composition root — a separate process, so it can't reach
    // App/DependencyContainer.swift. Uses the same SearchRecordHandlerFactory the app
    // does so the two never register a different handler set for the same dependencies.
    private func makeSearchRecordHandler() async -> SearchRecordHandler {
        let apiConfiguration = await MainActor.run { APIConfiguration() }
        let network = NetworkUtility()
        let images = ImageUtility()
        return SearchRecordHandlerFactory.makeSearchRecordHandler(
            discogsAccessor: SearchRecordHandlerFactory.makeDiscogsAccessor(networkUtility: network),
            aiVisionAccessor: SearchRecordHandlerFactory.makeAIVisionAccessor(
                networkUtility: network, imageUtility: images
            ),
            identificationEngine: SearchRecordHandlerFactory.makeIdentificationEngine(),
            imageUtility: images,
            apiConfiguration: apiConfiguration
        )
    }

    private func extractYear(from dateString: String) -> String? {
        let parts = dateString.split(separator: "-")
        guard let yearPart = parts.first, yearPart.count == 4 else { return nil }
        return String(yearPart)
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
