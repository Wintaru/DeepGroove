import Foundation

final class GetRecordRequest: RequestBase {
    let recordId: UUID

    init(recordId: UUID) {
        self.recordId = recordId
        super.init()
    }
}
