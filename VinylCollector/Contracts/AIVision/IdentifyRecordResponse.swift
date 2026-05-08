import Foundation

struct AIIdentification: Sendable {
    let artist: String?
    let albumTitle: String?
    let year: Int?
    let label: String?
    let catalogNumber: String?
    let genres: [String]
    let country: String?
    let rawJSON: String
}

final class IdentifyRecordResponse: ResponseBase {
    let identification: AIIdentification?

    init(correlationId: UUID, identification: AIIdentification) {
        self.identification = identification
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.identification = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
