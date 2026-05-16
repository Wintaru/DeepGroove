import UIKit
import Testing
@testable import VinylCollector

// MARK: - Mocks

private final class MockDiscogsAccessor: IDiscogsAccessor, @unchecked Sendable {
    var stubbedResponse: ResponseBase

    init(response: ResponseBase) { self.stubbedResponse = response }

    func load(_ request: RequestBase) async -> ResponseBase { stubbedResponse }
}

private final class MockAIVisionAccessor: IAIVisionAccessor, @unchecked Sendable {
    var stubbedResponse: ResponseBase

    init(response: ResponseBase) { self.stubbedResponse = response }

    func load(_ request: RequestBase) async -> ResponseBase { stubbedResponse }
}

private final class MockIdentificationEngine: IIdentificationEngine, @unchecked Sendable {
    var stubbedResponse: ResponseBase

    init(response: ResponseBase) { self.stubbedResponse = response }

    func evaluate(_ request: RequestBase) async -> ResponseBase { stubbedResponse }
}

// MARK: - Helpers

private func makeCandidate(id: Int = 1, title: String = "Pink Floyd - The Wall")
-> DiscogsSearchResult {
    DiscogsSearchResult(
        id: id, title: title, year: "1979", labels: ["Harvest"],
        catalogNumber: nil, genres: ["Rock"], styles: [],
        country: "UK", thumbURL: nil, coverImageURL: nil, barcodes: []
    )
}

private func makeDiscogsResponse(
    results: [DiscogsSearchResult] = [makeCandidate()],
    totalPages: Int = 1
) -> SearchDiscogsResponse {
    SearchDiscogsResponse(
        correlationId: UUID(), results: results, totalPages: totalPages
    )
}

private func makeHandler(
    discogs: IDiscogsAccessor = MockDiscogsAccessor(
        response: makeDiscogsResponse()
    ),
    aiVision: IAIVisionAccessor = MockAIVisionAccessor(
        response: IdentifyRecordResponse(correlationId: UUID(), errorMessage: "unused")
    ),
    identification: IIdentificationEngine = MockIdentificationEngine(
        response: ParseIdentificationResponse(
            correlationId: UUID(), errorMessage: "unused"
        )
    ),
    anthropicKey: String = ""
) -> SearchRecordHandler {
    let config = APIConfiguration()
    config.anthropicAPIKey = anthropicKey
    return SearchRecordHandler(
        aiVisionAccessor: aiVision,
        discogsAccessor: discogs,
        identificationEngine: identification,
        imageUtility: ImageUtility(),
        apiConfiguration: config
    )
}

// MARK: - Suite

@Suite("SearchRecordHandler")
struct SearchRecordHandlerTests {

    @Test func unhandledRequest() async {
        let response = await makeHandler().handle(ParseIdentificationRequest(rawJSON: "{}"))
        #expect(response is UnhandledRequestResponse)
    }

    @Test func textSource_returnsCandidates() async {
        let candidates = [makeCandidate(id: 1), makeCandidate(id: 2), makeCandidate(id: 3)]
        let discogs = MockDiscogsAccessor(
            response: makeDiscogsResponse(results: candidates, totalPages: 2)
        )
        let response = await makeHandler(discogs: discogs).handle(
            SearchRecordRequest(source: .text(artist: "Pink Floyd", albumTitle: "The Wall"))
        ) as? SearchRecordResponse
        #expect(response?.candidates.count == 3)
        #expect(response?.currentPage == 1)
        #expect(response?.totalPages == 2)
    }

    @Test func textSource_page2_passedThrough() async {
        let discogs = MockDiscogsAccessor(
            response: makeDiscogsResponse(totalPages: 3)
        )
        let response = await makeHandler(discogs: discogs).handle(
            SearchRecordRequest(
                source: .text(artist: "Pink Floyd", albumTitle: "The Wall"),
                page: 2
            )
        ) as? SearchRecordResponse
        #expect(response?.currentPage == 2)
        #expect(response?.totalPages == 3)
    }

    @Test func textSource_emptyCandidates() async {
        let discogs = MockDiscogsAccessor(
            response: makeDiscogsResponse(results: [], totalPages: 1)
        )
        let response = await makeHandler(discogs: discogs).handle(
            SearchRecordRequest(source: .text(artist: "Pink Floyd", albumTitle: "The Wall"))
        ) as? SearchRecordResponse
        #expect(response?.candidates.isEmpty == true)
        #expect(response?.success == true)
    }

    @Test func barcodeSource_returnsCandidates() async {
        let discogs = MockDiscogsAccessor(
            response: makeDiscogsResponse(
                results: [makeCandidate(id: 1), makeCandidate(id: 2)]
            )
        )
        let response = await makeHandler(discogs: discogs).handle(
            SearchRecordRequest(source: .barcode("5099902987521"))
        ) as? SearchRecordResponse
        #expect(response?.candidates.count == 2)
    }

    @Test func barcodeSource_emptyCandidates() async {
        let discogs = MockDiscogsAccessor(
            response: makeDiscogsResponse(results: [])
        )
        let response = await makeHandler(discogs: discogs).handle(
            SearchRecordRequest(source: .barcode("5099902987521"))
        ) as? SearchRecordResponse
        #expect(response?.candidates.isEmpty == true)
    }

    @Test func manualSource_returnsEmpty() async {
        let response = await makeHandler().handle(
            SearchRecordRequest(source: .manual)
        ) as? SearchRecordResponse
        #expect(response?.candidates.isEmpty == true)
        #expect(response?.success == true)
    }

    @Test func photoSource_emptyApiKey_returnsError() async {
        let response = await makeHandler(anthropicKey: "").handle(
            SearchRecordRequest(source: .photo(UIImage()))
        ) as? SearchRecordResponse
        #expect(response?.success == false)
        #expect(response?.errorMessage?.contains("API key") == true)
    }
}
