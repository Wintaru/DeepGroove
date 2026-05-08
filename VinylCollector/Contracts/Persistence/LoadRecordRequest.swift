import Foundation

final class LoadRecordRequest: RequestBase {
    let recordId: UUID

    init(recordId: UUID) {
        self.recordId = recordId
        super.init()
    }
}
