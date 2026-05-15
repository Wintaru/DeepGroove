import Foundation

final class DeleteRecordRequest: RequestBase, @unchecked Sendable {
    let recordId: UUID

    init(recordId: UUID) {
        self.recordId = recordId
        super.init()
    }
}
