import Foundation

final class WishlistManager: IWishlistManager {
    private let executeResolver: HandlerResolver

    init(executeResolver: HandlerResolver) {
        self.executeResolver = executeResolver
    }

    func execute(_ request: RequestBase) async -> ResponseBase { await executeResolver.resolve(request) }
}
