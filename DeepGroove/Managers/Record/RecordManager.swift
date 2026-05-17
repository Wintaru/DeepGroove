import Foundation

final class RecordManager: IRecordManager {
    private let executeResolver: HandlerResolver
    private let queryResolver: HandlerResolver

    init(executeResolver: HandlerResolver, queryResolver: HandlerResolver) {
        self.executeResolver = executeResolver
        self.queryResolver = queryResolver
    }

    func execute(_ request: RequestBase) async -> ResponseBase { await executeResolver.resolve(request) }
    func query(_ request: RequestBase) async -> ResponseBase { await queryResolver.resolve(request) }
}
