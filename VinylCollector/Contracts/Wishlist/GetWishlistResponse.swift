import Foundation

final class GetWishlistResponse: ResponseBase, @unchecked Sendable {
    let items: [WishlistRecord]

    init(correlationId: UUID, items: [WishlistRecord]) {
        self.items = items
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.items = []
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
