import Foundation

final class UpdateRecordRequest: RequestBase, @unchecked Sendable {
    let record: VinylRecord

    init(record: VinylRecord) {
        self.record = record
        super.init()
    }
}
