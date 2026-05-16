import Combine
import SwiftData

@MainActor
final class DependencyContainer: ObservableObject {

    // MARK: - Public managers (consumed by views / view-models)
    let recordManager: IRecordManager
    let statisticsManager: IStatisticsManager
    let wishlistManager: IWishlistManager

    // MARK: - Shared observable configuration (consumed by SettingsView)
    let apiConfiguration: APIConfiguration

    // MARK: - Init

    init(modelContext: ModelContext) {
        let apiConfiguration = APIConfiguration()
        let network = NetworkUtility()
        let images = ImageUtility()
        let files = FileManagerUtility()

        // ── Accessors ──────────────────────────────────────────────────────────

        let wishlistAccessor = WishlistAccessor(
            storeResolver: HandlerResolverBuilder()
                .register(SaveWishlistItemHandler(modelContext: modelContext), for: SaveWishlistItemRequest.self)
                .build(),
            loadResolver: HandlerResolverBuilder()
                .register(LoadAllWishlistItemsHandler(modelContext: modelContext), for: LoadAllWishlistItemsRequest.self)
                .build(),
            removeResolver: HandlerResolverBuilder()
                .register(DeleteWishlistItemHandler(modelContext: modelContext), for: DeleteWishlistItemRequest.self)
                .build()
        )

        let recordAccessor = RecordAccessor(
            storeResolver: HandlerResolverBuilder()
                .register(SaveRecordHandler(modelContext: modelContext), for: SaveRecordRequest.self)
                .register(UpdateRecordHandler(modelContext: modelContext), for: UpdateRecordRequest.self)
                .build(),
            loadResolver: HandlerResolverBuilder()
                .register(LoadRecordHandler(modelContext: modelContext), for: LoadRecordRequest.self)
                .register(LoadAllRecordsHandler(modelContext: modelContext), for: LoadAllRecordsRequest.self)
                .build(),
            removeResolver: HandlerResolverBuilder()
                .register(DeleteRecordHandler(modelContext: modelContext, fileManagerUtility: files), for: DeleteRecordRequest.self)
                .build()
        )

        let photoAccessor = PhotoAccessor(
            storeResolver: HandlerResolverBuilder()
                .register(SavePhotoHandler(modelContext: modelContext, imageUtility: images, fileManagerUtility: files),
                          for: SavePhotoRequest.self)
                .build(),
            loadResolver: HandlerResolverBuilder()
                .register(LoadPhotoHandler(imageUtility: images, fileManagerUtility: files), for: LoadPhotoRequest.self)
                .build(),
            removeResolver: HandlerResolverBuilder()
                .register(DeletePhotoHandler(modelContext: modelContext, fileManagerUtility: files), for: DeletePhotoRequest.self)
                .build()
        )

        let discogsAccessor = DiscogsAccessor(
            loadResolver: HandlerResolverBuilder()
                .register(SearchDiscogsHandler(networkUtility: network), for: SearchDiscogsRequest.self)
                .register(SearchDiscogsByBarcodeHandler(networkUtility: network),
                          for: SearchDiscogsByBarcodeRequest.self)
                .register(LoadDiscogsReleaseHandler(networkUtility: network),
                          for: LoadDiscogsReleaseRequest.self)
                .build()
        )

        let aiVisionAccessor = AIVisionAccessor(
            loadResolver: HandlerResolverBuilder()
                .register(IdentifyRecordHandler(networkUtility: network, imageUtility: images),
                          for: IdentifyRecordRequest.self)
                .build()
        )

        // ── Engines ────────────────────────────────────────────────────────────

        let identificationEngine = IdentificationEngine(
            evaluateResolver: HandlerResolverBuilder()
                .register(ParseIdentificationHandler(), for: ParseIdentificationRequest.self)
                .build()
        )

        let metadataEngine = MetadataEngine(
            transformResolver: HandlerResolverBuilder()
                .register(MergeMetadataHandler(), for: MergeMetadataRequest.self)
                .build()
        )

        let statisticsEngine = StatisticsEngine(
            evaluateResolver: HandlerResolverBuilder()
                .register(ComputeStatisticsHandler(), for: ComputeStatisticsRequest.self)
                .build()
        )

        // ── Managers ───────────────────────────────────────────────────────────

        let addHandler = AddRecordHandler(
            discogsAccessor: discogsAccessor,
            metadataEngine: metadataEngine,
            recordAccessor: recordAccessor,
            photoAccessor: photoAccessor,
            networkUtility: network,
            imageUtility: images,
            apiConfiguration: apiConfiguration
        )

        let searchHandler = SearchRecordHandler(
            aiVisionAccessor: aiVisionAccessor,
            discogsAccessor: discogsAccessor,
            identificationEngine: identificationEngine,
            imageUtility: images,
            apiConfiguration: apiConfiguration
        )

        self.recordManager = RecordManager(
            executeResolver: HandlerResolverBuilder()
                .register(addHandler, for: AddRecordRequest.self)
                .register(EditRecordHandler(recordAccessor: recordAccessor), for: EditRecordRequest.self)
                .register(RemoveRecordHandler(recordAccessor: recordAccessor),
                          for: RemoveRecordRequest.self)
                .register(AttachPhotoHandler(photoAccessor: photoAccessor), for: AttachPhotoRequest.self)
                .build(),
            queryResolver: HandlerResolverBuilder()
                .register(GetRecordHandler(recordAccessor: recordAccessor), for: GetRecordRequest.self)
                .register(searchHandler, for: SearchRecordRequest.self)
                .build()
        )

        self.statisticsManager = StatisticsManager(
            queryResolver: HandlerResolverBuilder()
                .register(GetStatisticsHandler(recordAccessor: recordAccessor,
                                               statisticsEngine: statisticsEngine),
                          for: GetStatisticsRequest.self)
                .build()
        )

        self.wishlistManager = WishlistManager(
            executeResolver: HandlerResolverBuilder()
                .register(AddToWishlistHandler(wishlistAccessor: wishlistAccessor), for: AddToWishlistRequest.self)
                .register(RemoveFromWishlistHandler(wishlistAccessor: wishlistAccessor), for: RemoveFromWishlistRequest.self)
                .build(),
            queryResolver: HandlerResolverBuilder()
                .register(GetWishlistHandler(wishlistAccessor: wishlistAccessor), for: GetWishlistRequest.self)
                .build()
        )

        self.apiConfiguration = apiConfiguration
    }
}
