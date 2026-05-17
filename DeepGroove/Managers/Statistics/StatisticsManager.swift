import Foundation

final class StatisticsManager: IStatisticsManager {
    private let queryResolver: HandlerResolver

    init(queryResolver: HandlerResolver) {
        self.queryResolver = queryResolver
    }

    func query(_ request: RequestBase) async -> ResponseBase { await queryResolver.resolve(request) }
}
