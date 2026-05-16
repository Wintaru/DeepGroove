import Foundation
import SwiftData

@MainActor
final class DeleteWishlistItemHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? DeleteWishlistItemRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            guard let item = try modelContext.fetchFirst(WishlistRecord.self, id: req.itemId) else {
                return DeleteWishlistItemResponse(correlationId: req.correlationId,
                                                 errorMessage: "Wishlist item not found: \(req.itemId)")
            }
            modelContext.delete(item)
            try modelContext.save()
            return DeleteWishlistItemResponse(correlationId: req.correlationId)
        } catch {
            return DeleteWishlistItemResponse(correlationId: req.correlationId,
                                              errorMessage: error.localizedDescription)
        }
    }
}
