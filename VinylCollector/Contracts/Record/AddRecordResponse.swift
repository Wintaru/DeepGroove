import Foundation

final class AddRecordResponse: ResponseBase {
    let recordId: UUID?
    let displayTitle: String?

    init(correlationId: UUID, recordId: UUID, displayTitle: String) {
        self.recordId = recordId
        self.displayTitle = displayTitle
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.recordId = nil
        self.displayTitle = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
