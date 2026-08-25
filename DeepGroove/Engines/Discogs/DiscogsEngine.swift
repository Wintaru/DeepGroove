import Foundation

final class DiscogsEngine: IDiscogsEngine {
    private let transformResolver: HandlerResolver

    init(transformResolver: HandlerResolver) {
        self.transformResolver = transformResolver
    }

    func transform(_ request: RequestBase) async -> ResponseBase { await transformResolver.resolve(request) }
}
