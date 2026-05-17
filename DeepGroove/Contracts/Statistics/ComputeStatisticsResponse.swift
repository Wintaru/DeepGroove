import Foundation

final class ComputeStatisticsResponse: ResponseBase, @unchecked Sendable {
    let statistics: CollectionStatistics?

    init(correlationId: UUID, statistics: CollectionStatistics) {
        self.statistics = statistics
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.statistics = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
