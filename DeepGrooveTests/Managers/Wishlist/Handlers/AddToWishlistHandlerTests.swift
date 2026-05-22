import Foundation
import Testing
@testable import DeepGroove

// MARK: - Mock

private final class MockWishlistAccessor: IWishlistAccessor, @unchecked Sendable {
    var stubbedLoadResponse: ResponseBase
    var stubbedStoreResponse: ResponseBase
    var capturedStoreRequest: SaveWishlistItemRequest?

    init(
        loadResponse: ResponseBase = LoadAllWishlistItemsResponse(
            correlationId: UUID(), items: []
        ),
        storeResponse: ResponseBase = SaveWishlistItemResponse(
            correlationId: UUID(), itemId: UUID()
        )
    ) {
        self.stubbedLoadResponse = loadResponse
        self.stubbedStoreResponse = storeResponse
    }

    func store(_ request: RequestBase) async -> ResponseBase {
        capturedStoreRequest = request as? SaveWishlistItemRequest
        return stubbedStoreResponse
    }
    func load(_ request: RequestBase) async -> ResponseBase { stubbedLoadResponse }
    func remove(_ request: RequestBase) async -> ResponseBase { fatalError("not used") }
}

// MARK: - Helpers

private func makeResult(
    id: Int = 1,
    title: String = "Pink Floyd - The Wall",
    year: String? = "1979",
    labels: [String] = ["Harvest"],
    genres: [String] = ["Rock"]
) -> DiscogsSearchResult {
    DiscogsSearchResult(
        id: id, masterId: nil, isMaster: false, title: title, year: year, labels: labels,
        catalogNumber: nil, genres: genres, styles: [],
        country: nil, thumbURL: nil, coverImageURL: nil, barcodes: []
    )
}

@MainActor
private func makeHandler(
    accessor: MockWishlistAccessor = MockWishlistAccessor()
) -> AddToWishlistHandler {
    AddToWishlistHandler(wishlistAccessor: accessor, stringUtility: StringUtility())
}

// MARK: - Suite

@MainActor
@Suite("AddToWishlistHandler")
struct AddToWishlistHandlerTests {

    @Test @MainActor func unhandledRequest() async {
        let response = await makeHandler().handle(ParseIdentificationRequest(rawJSON: "{}"))
        #expect(response is UnhandledRequestResponse)
    }

    @Test @MainActor func discogsResult_splitsTitle_andSaves() async {
        let accessor = MockWishlistAccessor()
        let handler = AddToWishlistHandler(
            wishlistAccessor: accessor, stringUtility: StringUtility()
        )
        let response = await handler.handle(
            AddToWishlistRequest(chosenResult: makeResult())
        ) as? AddToWishlistResponse
        #expect(response?.success == true)
        #expect(response?.displayTitle == "Pink Floyd \u{2013} The Wall")
        #expect(accessor.capturedStoreRequest?.artist == "Pink Floyd")
        #expect(accessor.capturedStoreRequest?.albumTitle == "The Wall")
    }

    @Test @MainActor func duplicateDiscogsId_returnsError() async {
        let existing = WishlistRecord(
            artist: "Pink Floyd", albumTitle: "The Wall", discogsId: 1
        )
        let accessor = MockWishlistAccessor(
            loadResponse: LoadAllWishlistItemsResponse(
                correlationId: UUID(), items: [existing]
            )
        )
        let response = await makeHandler(accessor: accessor).handle(
            AddToWishlistRequest(chosenResult: makeResult(id: 1))
        ) as? AddToWishlistResponse
        #expect(response?.success == false)
        #expect(response?.errorMessage?.contains("wishlist") == true)
    }

    @Test @MainActor func overrides_winOverParsedTitle() async {
        let accessor = MockWishlistAccessor()
        let handler = AddToWishlistHandler(
            wishlistAccessor: accessor, stringUtility: StringUtility()
        )
        let response = await handler.handle(
            AddToWishlistRequest(
                chosenResult: makeResult(title: "Pink Floyd - The Wall"),
                artistOverride: "Radiohead",
                albumTitleOverride: "OK Computer"
            )
        ) as? AddToWishlistResponse
        #expect(response?.displayTitle == "Radiohead \u{2013} OK Computer")
        #expect(accessor.capturedStoreRequest?.artist == "Radiohead")
        #expect(accessor.capturedStoreRequest?.albumTitle == "OK Computer")
    }

    @Test @MainActor func manualEntry_noChosenResult() async {
        let accessor = MockWishlistAccessor()
        let handler = AddToWishlistHandler(
            wishlistAccessor: accessor, stringUtility: StringUtility()
        )
        let response = await handler.handle(
            AddToWishlistRequest(
                artistOverride: "Radiohead",
                albumTitleOverride: "OK Computer"
            )
        ) as? AddToWishlistResponse
        #expect(response?.success == true)
        #expect(response?.displayTitle == "Radiohead \u{2013} OK Computer")
        #expect(accessor.capturedStoreRequest?.artist == "Radiohead")
    }

    @Test @MainActor func accessorSaveFailure_returnsError() async {
        let accessor = MockWishlistAccessor(
            storeResponse: SaveWishlistItemResponse(
                correlationId: UUID(), errorMessage: "Disk full"
            )
        )
        let response = await makeHandler(accessor: accessor).handle(
            AddToWishlistRequest(chosenResult: makeResult())
        ) as? AddToWishlistResponse
        #expect(response?.success == false)
        #expect(response?.errorMessage != nil)
    }

    @Test @MainActor func emptyAlbumTitle_displayTitleIsArtist() async {
        let response = await makeHandler().handle(
            AddToWishlistRequest(
                artistOverride: "Radiohead",
                albumTitleOverride: ""
            )
        ) as? AddToWishlistResponse
        #expect(response?.displayTitle == "Radiohead")
    }

    @Test @MainActor func yearOverride_winsOverDiscogsYear() async {
        let accessor = MockWishlistAccessor()
        let handler = AddToWishlistHandler(
            wishlistAccessor: accessor, stringUtility: StringUtility()
        )
        _ = await handler.handle(
            AddToWishlistRequest(
                chosenResult: makeResult(year: "1979"),
                yearOverride: 1984
            )
        )
        #expect(accessor.capturedStoreRequest?.year == 1984)
    }

    @Test @MainActor func labelOverride_winsOverDiscogsLabel() async {
        let accessor = MockWishlistAccessor()
        let handler = AddToWishlistHandler(
            wishlistAccessor: accessor, stringUtility: StringUtility()
        )
        _ = await handler.handle(
            AddToWishlistRequest(
                chosenResult: makeResult(labels: ["Harvest"]),
                labelOverride: "Columbia"
            )
        )
        #expect(accessor.capturedStoreRequest?.label == "Columbia")
    }
}
