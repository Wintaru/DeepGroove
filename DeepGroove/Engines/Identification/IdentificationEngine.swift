import Foundation

final class IdentificationEngine: IIdentificationEngine {
    private let evaluateResolver: HandlerResolver

    init(evaluateResolver: HandlerResolver) {
        self.evaluateResolver = evaluateResolver
    }

    func evaluate(_ request: RequestBase) async -> ResponseBase { await evaluateResolver.resolve(request) }
}
