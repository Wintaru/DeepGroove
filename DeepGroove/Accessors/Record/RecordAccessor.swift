import Foundation

final class RecordAccessor: IRecordAccessor {
    private let storeResolver: HandlerResolver
    private let loadResolver: HandlerResolver
    private let removeResolver: HandlerResolver

    init(
        storeResolver: HandlerResolver,
        loadResolver: HandlerResolver,
        removeResolver: HandlerResolver
    ) {
        self.storeResolver = storeResolver
        self.loadResolver = loadResolver
        self.removeResolver = removeResolver
    }

    func store(_ request: RequestBase) async -> ResponseBase { await storeResolver.resolve(request) }
    func load(_ request: RequestBase) async -> ResponseBase { await loadResolver.resolve(request) }
    func remove(_ request: RequestBase) async -> ResponseBase { await removeResolver.resolve(request) }
}
