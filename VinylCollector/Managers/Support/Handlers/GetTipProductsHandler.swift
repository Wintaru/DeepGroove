import Foundation

final class GetTipProductsHandler: IHandler {
    private let storeKitAccessor: IStoreKitAccessor

    init(storeKitAccessor: IStoreKitAccessor) {
        self.storeKitAccessor = storeKitAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard request is GetTipProductsRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let response = await storeKitAccessor.load(LoadTipProductsRequest())
        guard response.success, let result = response as? LoadTipProductsResponse else {
            return GetTipProductsResponse(correlationId: request.correlationId,
                                          errorMessage: response.errorMessage ?? "Failed to load tip products.")
        }
        return GetTipProductsResponse(correlationId: request.correlationId, products: result.products)
    }
}
