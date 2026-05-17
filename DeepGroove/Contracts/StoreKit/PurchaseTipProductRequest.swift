import Foundation

final class PurchaseTipProductRequest: RequestBase, @unchecked Sendable {
    let productId: String

    init(productId: String) {
        self.productId = productId
        super.init()
    }
}
