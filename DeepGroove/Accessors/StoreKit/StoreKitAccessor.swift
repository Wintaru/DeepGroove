import Foundation

final class StoreKitAccessor: IStoreKitAccessor {
    private let loadResolver: HandlerResolver
    private let storeResolver: HandlerResolver

    init(loadResolver: HandlerResolver, storeResolver: HandlerResolver) {
        self.loadResolver = loadResolver
        self.storeResolver = storeResolver
    }

    func load(_ request: RequestBase) async -> ResponseBase { await loadResolver.resolve(request) }
    func store(_ request: RequestBase) async -> ResponseBase { await storeResolver.resolve(request) }
}
