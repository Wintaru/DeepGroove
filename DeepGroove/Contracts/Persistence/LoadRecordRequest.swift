import Foundation

final class LoadRecordRequest: RequestBase, @unchecked Sendable {
    let recordId: UUID

    init(recordId: UUID) {
        self.recordId = recordId
        super.init()
    }
}
