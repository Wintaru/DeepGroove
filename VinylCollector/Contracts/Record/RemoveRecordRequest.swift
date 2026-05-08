import Foundation

final class RemoveRecordRequest: RequestBase {
    let recordId: UUID

    init(recordId: UUID) {
        self.recordId = recordId
        super.init()
    }
}
