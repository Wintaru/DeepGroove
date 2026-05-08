import Foundation

final class DeleteRecordRequest: RequestBase {
    let recordId: UUID

    init(recordId: UUID) {
        self.recordId = recordId
        super.init()
    }
}
