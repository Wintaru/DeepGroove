import UIKit

@MainActor
final class AddRecordHandler: IHandler {
    private let discogsAccessor: IDiscogsAccessor
    private let metadataEngine: IMetadataEngine
    private let recordAccessor: IRecordAccessor
    private let photoAccessor: IPhotoAccessor
    private let networkUtility: NetworkUtility
    private let imageUtility: ImageUtility
    private let apiConfiguration: APIConfiguration

    init(
        discogsAccessor: IDiscogsAccessor,
        metadataEngine: IMetadataEngine,
        recordAccessor: IRecordAccessor,
        photoAccessor: IPhotoAccessor,
        networkUtility: NetworkUtility,
        imageUtility: ImageUtility,
        apiConfiguration: APIConfiguration
    ) {
        self.discogsAccessor = discogsAccessor
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

        // Load full Discogs release for the chosen search result
        let discogsRelease: DiscogsRelease?
        if let resultId = req.chosenResult?.id {
            let releaseResponse = await discogsAccessor.load(
                LoadDiscogsReleaseRequest(releaseId: resultId, token: apiConfiguration.discogsToken)
            )
            discogsRelease = (releaseResponse as? LoadDiscogsReleaseResponse)?.release
        } else {
            discogsRelease = nil
        }

        let mergeResponse = await metadataEngine.transform(MergeMetadataRequest(
            identification: req.identification,
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

        let saveResponse = await recordAccessor.store(SaveRecordRequest(candidate: candidate))
        guard saveResponse.success, let recordId = (saveResponse as? SaveRecordResponse)?.recordId else {
            return AddRecordResponse(
                correlationId: req.correlationId,
                errorMessage: saveResponse.errorMessage ?? "Failed to save record."
            )
        }

        if let photo = req.userPhoto {
            _ = await photoAccessor.store(SavePhotoRequest(image: photo, photoType: .userCapture,
                                                           recordId: recordId))
        }

        if let artworkURLString = candidate.artworkURL,
           let artworkURL = URL(string: artworkURLString),
           candidate.artworkSource != .userPhoto,
           let artworkData = try? await networkUtility.get(url: artworkURL),
           let artworkImage = UIImage(data: artworkData) {
            _ = await photoAccessor.store(SavePhotoRequest(image: artworkImage, photoType: .artwork,
                                                           recordId: recordId))
        }

        let displayTitle = candidate.albumTitle.isEmpty
            ? candidate.artist
            : "\(candidate.artist) – \(candidate.albumTitle)"

        return AddRecordResponse(correlationId: req.correlationId,
                                 recordId: recordId,
                                 displayTitle: displayTitle)
    }
}
