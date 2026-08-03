import Foundation

// Single place that wires a working SearchRecordHandler — used by both
// App/DependencyContainer.swift (the app's composition root) and
// DeepGrooveShareExtension/ShareViewModel.swift (the extension's own composition
// root, since it's a separate process DependencyContainer can't reach). Keeping the
// handler-registration list here means the two don't drift out of sync on which
// request types SearchRecordHandler's dependencies need to resolve.
enum SearchRecordHandlerFactory {
    static func makeDiscogsAccessor(networkUtility: NetworkUtility) -> IDiscogsAccessor {
        DiscogsAccessor(
            loadResolver: HandlerResolverBuilder()
                .register(SearchDiscogsHandler(networkUtility: networkUtility), for: SearchDiscogsRequest.self)
                .register(SearchDiscogsByBarcodeHandler(networkUtility: networkUtility),
                          for: SearchDiscogsByBarcodeRequest.self)
                .register(LoadDiscogsReleaseHandler(networkUtility: networkUtility),
                          for: LoadDiscogsReleaseRequest.self)
                .register(LoadDiscogsMasterHandler(networkUtility: networkUtility),
                          for: LoadDiscogsMasterRequest.self)
                .build()
        )
    }

    static func makeAIVisionAccessor(networkUtility: NetworkUtility, imageUtility: ImageUtility) -> IAIVisionAccessor {
        AIVisionAccessor(
            loadResolver: HandlerResolverBuilder()
                .register(IdentifyRecordHandler(networkUtility: networkUtility, imageUtility: imageUtility),
                          for: IdentifyRecordRequest.self)
                .register(CorrectArtistNameHandler(networkUtility: networkUtility),
                          for: CorrectArtistNameRequest.self)
                .build()
        )
    }

    static func makeIdentificationEngine() -> IIdentificationEngine {
        IdentificationEngine(
            evaluateResolver: HandlerResolverBuilder()
                .register(ParseIdentificationHandler(), for: ParseIdentificationRequest.self)
                .build()
        )
    }

    static func makeSearchRecordHandler(
        discogsAccessor: IDiscogsAccessor,
        aiVisionAccessor: IAIVisionAccessor,
        identificationEngine: IIdentificationEngine,
        imageUtility: ImageUtility,
        apiConfiguration: APIConfiguration
    ) -> SearchRecordHandler {
        SearchRecordHandler(
            aiVisionAccessor: aiVisionAccessor,
            discogsAccessor: discogsAccessor,
            identificationEngine: identificationEngine,
            imageUtility: imageUtility,
            apiConfiguration: apiConfiguration
        )
    }
}
