import Foundation
import Testing
@testable import DeepGroove

// MARK: - Mock

private final class MockStoreKitAccessor: IStoreKitAccessor, @unchecked Sendable {
    var stubbedLoadResponse: ResponseBase
    var stubbedStoreResponse: ResponseBase
    private(set) var capturedStoreRequest: PurchaseTipProductRequest?

    init(
        loadResponse: ResponseBase = LoadTipProductsResponse(correlationId: UUID(), products: []),
        storeResponse: ResponseBase = PurchaseTipProductResponse(correlationId: UUID(), productId: "tip.small")
    ) {
        self.stubbedLoadResponse = loadResponse
        self.stubbedStoreResponse = storeResponse
    }

    func load(_ request: RequestBase) async -> ResponseBase { stubbedLoadResponse }
    func store(_ request: RequestBase) async -> ResponseBase {
        capturedStoreRequest = request as? PurchaseTipProductRequest
        return stubbedStoreResponse
    }
}

// MARK: - Helpers

private func makeHandler(accessor: MockStoreKitAccessor = MockStoreKitAccessor()) -> PurchaseTipHandler {
    PurchaseTipHandler(storeKitAccessor: accessor)
}

// MARK: - Suite

@Suite("PurchaseTipHandler")
struct PurchaseTipHandlerTests {

    @Test func unhandledRequest() async {
        let response = await makeHandler().handle(ParseIdentificationRequest(rawJSON: "{}"))
        #expect(response is UnhandledRequestResponse)
    }

    @Test func returnsSuccessOnPurchase() async {
        let accessor = MockStoreKitAccessor(
            storeResponse: PurchaseTipProductResponse(correlationId: UUID(), productId: "tip.small")
        )
        let response = await makeHandler(accessor: accessor)
            .handle(PurchaseTipRequest(productId: "tip.small")) as? PurchaseTipResponse
        #expect(response?.success == true)
        #expect(response?.productId == "tip.small")
    }

    @Test func forwardsProductIdToAccessor() async {
        let accessor = MockStoreKitAccessor(
            storeResponse: PurchaseTipProductResponse(correlationId: UUID(), productId: "tip.large")
        )
        _ = await makeHandler(accessor: accessor).handle(PurchaseTipRequest(productId: "tip.large"))
        #expect(accessor.capturedStoreRequest?.productId == "tip.large")
    }

    @Test func returnsFailureWhenAccessorFails() async {
        let accessor = MockStoreKitAccessor(
            storeResponse: PurchaseTipProductResponse(correlationId: UUID(), errorMessage: "Payment declined")
        )
        let response = await makeHandler(accessor: accessor)
            .handle(PurchaseTipRequest(productId: "tip.small")) as? PurchaseTipResponse
        #expect(response?.success == false)
        #expect(response?.errorMessage == "Payment declined")
    }

    @Test func userCancelledPropagatesNilErrorMessage() async {
        let accessor = MockStoreKitAccessor(
            storeResponse: PurchaseTipProductResponse(correlationId: UUID(), errorMessage: nil)
        )
        let response = await makeHandler(accessor: accessor)
            .handle(PurchaseTipRequest(productId: "tip.small")) as? PurchaseTipResponse
        #expect(response?.success == false)
        #expect(response?.errorMessage == nil)
    }
}
