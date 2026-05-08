import Foundation

final class SaveRecordResponse: ResponseBase {
    let recordId: UUID?

    init(correlationId: UUID, recordId: UUID) {
        self.recordId = recordId
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.recordId = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
