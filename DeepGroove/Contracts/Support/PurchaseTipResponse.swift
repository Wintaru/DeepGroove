import Foundation

final class PurchaseTipResponse: ResponseBase, @unchecked Sendable {
    let productId: String?

    init(correlationId: UUID, productId: String) {
        self.productId = productId
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String?) {
        self.productId = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
