import Foundation

final class SaveWishlistItemResponse: ResponseBase, @unchecked Sendable {
    let itemId: UUID?

    init(correlationId: UUID, itemId: UUID) {
        self.itemId = itemId
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.itemId = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
