import Foundation

final class SearchDiscogsResponse: ResponseBase, @unchecked Sendable {
    let results: [DiscogsSearchResult]
    let totalPages: Int

    init(correlationId: UUID, results: [DiscogsSearchResult], totalPages: Int) {
        self.results = results
        self.totalPages = totalPages
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.results = []
        self.totalPages = 0
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
