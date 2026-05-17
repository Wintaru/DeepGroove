import Foundation
import StoreKit

final class PurchaseTipProductHandler: IHandler {
    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? PurchaseTipProductRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        do {
            let products = try await Product.products(for: [req.productId])
            guard let product = products.first else {
                return PurchaseTipProductResponse(correlationId: req.correlationId,
                                                  errorMessage: "Product not found.")
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()
                return PurchaseTipProductResponse(correlationId: req.correlationId,
                                                  productId: req.productId)
            case .userCancelled:
                return PurchaseTipProductResponse(correlationId: req.correlationId,
                                                  errorMessage: nil)
            case .pending:
                return PurchaseTipProductResponse(correlationId: req.correlationId,
                                                  errorMessage: "Purchase is pending approval.")
            @unknown default:
                return PurchaseTipProductResponse(correlationId: req.correlationId,
                                                  errorMessage: "Unexpected purchase result.")
            }
        } catch {
            return PurchaseTipProductResponse(correlationId: req.correlationId,
                                              errorMessage: error.localizedDescription)
        }
    }
}
