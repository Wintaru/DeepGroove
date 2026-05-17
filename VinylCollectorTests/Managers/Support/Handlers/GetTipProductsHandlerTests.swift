import Foundation
import Testing
@testable import VinylCollector

// MARK: - Mock

private final class MockStoreKitAccessor: IStoreKitAccessor, @unchecked Sendable {
    var stubbedLoadResponse: ResponseBase
    var stubbedStoreResponse: ResponseBase

    init(
        loadResponse: ResponseBase = LoadTipProductsResponse(correlationId: UUID(), products: []),
        storeResponse: ResponseBase = PurchaseTipProductResponse(correlationId: UUID(), productId: "")
    ) {
        self.stubbedLoadResponse = loadResponse
        self.stubbedStoreResponse = storeResponse
    }

    func load(_ request: RequestBase) async -> ResponseBase { stubbedLoadResponse }
    func store(_ request: RequestBase) async -> ResponseBase { stubbedStoreResponse }
}

// MARK: - Helpers

private func makeTipProduct(
    id: String = "com.jdonner.vinylcollector.tip.small",
    displayName: String = "Buy me a coffee",
    displayPrice: String = "$0.99",
    priceDecimal: Decimal = 0.99
) -> TipProduct {
    TipProduct(id: id, displayName: displayName, displayPrice: displayPrice, priceDecimal: priceDecimal)
}

private func makeHandler(accessor: MockStoreKitAccessor = MockStoreKitAccessor()) -> GetTipProductsHandler {
    GetTipProductsHandler(storeKitAccessor: accessor)
}

// MARK: - Suite

@Suite("GetTipProductsHandler")
struct GetTipProductsHandlerTests {

    @Test func unhandledRequest() async {
        let response = await makeHandler().handle(ParseIdentificationRequest(rawJSON: "{}"))
        #expect(response is UnhandledRequestResponse)
    }

    @Test func returnsProductsOnSuccess() async {
        let products = [
            makeTipProduct(id: "tip.small"),
            makeTipProduct(id: "tip.medium"),
            makeTipProduct(id: "tip.large")
        ]
        let accessor = MockStoreKitAccessor(
            loadResponse: LoadTipProductsResponse(correlationId: UUID(), products: products)
        )
        let response = await makeHandler(accessor: accessor).handle(GetTipProductsRequest()) as? GetTipProductsResponse
        #expect(response?.success == true)
        #expect(response?.products.count == 3)
    }

    @Test func returnsErrorWhenAccessorFails() async {
        let accessor = MockStoreKitAccessor(
            loadResponse: LoadTipProductsResponse(correlationId: UUID(), errorMessage: "Network error")
        )
        let response = await makeHandler(accessor: accessor).handle(GetTipProductsRequest()) as? GetTipProductsResponse
        #expect(response?.success == false)
        #expect(response?.errorMessage == "Network error")
        #expect(response?.products.isEmpty == true)
    }

    @Test func productsArePassedThrough() async {
        let product = makeTipProduct(id: "tip.small", displayName: "Buy me a coffee", displayPrice: "$0.99")
        let accessor = MockStoreKitAccessor(
            loadResponse: LoadTipProductsResponse(correlationId: UUID(), products: [product])
        )
        let response = await makeHandler(accessor: accessor).handle(GetTipProductsRequest()) as? GetTipProductsResponse
        #expect(response?.products.first?.id == "tip.small")
        #expect(response?.products.first?.displayName == "Buy me a coffee")
        #expect(response?.products.first?.displayPrice == "$0.99")
    }
}
