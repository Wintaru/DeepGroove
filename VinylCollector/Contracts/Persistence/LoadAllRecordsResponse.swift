import Foundation

final class LoadAllRecordsResponse: ResponseBase {
    let records: [VinylRecord]

    init(correlationId: UUID, records: [VinylRecord]) {
        self.records = records
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.records = []
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
