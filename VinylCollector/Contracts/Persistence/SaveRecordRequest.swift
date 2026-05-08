import Foundation

final class SaveRecordRequest: RequestBase {
    let record: VinylRecord

    init(record: VinylRecord) {
        self.record = record
        super.init()
    }
}
