import Foundation

final class GetCollectionResponse: ResponseBase {
    let records: [VinylRecord]
    let totalCount: Int

    init(correlationId: UUID, records: [VinylRecord], totalCount: Int) {
        self.records = records
        self.totalCount = totalCount
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.records = []
        self.totalCount = 0
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
