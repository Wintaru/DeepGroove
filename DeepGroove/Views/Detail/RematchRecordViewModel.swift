import Foundation

enum RematchRecordState {
    case editingSearch
    case searching
    case showingDiscogsResults(candidates: [DiscogsSearchResult], currentPage: Int, totalPages: Int)
    case applying
    case success(String)
    case noResults(String)
    case failure(String)
}

@Observable
final class RematchRecordViewModel {
    var state: RematchRecordState = .editingSearch
    var searchArtist: String
    var searchAlbumTitle: String
    var isLoadingMore = false

    private let recordId: UUID
    private let recordManager: IRecordManager
    private let discogsResultsUtility = DiscogsResultsUtility()

    init(record: VinylRecord, recordManager: IRecordManager) {
        self.recordId = record.id
        self.recordManager = recordManager
        self.searchArtist = record.artist
        self.searchAlbumTitle = record.albumTitle
    }

    func search() async {
        state = .searching
        let response = await recordManager.query(SearchRecordRequest(
            source: .text(artist: searchArtist, albumTitle: searchAlbumTitle)
        ))
        handleSearchResponse(response)
    }

    func loadMoreResults() async {
        let maxCandidates = 40
        guard case let .showingDiscogsResults(existing, currentPage, totalPages) = state,
              currentPage < totalPages,
              existing.count < maxCandidates else { return }
        isLoadingMore = true
        let response = await recordManager.query(SearchRecordRequest(
            source: .text(artist: searchArtist, albumTitle: searchAlbumTitle),
            page: currentPage + 1
        ))
        isLoadingMore = false
        guard let result = response as? SearchRecordResponse, result.success else { return }
        let combined = discogsResultsUtility.appendingPage(to: existing, newResults: result.candidates,
                                                           maxCandidates: maxCandidates)
        state = .showingDiscogsResults(candidates: combined, currentPage: result.currentPage,
                                       totalPages: result.totalPages)
    }

    func chooseResult(_ result: DiscogsSearchResult) async {
        state = .applying
        let response = await recordManager.execute(
            RematchRecordRequest(recordId: recordId, chosenResult: result)
        )
        if let rematch = response as? RematchRecordResponse, rematch.success, let record = rematch.record {
            state = .success(record.displayTitle)
        } else {
            state = .failure(response.errorMessage ?? "Failed to update record.")
        }
    }

    func retrySearch() {
        state = .editingSearch
    }

    // MARK: - Private

    private func handleSearchResponse(_ response: ResponseBase) {
        guard let result = response as? SearchRecordResponse else {
            state = .failure(response.errorMessage ?? "Search failed.")
            return
        }
        if !result.candidates.isEmpty {
            state = .showingDiscogsResults(candidates: result.candidates, currentPage: result.currentPage,
                                           totalPages: result.totalPages)
        } else {
            state = .noResults(response.errorMessage ?? "No results found. Try editing the artist or album title.")
        }
    }
}
