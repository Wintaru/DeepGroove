import Foundation

final class LoadRecordResponse: ResponseBase {
    let record: VinylRecord?

    init(correlationId: UUID, record: VinylRecord) {
        self.record = record
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.record = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
