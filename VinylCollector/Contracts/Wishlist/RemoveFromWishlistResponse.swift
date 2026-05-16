import Foundation

final class RemoveFromWishlistResponse: ResponseBase, @unchecked Sendable {
    init(correlationId: UUID) {
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
