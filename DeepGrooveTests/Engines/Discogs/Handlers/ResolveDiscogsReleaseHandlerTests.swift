import Foundation
import Testing
@testable import DeepGroove

// MARK: - Mocks

private final class MockDiscogsAccessor: IDiscogsAccessor, @unchecked Sendable {
    var masterResponse: ResponseBase?
    var releaseResponse: ResponseBase
    private(set) var releaseIdsRequested: [Int] = []

    init(releaseResponse: ResponseBase, masterResponse: ResponseBase? = nil) {
        self.releaseResponse = releaseResponse
        self.masterResponse = masterResponse
    }

    func load(_ request: RequestBase) async -> ResponseBase {
        if let masterRequest = request as? LoadDiscogsMasterRequest {
            _ = masterRequest
            return masterResponse ?? LoadDiscogsMasterResponse(correlationId: UUID(), errorMessage: "unused")
        }
        if let releaseRequest = request as? LoadDiscogsReleaseRequest {
            releaseIdsRequested.append(releaseRequest.releaseId)
        }
        return releaseResponse
    }
}

// MARK: - Helpers

private func makeChosenResult(id: Int = 42, isMaster: Bool = false) -> DiscogsSearchResult {
    DiscogsSearchResult(
        id: id, masterId: nil, isMaster: isMaster, title: "White Zombie - La Sexorcisto", year: "1992",
        labels: ["Geffen"], catalogNumber: nil, genres: ["Rock"], styles: [],
        country: "US", thumbURL: nil, coverImageURL: nil, barcodes: []
    )
}

private func makeRelease(id: Int = 42) -> DiscogsRelease {
    DiscogsRelease(
        id: id, title: "La Sexorcisto: Devil Music Vol. 1", artists: ["White Zombie"], year: 1992,
        labels: [], genres: [], styles: [], country: "US",
        primaryImageURL: nil, secondaryImageURLs: [], tracklist: [], lowestPrice: nil, numForSale: nil
    )
}

// MARK: - Suite

@Suite("ResolveDiscogsReleaseHandler")
struct ResolveDiscogsReleaseHandlerTests {

    @Test func unhandledRequest() async {
        let handler = ResolveDiscogsReleaseHandler(
            discogsAccessor: MockDiscogsAccessor(releaseResponse: LoadDiscogsReleaseResponse(correlationId: UUID(), release: makeRelease()))
        )
        let response = await handler.handle(LoadDiscogsReleaseRequest(releaseId: 1))
        #expect(response is UnhandledRequestResponse)
    }

    @Test func nonMasterResult_loadsReleaseByItsOwnId() async {
        let discogs = MockDiscogsAccessor(
            releaseResponse: LoadDiscogsReleaseResponse(correlationId: UUID(), release: makeRelease(id: 7))
        )
        let handler = ResolveDiscogsReleaseHandler(discogsAccessor: discogs)
        let response = await handler.handle(
            ResolveDiscogsReleaseRequest(chosenResult: makeChosenResult(id: 7, isMaster: false), token: "tok")
        ) as? LoadDiscogsReleaseResponse
        #expect(response?.release?.id == 7)
        #expect(discogs.releaseIdsRequested == [7])
    }

    @Test func masterResult_resolvesMainReleaseFirst() async {
        let discogs = MockDiscogsAccessor(
            releaseResponse: LoadDiscogsReleaseResponse(correlationId: UUID(), release: makeRelease(id: 99)),
            masterResponse: LoadDiscogsMasterResponse(correlationId: UUID(), mainReleaseId: 99)
        )
        let handler = ResolveDiscogsReleaseHandler(discogsAccessor: discogs)
        let response = await handler.handle(
            ResolveDiscogsReleaseRequest(chosenResult: makeChosenResult(id: 7, isMaster: true), token: nil)
        ) as? LoadDiscogsReleaseResponse
        #expect(response?.release?.id == 99)
        #expect(discogs.releaseIdsRequested == [99])
    }

    @Test func masterResolutionFailure_fallsBackToChosenResultId() async {
        let discogs = MockDiscogsAccessor(
            releaseResponse: LoadDiscogsReleaseResponse(correlationId: UUID(), release: makeRelease(id: 7)),
            masterResponse: LoadDiscogsMasterResponse(correlationId: UUID(), errorMessage: "not found")
        )
        let handler = ResolveDiscogsReleaseHandler(discogsAccessor: discogs)
        let response = await handler.handle(
            ResolveDiscogsReleaseRequest(chosenResult: makeChosenResult(id: 7, isMaster: true), token: nil)
        ) as? LoadDiscogsReleaseResponse
        #expect(response?.success == true)
        #expect(discogs.releaseIdsRequested == [7])
    }

    @Test func releaseLoadFailure_propagatesError() async {
        let discogs = MockDiscogsAccessor(
            releaseResponse: LoadDiscogsReleaseResponse(correlationId: UUID(), errorMessage: "network down")
        )
        let handler = ResolveDiscogsReleaseHandler(discogsAccessor: discogs)
        let response = await handler.handle(
            ResolveDiscogsReleaseRequest(chosenResult: makeChosenResult(isMaster: false), token: nil)
        )
        #expect(response.success == false)
        #expect(response.errorMessage == "network down")
    }
}
