import Foundation
import Observation

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case success
    case error(String)
    case cancelled
}

@Observable
final class SupportViewModel {
    var products: [TipProduct] = []
    var isLoading = false
    var purchaseState: PurchaseState = .idle

    private let supportManager: ISupportManager

    init(supportManager: ISupportManager) {
        self.supportManager = supportManager
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        let response = await supportManager.query(GetTipProductsRequest())
        if let result = response as? GetTipProductsResponse, result.success {
            products = result.products
        }
    }

    func purchase(_ product: TipProduct) async {
        purchaseState = .purchasing
        let response = await supportManager.execute(PurchaseTipRequest(productId: product.id))
        if response.success {
            purchaseState = .success
        } else if response.errorMessage == nil {
            purchaseState = .cancelled
        } else {
            purchaseState = .error(response.errorMessage ?? "Purchase failed.")
        }
    }

    func resetPurchaseState() {
        purchaseState = .idle
    }
}
