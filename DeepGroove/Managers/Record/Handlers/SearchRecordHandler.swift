import UIKit

final class SearchRecordHandler: IHandler {
    private let aiVisionAccessor: IAIVisionAccessor
    private let discogsAccessor: IDiscogsAccessor
    private let identificationEngine: IIdentificationEngine
    private let imageUtility: ImageUtility
    private let apiConfiguration: APIConfiguration

    init(
        aiVisionAccessor: IAIVisionAccessor,
        discogsAccessor: IDiscogsAccessor,
        identificationEngine: IIdentificationEngine,
        imageUtility: ImageUtility,
        apiConfiguration: APIConfiguration
    ) {
        self.aiVisionAccessor = aiVisionAccessor
        self.discogsAccessor = discogsAccessor
        self.identificationEngine = identificationEngine
        self.imageUtility = imageUtility
        self.apiConfiguration = apiConfiguration
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SearchRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let config = apiConfiguration
        let (anthropicKey, discogsToken) = await MainActor.run {
            (config.anthropicAPIKey, config.discogsToken)
        }

        switch req.source {
        case .photo(let image):
            if let barcode = imageUtility.detectBarcode(in: image) {
                let candidates = await searchByBarcode(barcode, token: discogsToken, correlationId: req.correlationId)
                if !candidates.isEmpty {
                    return SearchRecordResponse(correlationId: req.correlationId,
                                               candidates: candidates, userPhoto: image)
                }
            }
            let (identification, aiError) = await identifyViaAI(image: image, anthropicKey: anthropicKey)
            if let aiError, identification == nil {
                return SearchRecordResponse(correlationId: req.correlationId, errorMessage: aiError)
            }
            let candidates = await searchByIdentification(identification, token: discogsToken)
            return SearchRecordResponse(correlationId: req.correlationId,
                                        candidates: candidates,
                                        identification: identification,
                                        userPhoto: image)

        case .barcode(let code):
            let candidates = await searchByBarcode(code, token: discogsToken, correlationId: req.correlationId)
            return SearchRecordResponse(correlationId: req.correlationId, candidates: candidates)

        case .text(let artist, let albumTitle):
            let response = await discogsAccessor.load(
                SearchDiscogsRequest(
                    artist: artist.isEmpty ? nil : artist,
                    releaseTitle: albumTitle.isEmpty ? nil : albumTitle,
                    sort: "have",
                    sortOrder: "desc",
                    token: discogsToken,
                    page: req.page
                )
            )
            let discogsResponse = response as? SearchDiscogsResponse
            let identification = AIIdentification(
                artist: artist.isEmpty ? nil : artist,
                albumTitle: albumTitle.isEmpty ? nil : albumTitle,
                year: nil, label: nil, catalogNumber: nil, genres: [], country: nil, rawJSON: ""
            )
            return SearchRecordResponse(correlationId: req.correlationId,
                                        candidates: discogsResponse?.results ?? [],
                                        identification: identification,
                                        currentPage: req.page,
                                        totalPages: discogsResponse?.totalPages ?? 1)

        case .manual:
            return SearchRecordResponse(correlationId: req.correlationId, candidates: [])
        }
    }

    // MARK: - Private

    private func identifyViaAI(image: UIImage, anthropicKey: String) async -> (AIIdentification?, String?) {
        guard !anthropicKey.isEmpty else {
            return (nil, "No Anthropic API key set. Add it in Settings.")
        }
        let response = await aiVisionAccessor.load(
            IdentifyRecordRequest(image: image, apiKey: anthropicKey)
        )
        guard let identified = response as? IdentifyRecordResponse else {
            return (nil, response.errorMessage ?? "AI identification failed.")
        }
        guard let rawJSON = identified.rawJSON else {
            return (nil, identified.errorMessage ?? "Could not identify record from photo.")
        }
        let parseResponse = await identificationEngine.evaluate(
            ParseIdentificationRequest(rawJSON: rawJSON)
        )
        return ((parseResponse as? ParseIdentificationResponse)?.identification, nil)
    }

    private func searchByBarcode(_ barcode: String, token: String?, correlationId: UUID) async -> [DiscogsSearchResult] {
        let response = await discogsAccessor.load(
            SearchDiscogsByBarcodeRequest(barcode: barcode, token: token)
        )
        return (response as? SearchDiscogsResponse)?.results ?? []
    }

    private func searchByIdentification(_ identification: AIIdentification?, token: String?) async -> [DiscogsSearchResult] {
        guard let id = identification, let artist = id.artist, let title = id.albumTitle else {
            return []
        }
        let response = await discogsAccessor.load(
            SearchDiscogsRequest(
                artist: artist,
                releaseTitle: title,
                sort: "have",
                sortOrder: "desc",
                token: token
            )
        )
        return (response as? SearchDiscogsResponse)?.results ?? []
    }
}
