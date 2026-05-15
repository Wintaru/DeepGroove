import Foundation

final class GetRecordRequest: RequestBase, @unchecked Sendable {
    let recordId: UUID

    init(recordId: UUID) {
        self.recordId = recordId
        super.init()
    }
}
