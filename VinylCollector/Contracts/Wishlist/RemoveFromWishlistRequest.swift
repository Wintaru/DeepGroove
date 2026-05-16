import Foundation

final class RemoveFromWishlistRequest: RequestBase, @unchecked Sendable {
    let itemId: UUID

    init(itemId: UUID) {
        self.itemId = itemId
        super.init()
    }
}
