import Foundation

final class PurchaseTipRequest: RequestBase, @unchecked Sendable {
    let productId: String

    init(productId: String) {
        self.productId = productId
        super.init()
    }
}
