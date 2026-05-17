import Foundation

final class SupportManager: ISupportManager {
    private let queryResolver: HandlerResolver
    private let executeResolver: HandlerResolver

    init(queryResolver: HandlerResolver, executeResolver: HandlerResolver) {
        self.queryResolver = queryResolver
        self.executeResolver = executeResolver
    }

    func query(_ request: RequestBase) async -> ResponseBase { await queryResolver.resolve(request) }
    func execute(_ request: RequestBase) async -> ResponseBase { await executeResolver.resolve(request) }
}
