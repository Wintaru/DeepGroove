import Foundation

final class ComputeStatisticsRequest: RequestBase, @unchecked Sendable {
    let records: [VinylRecord]

    init(records: [VinylRecord]) {
        self.records = records
        super.init()
    }
}
