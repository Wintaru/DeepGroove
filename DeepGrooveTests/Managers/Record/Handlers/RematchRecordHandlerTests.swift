import Foundation
import UIKit
import Testing
@testable import DeepGroove

// MARK: - Mocks

private final class MockDiscogsEngine: IDiscogsEngine, @unchecked Sendable {
    var stubbedResponse: ResponseBase
    init(response: ResponseBase) { self.stubbedResponse = response }
    func transform(_ request: RequestBase) async -> ResponseBase { stubbedResponse }
}

private final class MockMetadataEngine: IMetadataEngine, @unchecked Sendable {
    var stubbedResponse: ResponseBase?
    init(response: ResponseBase? = nil) { self.stubbedResponse = response }

    // When no stub is provided, delegates to the real handler so tests exercise the
    // actual merge logic rather than a hand-rolled duplicate of it.
    func transform(_ request: RequestBase) async -> ResponseBase {
        if let stubbedResponse { return stubbedResponse }
        return await MergeMetadataHandler().handle(request)
    }
}

private final class MockRecordAccessor: IRecordAccessor, @unchecked Sendable {
    var loadResponse: ResponseBase
    var storeResponse: ResponseBase

    init(loadResponse: ResponseBase, storeResponse: ResponseBase = UpdateRecordResponse(correlationId: UUID())) {
        self.loadResponse = loadResponse
        self.storeResponse = storeResponse
    }

    func load(_ request: RequestBase) async -> ResponseBase { loadResponse }
    func store(_ request: RequestBase) async -> ResponseBase { storeResponse }
    func remove(_ request: RequestBase) async -> ResponseBase {
        fatalError("remove not used by RematchRecordHandler")
    }
}

private final class MockITunesAccessor: IITunesAccessor, @unchecked Sendable {
    var stubbedResponse: ResponseBase
    init(response: ResponseBase) { self.stubbedResponse = response }
    func load(_ request: RequestBase) async -> ResponseBase { stubbedResponse }
}

// Spy so tests can assert exactly which photo calls happened, and in what order — that's
// the only way to catch a regression on the "never delete before the replacement is ready"
// and "never leave a duplicate artwork behind" guarantees.
private final class SpyPhotoAccessor: IPhotoAccessor, @unchecked Sendable {
    enum Call: Equatable { case remove(UUID), store(PhotoType) }
    private(set) var calls: [Call] = []
    var removeResponse: ResponseBase = DeletePhotoResponse(correlationId: UUID())
    var storeResponse: ResponseBase = SavePhotoResponse(
        correlationId: UUID(), photo: RecordPhoto(photoPath: "RecordPhotos/new.jpg", photoType: .artwork)
    )

    func store(_ request: RequestBase) async -> ResponseBase {
        if let req = request as? SavePhotoRequest { calls.append(.store(req.photoType)) }
        return storeResponse
    }
    func load(_ request: RequestBase) async -> ResponseBase {
        fatalError("load not used by RematchRecordHandler")
    }
    func remove(_ request: RequestBase) async -> ResponseBase {
        if let req = request as? DeletePhotoRequest { calls.append(.remove(req.photoId)) }
        return removeResponse
    }
}

// Intercepts URLSession traffic so artwork-download tests never hit the real network.
private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (statusCode, data) = handler(request)
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private func makeStubbedNetworkUtility(statusCode: Int = 200, data: Data) -> NetworkUtility {
    MockURLProtocol.handler = { _ in (statusCode, data) }
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return NetworkUtility(session: URLSession(configuration: config))
}

private func makeJPEGData() -> Data {
    let size = CGSize(width: 2, height: 2)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        UIColor.red.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    return image.jpegData(compressionQuality: 1.0)!
}

// MARK: - Fixtures

private func makeRecord(
    artist: String = "White Zombie = 화이트 좀비",
    albumTitle: String = "La Sexorcisto",
    condition: RecordCondition = .nearMint,
    notes: String? = "Bought at a swap meet"
) -> VinylRecord {
    VinylRecord(artist: artist, albumTitle: albumTitle, notes: notes, condition: condition)
}

private func makeChosenResult(id: Int = 42, isMaster: Bool = false) -> DiscogsSearchResult {
    DiscogsSearchResult(
        id: id, masterId: nil, isMaster: isMaster, title: "White Zombie - La Sexorcisto", year: "1992",
        labels: ["Geffen"], catalogNumber: nil, genres: ["Rock"], styles: [],
        country: "US", thumbURL: nil, coverImageURL: nil, barcodes: []
    )
}

private func makeRelease(id: Int = 42, artworkURL: String? = nil) -> DiscogsRelease {
    DiscogsRelease(
        id: id, title: "La Sexorcisto: Devil Music Vol. 1", artists: ["White Zombie"], year: 1992,
        labels: [DiscogsLabel(name: "Geffen Records", catalogNumber: "GEF 24460")],
        genres: ["Rock"], styles: ["Industrial"], country: "US",
        primaryImageURL: artworkURL, secondaryImageURLs: [], tracklist: [],
        lowestPrice: 12.5, numForSale: 3
    )
}

@MainActor
private func makeHandler(
    discogsEngine: IDiscogsEngine,
    iTunesAccessor: IITunesAccessor = MockITunesAccessor(response: SearchITunesResponse(correlationId: UUID(), url: nil)),
    metadataEngine: IMetadataEngine = MockMetadataEngine(),
    recordAccessor: IRecordAccessor,
    photoAccessor: IPhotoAccessor = SpyPhotoAccessor(),
    networkUtility: NetworkUtility = NetworkUtility()
) -> RematchRecordHandler {
    RematchRecordHandler(
        discogsEngine: discogsEngine,
        iTunesAccessor: iTunesAccessor,
        metadataEngine: metadataEngine,
        recordAccessor: recordAccessor,
        photoAccessor: photoAccessor,
        networkUtility: networkUtility,
        apiConfiguration: APIConfiguration()
    )
}

private func makeResolvedEngine(release: DiscogsRelease) -> MockDiscogsEngine {
    MockDiscogsEngine(response: LoadDiscogsReleaseResponse(correlationId: UUID(), release: release))
}

// MARK: - Suite

// Serialized: the artwork-download tests share MockURLProtocol's static handler, which
// isn't safe under Swift Testing's default parallel execution.
@MainActor
@Suite("RematchRecordHandler", .serialized)
struct RematchRecordHandlerTests {

    @Test func unhandledRequest() async {
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease()),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: makeRecord()))
        )
        let response = await handler.handle(EditRecordRequest(recordId: UUID()))
        #expect(response is UnhandledRequestResponse)
    }

    @Test func recordNotFound_returnsError() async {
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease()),
            recordAccessor: MockRecordAccessor(
                loadResponse: LoadRecordResponse(correlationId: UUID(), errorMessage: "Record not found: x")
            )
        )
        let response = await handler.handle(RematchRecordRequest(recordId: UUID(), chosenResult: makeChosenResult()))
        #expect(response.success == false)
        #expect(response.errorMessage == "Record not found: x")
    }

    @Test func releaseLoadFailure_returnsError() async {
        let handler = makeHandler(
            discogsEngine: MockDiscogsEngine(
                response: LoadDiscogsReleaseResponse(correlationId: UUID(), errorMessage: "network down")
            ),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: makeRecord()))
        )
        let response = await handler.handle(RematchRecordRequest(recordId: UUID(), chosenResult: makeChosenResult()))
        #expect(response.success == false)
        #expect(response.errorMessage == "network down")
    }

    @Test func success_overwritesDiscogsFieldsButKeepsConditionAndNotes() async {
        let record = makeRecord(condition: .veryGood, notes: "Slight warp on side B")
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease()),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record))
        )
        let response = await handler.handle(
            RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult())
        ) as? RematchRecordResponse

        #expect(response?.success == true)
        #expect(record.artist == "White Zombie")
        #expect(record.albumTitle == "La Sexorcisto: Devil Music Vol. 1")
        #expect(record.year == 1992)
        #expect(record.label == "Geffen Records")
        #expect(record.catalogNumber == "GEF 24460")
        #expect(record.styles == ["Industrial"])
        #expect(record.country == "US")
        #expect(record.discogsId == 42)
        #expect(record.estimatedValue == 12.5)
        // Untouched by the rematch — these are the collector's own data, not Discogs's.
        #expect(record.condition == .veryGood)
        #expect(record.notes == "Slight warp on side B")
    }

    @Test func appleMusicURL_refreshedFromNewMetadata() async {
        let record = makeRecord()
        record.appleMusicURL = "https://music.apple.com/us/album/stale-old-match/1"
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease()),
            iTunesAccessor: MockITunesAccessor(
                response: SearchITunesResponse(correlationId: UUID(), url: "https://music.apple.com/us/album/correct/2")
            ),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record))
        )
        let response = await handler.handle(RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult()))
        #expect(response.success == true)
        #expect(record.appleMusicURL == "https://music.apple.com/us/album/correct/2")
    }

    @Test func mergeFailure_returnsError() async {
        let record = makeRecord()
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease()),
            metadataEngine: MockMetadataEngine(
                response: MergeMetadataResponse(correlationId: UUID(), errorMessage: "Cannot create record.")
            ),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record))
        )
        let response = await handler.handle(
            RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult())
        )
        #expect(response.success == false)
        #expect(response.errorMessage == "Cannot create record.")
    }

    @Test func saveFailure_returnsError() async {
        let record = makeRecord()
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease()),
            recordAccessor: MockRecordAccessor(
                loadResponse: LoadRecordResponse(correlationId: UUID(), record: record),
                storeResponse: UpdateRecordResponse(correlationId: UUID(), errorMessage: "disk full")
            )
        )
        let response = await handler.handle(
            RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult())
        )
        #expect(response.success == false)
        #expect(response.errorMessage == "disk full")
    }

    // MARK: - Artwork swap

    @Test func noArtworkOnNewRelease_leavesExistingArtworkUntouched() async {
        let record = makeRecord()
        let existingArtwork = RecordPhoto(photoPath: "RecordPhotos/old.jpg", photoType: .artwork)
        record.photos = [existingArtwork]
        let photoAccessor = SpyPhotoAccessor()
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease(artworkURL: nil)),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record)),
            photoAccessor: photoAccessor
        )
        let response = await handler.handle(RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult()))
        #expect(response.success == true)
        #expect(photoAccessor.calls.isEmpty)
    }

    @Test func artworkDownloadHTTPFailure_leavesExistingArtworkUntouched() async {
        let record = makeRecord()
        let existingArtwork = RecordPhoto(photoPath: "RecordPhotos/old.jpg", photoType: .artwork)
        record.photos = [existingArtwork]
        let photoAccessor = SpyPhotoAccessor()
        // 404 → networkUtility.get throws → UIImage never even gets a chance to fail to decode.
        let brokenNetwork = makeStubbedNetworkUtility(statusCode: 404, data: Data())
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease(artworkURL: "https://example.com/cover.jpg")),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record)),
            photoAccessor: photoAccessor,
            networkUtility: brokenNetwork
        )
        let response = await handler.handle(RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult()))
        // The metadata fix still succeeds — a bad cover-art fetch shouldn't fail the whole rematch,
        // and critically, the old (still-correct-until-proven-otherwise) artwork is never deleted.
        #expect(response.success == true)
        #expect(photoAccessor.calls.isEmpty)
    }

    @Test func artworkDownloadDecodeFailure_leavesExistingArtworkUntouched() async {
        let record = makeRecord()
        let existingArtwork = RecordPhoto(photoPath: "RecordPhotos/old.jpg", photoType: .artwork)
        record.photos = [existingArtwork]
        let photoAccessor = SpyPhotoAccessor()
        // 200 OK but not actually image bytes → networkUtility.get succeeds, UIImage(data:) returns nil.
        let corruptNetwork = makeStubbedNetworkUtility(data: Data("not an image".utf8))
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease(artworkURL: "https://example.com/cover.jpg")),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record)),
            photoAccessor: photoAccessor,
            networkUtility: corruptNetwork
        )
        let response = await handler.handle(RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult()))
        #expect(response.success == true)
        #expect(photoAccessor.calls.isEmpty)
    }

    @Test func artworkDownloadSucceeds_removesOldThenStoresNew() async {
        let record = makeRecord()
        let existingArtwork = RecordPhoto(photoPath: "RecordPhotos/old.jpg", photoType: .artwork)
        record.photos = [existingArtwork]
        let photoAccessor = SpyPhotoAccessor()
        let workingNetwork = makeStubbedNetworkUtility(data: makeJPEGData())
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease(artworkURL: "https://example.com/cover.jpg")),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record)),
            photoAccessor: photoAccessor,
            networkUtility: workingNetwork
        )
        let response = await handler.handle(RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult()))
        #expect(response.success == true)
        #expect(photoAccessor.calls == [.remove(existingArtwork.id), .store(.artwork)])
    }

    @Test func noExistingArtwork_downloadSucceeds_storesWithoutRemoving() async {
        let record = makeRecord()
        let photoAccessor = SpyPhotoAccessor()
        let workingNetwork = makeStubbedNetworkUtility(data: makeJPEGData())
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease(artworkURL: "https://example.com/cover.jpg")),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record)),
            photoAccessor: photoAccessor,
            networkUtility: workingNetwork
        )
        let response = await handler.handle(RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult()))
        #expect(response.success == true)
        #expect(photoAccessor.calls == [.store(.artwork)])
    }

    @Test func artworkRemoveFails_reportsErrorAndNeverStoresADuplicate() async {
        let record = makeRecord()
        let existingArtwork = RecordPhoto(photoPath: "RecordPhotos/old.jpg", photoType: .artwork)
        record.photos = [existingArtwork]
        let photoAccessor = SpyPhotoAccessor()
        photoAccessor.removeResponse = DeletePhotoResponse(correlationId: UUID(), errorMessage: "file locked")
        let workingNetwork = makeStubbedNetworkUtility(data: makeJPEGData())
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease(artworkURL: "https://example.com/cover.jpg")),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record)),
            photoAccessor: photoAccessor,
            networkUtility: workingNetwork
        )
        let response = await handler.handle(RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult()))
        #expect(response.success == false)
        #expect(response.errorMessage?.contains("file locked") == true)
        // Never stores on top of a failed delete — that would leave two `.artwork` photos
        // with an undefined winner (VinylRecord.artworkPhoto just picks the array's first).
        #expect(photoAccessor.calls == [.remove(existingArtwork.id)])
    }

    @Test func artworkStoreFails_reportsErrorAndDoesNotClaimSuccess() async {
        let record = makeRecord()
        let existingArtwork = RecordPhoto(photoPath: "RecordPhotos/old.jpg", photoType: .artwork)
        record.photos = [existingArtwork]
        let photoAccessor = SpyPhotoAccessor()
        photoAccessor.storeResponse = SavePhotoResponse(correlationId: UUID(), errorMessage: "disk full")
        let workingNetwork = makeStubbedNetworkUtility(data: makeJPEGData())
        let handler = makeHandler(
            discogsEngine: makeResolvedEngine(release: makeRelease(artworkURL: "https://example.com/cover.jpg")),
            recordAccessor: MockRecordAccessor(loadResponse: LoadRecordResponse(correlationId: UUID(), record: record)),
            photoAccessor: photoAccessor,
            networkUtility: workingNetwork
        )
        let response = await handler.handle(RematchRecordRequest(recordId: record.id, chosenResult: makeChosenResult()))
        // A failed save must not be reported as success — the record would otherwise be left
        // with the old artwork already deleted and nothing to replace it.
        #expect(response.success == false)
        #expect(response.errorMessage?.contains("disk full") == true)
        #expect(photoAccessor.calls == [.remove(existingArtwork.id), .store(.artwork)])
    }
}
