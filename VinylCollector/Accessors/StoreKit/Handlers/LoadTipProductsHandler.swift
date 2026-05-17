import Foundation
import StoreKit

final class LoadTipProductsHandler: IHandler {
    private static let productIds = [
        "com.jdonner.vinylcollector.tip.small",
        "com.jdonner.vinylcollector.tip.medium",
        "com.jdonner.vinylcollector.tip.large"
    ]

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard request is LoadTipProductsRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        do {
            let storeProducts = try await Product.products(for: Self.productIds)
            let tips = storeProducts
                .sorted { $0.price < $1.price }
                .map { TipProduct(id: $0.id,
                                  displayName: $0.displayName,
                                  displayPrice: $0.displayPrice,
                                  priceDecimal: $0.price) }
            return LoadTipProductsResponse(correlationId: request.correlationId, products: tips)
        } catch {
            return LoadTipProductsResponse(correlationId: request.correlationId,
                                           errorMessage: error.localizedDescription)
        }
    }
}
