import Foundation

protocol IStatisticsManager {
    func query(_ request: RequestBase) async -> ResponseBase
}
