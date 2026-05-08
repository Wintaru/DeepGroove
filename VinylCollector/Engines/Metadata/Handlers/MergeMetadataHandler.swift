import Foundation

final class MergeMetadataHandler: IHandler {

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? MergeMetadataRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let ai = req.identification
        let discogs = req.discogsRelease

        // Priority: user override > Discogs > AI identification
        let artist = req.artistOverride
            ?? discogs?.artists.first
            ?? ai?.artist

        let albumTitle = req.albumTitleOverride
            ?? discogs?.title
            ?? ai?.albumTitle

        guard let resolvedArtist = artist, let resolvedTitle = albumTitle else {
            return MergeMetadataResponse(
                correlationId: req.correlationId,
                errorMessage: "Cannot create record: artist and album title are required."
            )
        }

        let year = req.yearOverride
            ?? discogs?.year
            ?? ai?.year

        let primaryLabel = req.labelOverride
            ?? discogs?.labels.first?.name
            ?? ai?.label

        let catalogNumber = discogs?.labels.first?.catalogNumber
            ?? ai?.catalogNumber

        // Merge genres: Discogs is authoritative; fall back to AI
        let discogsGenres = discogs?.genres ?? []
        let genres = discogsGenres.isEmpty ? (ai?.genres ?? []) : discogsGenres

        let styles = discogs?.styles ?? []

        let artworkURL: String? = {
            switch req.artworkPreference {
            case .downloaded, .both:
                return discogs?.primaryImageURL
            case .userPhoto:
                return nil
            }
        }()

        let candidate = RecordCandidate(
            artist: resolvedArtist,
            albumTitle: resolvedTitle,
            year: year,
            label: primaryLabel,
            catalogNumber: catalogNumber,
            genres: genres,
            styles: styles,
            country: discogs?.country ?? ai?.country,
            discogsId: discogs?.id,
            artworkURL: artworkURL,
            estimatedValue: discogs?.lowestPrice,
            condition: req.conditionOverride,
            artworkSource: req.artworkPreference,
            notes: req.notes
        )

        return MergeMetadataResponse(correlationId: req.correlationId, candidate: candidate)
    }
}
