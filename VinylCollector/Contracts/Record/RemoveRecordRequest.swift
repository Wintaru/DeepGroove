import Foundation

final class RemoveRecordRequest: RequestBase, @unchecked Sendable {
    let recordId: UUID

    init(recordId: UUID) {
        self.recordId = recordId
        super.init()
    }
}
