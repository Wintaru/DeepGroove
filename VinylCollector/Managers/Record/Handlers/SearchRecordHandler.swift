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

        switch req.source {
        case .photo(let image):
            // Try barcode detection in the image first — faster and more precise
            if let barcode = imageUtility.detectBarcode(in: image) {
                let candidates = await searchByBarcode(barcode, correlationId: req.correlationId)
                if !candidates.isEmpty {
                    return SearchRecordResponse(correlationId: req.correlationId,
                                               candidates: candidates, userPhoto: image)
                }
            }
            // Fall back to AI visual identification
            let (identification, aiError) = await identifyViaAI(image: image)
            if let aiError, identification == nil {
                return SearchRecordResponse(correlationId: req.correlationId, errorMessage: aiError)
            }
            let candidates = await searchByIdentification(identification)
            return SearchRecordResponse(correlationId: req.correlationId,
                                        candidates: candidates,
                                        identification: identification,
                                        userPhoto: image)

        case .barcode(let code):
            let candidates = await searchByBarcode(code, correlationId: req.correlationId)
            return SearchRecordResponse(correlationId: req.correlationId, candidates: candidates)

        case .text(let artist, let albumTitle):
            let query = [artist, albumTitle].filter { !$0.isEmpty }.joined(separator: " ")
            let response = await discogsAccessor.load(
                SearchDiscogsRequest(query: query, token: apiConfiguration.discogsToken)
            )
            let results = Array(((response as? SearchDiscogsResponse)?.results ?? []).prefix(8))
            let identification = AIIdentification(
                artist: artist.isEmpty ? nil : artist,
                albumTitle: albumTitle.isEmpty ? nil : albumTitle,
                year: nil, label: nil, catalogNumber: nil, genres: [], country: nil, rawJSON: ""
            )
            return SearchRecordResponse(correlationId: req.correlationId,
                                        candidates: results,
                                        identification: identification)

        case .manual:
            return SearchRecordResponse(correlationId: req.correlationId, candidates: [])
        }
    }

    // MARK: - Private

    private func identifyViaAI(image: UIImage) async -> (AIIdentification?, String?) {
        guard !apiConfiguration.anthropicAPIKey.isEmpty else {
            return (nil, "No Anthropic API key set. Add it in Settings.")
        }
        let response = await aiVisionAccessor.load(
            IdentifyRecordRequest(image: image, apiKey: apiConfiguration.anthropicAPIKey)
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

    private func searchByBarcode(_ barcode: String, correlationId: UUID) async -> [DiscogsSearchResult] {
        let response = await discogsAccessor.load(
            SearchDiscogsByBarcodeRequest(barcode: barcode, token: apiConfiguration.discogsToken)
        )
        return (response as? SearchDiscogsByBarcodeResponse)?.results ?? []
    }

    private func searchByIdentification(_ identification: AIIdentification?) async -> [DiscogsSearchResult] {
        guard let id = identification, let artist = id.artist, let title = id.albumTitle else {
            return []
        }
        let response = await discogsAccessor.load(
            SearchDiscogsRequest(query: "\(artist) \(title)", token: apiConfiguration.discogsToken)
        )
        let results = (response as? SearchDiscogsResponse)?.results ?? []
        return Array(results.prefix(8))
    }
}
