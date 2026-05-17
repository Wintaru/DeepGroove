import Foundation

final class AddToWishlistResponse: ResponseBase, @unchecked Sendable {
    let itemId: UUID?
    let displayTitle: String?

    init(correlationId: UUID, itemId: UUID, displayTitle: String) {
        self.itemId = itemId
        self.displayTitle = displayTitle
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.itemId = nil
        self.displayTitle = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
