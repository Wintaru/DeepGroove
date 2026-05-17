import Foundation

protocol IStatisticsEngine {
    func evaluate(_ request: RequestBase) async -> ResponseBase
}
