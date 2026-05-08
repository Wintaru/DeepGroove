import Foundation

struct DiscogsSearchResult: Sendable {
    let id: Int
    let title: String
    let year: String?
    let labels: [String]
    let catalogNumber: String?
    let genres: [String]
    let styles: [String]
    let country: String?
    let thumbURL: String?
    let coverImageURL: String?
    let barcodes: [String]
}

final class SearchDiscogsResponse: ResponseBase {
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
