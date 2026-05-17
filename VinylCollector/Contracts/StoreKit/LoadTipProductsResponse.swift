import Foundation

final class LoadTipProductsResponse: ResponseBase, @unchecked Sendable {
    let products: [TipProduct]

    init(correlationId: UUID, products: [TipProduct]) {
        self.products = products
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.products = []
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
