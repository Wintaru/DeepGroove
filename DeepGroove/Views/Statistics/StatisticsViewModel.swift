import Foundation

@Observable
final class StatisticsViewModel {
    var statistics: CollectionStatistics?
    var isLoading = false
    var errorMessage: String?

    private let statisticsManager: IStatisticsManager

    init(statisticsManager: IStatisticsManager) {
        self.statisticsManager = statisticsManager
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        let response = await statisticsManager.query(GetStatisticsRequest())
        if let result = response as? GetStatisticsResponse, result.success {
            statistics = result.statistics
        } else {
            errorMessage = response.errorMessage ?? "Failed to load statistics."
        }
    }
}
