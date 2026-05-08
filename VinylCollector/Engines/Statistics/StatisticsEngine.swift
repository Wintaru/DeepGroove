import Foundation

final class StatisticsEngine: IStatisticsEngine {
    private let evaluateResolver: HandlerResolver

    init(evaluateResolver: HandlerResolver) {
        self.evaluateResolver = evaluateResolver
    }

    func evaluate(_ request: RequestBase) async -> ResponseBase { await evaluateResolver.resolve(request) }
}
