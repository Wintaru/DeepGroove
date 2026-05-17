import Foundation

struct RecordCandidate: Sendable {
    let artist: String
    let albumTitle: String
    let year: Int?
    let label: String?
    let catalogNumber: String?
    let genres: [String]
    let styles: [String]
    let country: String?
    let discogsId: Int?
    let artworkURL: String?
    let estimatedValue: Double?
    let condition: RecordCondition
    let artworkSource: ArtworkSource
    let notes: String?
}

final class MergeMetadataResponse: ResponseBase, @unchecked Sendable {
    let candidate: RecordCandidate?

    init(correlationId: UUID, candidate: RecordCandidate) {
        self.candidate = candidate
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.candidate = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
