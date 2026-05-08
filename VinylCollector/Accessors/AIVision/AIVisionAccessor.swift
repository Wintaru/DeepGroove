import Foundation

final class AIVisionAccessor: IAIVisionAccessor {
    private let loadResolver: HandlerResolver

    init(loadResolver: HandlerResolver) {
        self.loadResolver = loadResolver
    }

    func load(_ request: RequestBase) async -> ResponseBase { await loadResolver.resolve(request) }
}
