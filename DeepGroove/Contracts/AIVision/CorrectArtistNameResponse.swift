import Foundation

final class CorrectArtistNameResponse: ResponseBase, @unchecked Sendable {
    let correctedName: String?

    init(correlationId: UUID, correctedName: String) {
        self.correctedName = correctedName
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.correctedName = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
