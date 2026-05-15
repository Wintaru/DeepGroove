import Foundation

final class SearchDiscogsByBarcodeResponse: ResponseBase, @unchecked Sendable {
    let results: [DiscogsSearchResult]

    init(correlationId: UUID, results: [DiscogsSearchResult]) {
        self.results = results
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.results = []
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
