import Foundation

@MainActor
final class RemoveFromWishlistHandler: IHandler {
    private let wishlistAccessor: IWishlistAccessor

    init(wishlistAccessor: IWishlistAccessor) {
        self.wishlistAccessor = wishlistAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? RemoveFromWishlistRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        let response = await wishlistAccessor.remove(DeleteWishlistItemRequest(itemId: req.itemId))
        if response.success {
            return RemoveFromWishlistResponse(correlationId: req.correlationId)
        } else {
            return RemoveFromWishlistResponse(correlationId: req.correlationId,
                                              errorMessage: response.errorMessage ?? "Failed to remove from wishlist.")
        }
    }
}
