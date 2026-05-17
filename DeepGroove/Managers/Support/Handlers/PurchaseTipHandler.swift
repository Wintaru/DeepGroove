import Foundation

final class PurchaseTipHandler: IHandler {
    private let storeKitAccessor: IStoreKitAccessor

    init(storeKitAccessor: IStoreKitAccessor) {
        self.storeKitAccessor = storeKitAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? PurchaseTipRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let response = await storeKitAccessor.store(PurchaseTipProductRequest(productId: req.productId))
        guard response.success, let result = response as? PurchaseTipProductResponse,
              let productId = result.productId else {
            return PurchaseTipResponse(correlationId: req.correlationId,
                                       errorMessage: response.errorMessage)
        }
        return PurchaseTipResponse(correlationId: req.correlationId, productId: productId)
    }
}
