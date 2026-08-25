import UIKit

@MainActor
final class RematchRecordHandler: IHandler {
    private let discogsEngine: IDiscogsEngine
    private let iTunesAccessor: IITunesAccessor
    private let metadataEngine: IMetadataEngine
    private let recordAccessor: IRecordAccessor
    private let photoAccessor: IPhotoAccessor
    private let networkUtility: NetworkUtility
    private let apiConfiguration: APIConfiguration

    init(
        discogsEngine: IDiscogsEngine,
        iTunesAccessor: IITunesAccessor,
        metadataEngine: IMetadataEngine,
        recordAccessor: IRecordAccessor,
        photoAccessor: IPhotoAccessor,
        networkUtility: NetworkUtility,
        apiConfiguration: APIConfiguration
    ) {
        self.discogsEngine = discogsEngine
        self.iTunesAccessor = iTunesAccessor
        self.metadataEngine = metadataEngine
        self.recordAccessor = recordAccessor
        self.photoAccessor = photoAccessor
        self.networkUtility = networkUtility
        self.apiConfiguration = apiConfiguration
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? RematchRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let loadResponse = await recordAccessor.load(LoadRecordRequest(recordId: req.recordId))
        guard loadResponse.success, let record = (loadResponse as? LoadRecordResponse)?.record else {
            return RematchRecordResponse(
                correlationId: req.correlationId,
                errorMessage: loadResponse.errorMessage ?? "Record not found."
            )
        }

        let releaseResponse = await discogsEngine.transform(
            ResolveDiscogsReleaseRequest(chosenResult: req.chosenResult, token: apiConfiguration.discogsToken)
        )
        guard let discogsRelease = (releaseResponse as? LoadDiscogsReleaseResponse)?.release else {
            return RematchRecordResponse(
                correlationId: req.correlationId,
                errorMessage: releaseResponse.errorMessage ?? "Failed to load release details."
            )
        }

        // Condition and notes are the collector's own — carried through untouched.
        // Everything else comes fresh from the newly chosen release.
        let mergeResponse = await metadataEngine.transform(MergeMetadataRequest(
            identification: nil,
            discogsRelease: discogsRelease,
            artworkPreference: .downloaded,
            conditionOverride: record.condition,
            notes: record.notes
        ))
        guard let mergeResult = mergeResponse as? MergeMetadataResponse, mergeResult.success,
              let candidate = mergeResult.candidate
        else {
            return RematchRecordResponse(
                correlationId: req.correlationId,
                errorMessage: mergeResponse.errorMessage ?? "Failed to build record metadata."
            )
        }

        record.artist = candidate.artist
        record.albumTitle = candidate.albumTitle
        record.year = candidate.year
        record.label = candidate.label
        record.catalogNumber = candidate.catalogNumber
        record.genres = candidate.genres
        record.styles = candidate.styles
        record.country = candidate.country
        record.discogsId = candidate.discogsId
        record.estimatedValue = candidate.estimatedValue
        record.lastModified = Date()

        // The Apple Music link was resolved from the old (possibly wrong) artist/title —
        // re-resolve it against the corrected metadata rather than leaving it stale.
        let iTunesResponse = await iTunesAccessor.load(
            SearchITunesRequest(artist: candidate.artist, albumTitle: candidate.albumTitle)
        )
        record.appleMusicURL = (iTunesResponse as? SearchITunesResponse)?.url

        let saveResponse = await recordAccessor.store(UpdateRecordRequest(record: record))
        guard saveResponse.success else {
            return RematchRecordResponse(
                correlationId: req.correlationId,
                errorMessage: saveResponse.errorMessage ?? "Failed to save."
            )
        }

        // Fetch the new release's artwork *before* touching the old photo — a missing or
        // failed download must never leave the record with no artwork at all. Existing
        // user-captured photos and the record's artworkSource preference are left alone;
        // this only refreshes the downloaded-artwork slot.
        let newArtworkImage: UIImage? = await {
            guard let artworkURLString = candidate.artworkURL,
                  let artworkURL = URL(string: artworkURLString),
                  let artworkData = try? await networkUtility.get(url: artworkURL) else { return nil }
            return UIImage(data: artworkData)
        }()

        if let newArtworkImage {
            if let existingArtwork = record.artworkPhoto {
                let removeResponse = await photoAccessor.remove(DeletePhotoRequest(photoId: existingArtwork.id))
                guard removeResponse.success else {
                    return RematchRecordResponse(
                        correlationId: req.correlationId,
                        errorMessage: "Updated the details, but couldn't replace the old artwork: "
                            + (removeResponse.errorMessage ?? "unknown error")
                    )
                }
            }
            let storeResponse = await photoAccessor.store(SavePhotoRequest(image: newArtworkImage, photoType: .artwork,
                                                                           recordId: record.id))
            guard storeResponse.success else {
                return RematchRecordResponse(
                    correlationId: req.correlationId,
                    errorMessage: "Updated the details, but couldn't save the new artwork: "
                        + (storeResponse.errorMessage ?? "unknown error")
                )
            }
        }

        return RematchRecordResponse(correlationId: req.correlationId, record: record)
    }
}
