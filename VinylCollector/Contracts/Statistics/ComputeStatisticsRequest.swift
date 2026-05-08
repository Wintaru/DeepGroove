import Foundation

final class ComputeStatisticsRequest: RequestBase {
    let records: [VinylRecord]

    init(records: [VinylRecord]) {
        self.records = records
        super.init()
    }
}
