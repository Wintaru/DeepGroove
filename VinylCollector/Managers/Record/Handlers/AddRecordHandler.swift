import UIKit

final class AddRecordHandler: IHandler {
    private let aiVisionAccessor: IAIVisionAccessor
    private let discogsAccessor: IDiscogsAccessor
    private let identificationEngine: IIdentificationEngine
    private let metadataEngine: IMetadataEngine
    private let recordAccessor: IRecordAccessor
    private let photoAccessor: IPhotoAccessor
    private let networkUtility: NetworkUtility
    private let imageUtility: ImageUtility
    private let apiConfiguration: APIConfiguration

    init(
        aiVisionAccessor: IAIVisionAccessor,
        discogsAccessor: IDiscogsAccessor,
        identificationEngine: IIdentificationEngine,
        metadataEngine: IMetadataEngine,
        recordAccessor: IRecordAccessor,
        photoAccessor: IPhotoAccessor,
        networkUtility: NetworkUtility,
        imageUtility: ImageUtility,
        apiConfiguration: APIConfiguration
    ) {
        self.aiVisionAccessor = aiVisionAccessor
        self.discogsAccessor = discogsAccessor
        self.identificationEngine = identificationEngine
        self.metadataEngine = metadataEngine
        self.recordAccessor = recordAccessor
        self.photoAccessor = photoAccessor
        self.networkUtility = networkUtility
        self.imageUtility = imageUtility
        self.apiConfiguration = apiConfiguration
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? AddRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let (identification, userPhoto, barcode, aiError) = await identify(from: req.source)

        if let aiError, identification == nil, barcode == nil {
            return AddRecordResponse(correlationId: req.correlationId, errorMessage: aiError)
        }

        let discogsRelease = await fetchDiscogsRelease(identification: identification, barcode: barcode)

        let mergeResponse = await metadataEngine.transform(MergeMetadataRequest(
            identification: identification,
            discogsRelease: discogsRelease,
            artworkPreference: req.artworkPreference,
            conditionOverride: req.condition,
            artistOverride: req.artistOverride,
            albumTitleOverride: req.albumTitleOverride,
            yearOverride: req.yearOverride,
            labelOverride: req.labelOverride,
            notes: req.notes
        ))

        guard let mergeResult = mergeResponse as? MergeMetadataResponse, mergeResult.success,
              let candidate = mergeResult.candidate
        else {
            return AddRecordResponse(
                correlationId: req.correlationId,
                errorMessage: mergeResponse.errorMessage ?? "Failed to build record metadata."
            )
        }

        let record = buildRecord(from: candidate)

        let saveResponse = await recordAccessor.store(SaveRecordRequest(record: record))
        guard saveResponse.success else {
            return AddRecordResponse(
                correlationId: req.correlationId,
                errorMessage: saveResponse.errorMessage ?? "Failed to save record."
            )
        }

        // Save user-captured photo
        if let photo = userPhoto {
            await photoAccessor.store(SavePhotoRequest(image: photo, photoType: .userCapture,
                                                       recordId: record.id))
        }

        // Download and save artwork
        if let artworkURLString = candidate.artworkURL,
           let artworkURL = URL(string: artworkURLString),
           candidate.artworkSource != .userPhoto {
            if let artworkImage = await downloadImage(from: artworkURL) {
                await photoAccessor.store(SavePhotoRequest(image: artworkImage, photoType: .artwork,
                                                           recordId: record.id))
            }
        }

        return AddRecordResponse(correlationId: req.correlationId, record: record)
    }

    // MARK: - Private helpers

    private func identify(from source: AddRecordSource) async -> (AIIdentification?, UIImage?, String?, String?) {
        switch source {
        case .photo(let image):
            let (identification, error) = await identifyViaAI(image: image)
            return (identification, image, nil, error)
        case .barcode(let code):
            return (nil, nil, code, nil)
        case .manual:
            return (nil, nil, nil, nil)
        }
    }

    private func identifyViaAI(image: UIImage) async -> (AIIdentification?, String?) {
        guard !apiConfiguration.anthropicAPIKey.isEmpty else {
            return (nil, "No Anthropic API key set. Add it in Settings.")
        }

        let visionResponse = await aiVisionAccessor.load(
            IdentifyRecordRequest(image: image, apiKey: apiConfiguration.anthropicAPIKey)
        )
        guard let identified = visionResponse as? IdentifyRecordResponse else {
            return (nil, visionResponse.errorMessage ?? "AI identification failed.")
        }
        guard let rawAI = identified.identification else {
            return (nil, identified.errorMessage ?? "Could not identify record from photo.")
        }

        let parseResponse = await identificationEngine.evaluate(
            ParseIdentificationRequest(rawJSON: rawAI.rawJSON)
        )
        return ((parseResponse as? ParseIdentificationResponse)?.identification, nil)
    }

    private func fetchDiscogsRelease(identification: AIIdentification?, barcode: String?) async -> DiscogsRelease? {
        let searchResult: DiscogsSearchResult?

        if let barcode {
            let response = await discogsAccessor.load(
                SearchDiscogsByBarcodeRequest(barcode: barcode, token: apiConfiguration.discogsToken)
            )
            searchResult = (response as? SearchDiscogsByBarcodeResponse)?.results.first
        } else if let id = identification, let artist = id.artist, let title = id.albumTitle {
            let query = "\(artist) \(title)"
            let response = await discogsAccessor.load(
                SearchDiscogsRequest(query: query, token: apiConfiguration.discogsToken)
            )
            searchResult = (response as? SearchDiscogsResponse)?.results.first
        } else {
            return nil
        }

        guard let releaseId = searchResult?.id else { return nil }
        let releaseResponse = await discogsAccessor.load(
            LoadDiscogsReleaseRequest(releaseId: releaseId, token: apiConfiguration.discogsToken)
        )
        return (releaseResponse as? LoadDiscogsReleaseResponse)?.release
    }

    private func buildRecord(from candidate: RecordCandidate) -> VinylRecord {
        VinylRecord(
            artist: candidate.artist,
            albumTitle: candidate.albumTitle,
            year: candidate.year,
            label: candidate.label,
            catalogNumber: candidate.catalogNumber,
            genres: candidate.genres,
            styles: candidate.styles,
            country: candidate.country,
            discogsId: candidate.discogsId,
            notes: candidate.notes,
            condition: candidate.condition,
            artworkSource: candidate.artworkSource,
            estimatedValue: candidate.estimatedValue
        )
    }

    private func downloadImage(from url: URL) async -> UIImage? {
        guard let data = try? await networkUtility.get(url: url) else { return nil }
        return UIImage(data: data)
    }
}
