import Foundation

@MainActor
final class GetWishlistHandler: IHandler {
    private let wishlistAccessor: IWishlistAccessor

    init(wishlistAccessor: IWishlistAccessor) {
        self.wishlistAccessor = wishlistAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? GetWishlistRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        let response = await wishlistAccessor.load(LoadAllWishlistItemsRequest())
        if let loaded = response as? LoadAllWishlistItemsResponse, loaded.success {
            return GetWishlistResponse(correlationId: req.correlationId, items: loaded.items)
        } else {
            return GetWishlistResponse(correlationId: req.correlationId,
                                       errorMessage: response.errorMessage ?? "Failed to load wishlist.")
        }
    }
}
