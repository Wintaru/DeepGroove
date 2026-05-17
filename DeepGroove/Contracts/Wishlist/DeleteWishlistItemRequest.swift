import Foundation

final class DeleteWishlistItemRequest: RequestBase, @unchecked Sendable {
    let itemId: UUID

    init(itemId: UUID) {
        self.itemId = itemId
        super.init()
    }
}
