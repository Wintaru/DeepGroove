import Foundation

@MainActor
final class AddToWishlistHandler: IHandler {
    private let wishlistAccessor: IWishlistAccessor

    init(wishlistAccessor: IWishlistAccessor) {
        self.wishlistAccessor = wishlistAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? AddToWishlistRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        if let discogsId = req.chosenResult?.id {
            let existing = await wishlistAccessor.load(LoadAllWishlistItemsRequest())
            if let items = (existing as? LoadAllWishlistItemsResponse)?.items,
               items.contains(where: { $0.discogsId == discogsId }) {
                return AddToWishlistResponse(correlationId: req.correlationId,
                                            errorMessage: "Already on your wishlist.")
            }
        }

        let (parsedArtist, parsedAlbumTitle) = req.chosenResult.map {
            splitDiscogsTitle($0.title)
        } ?? ("", "")

        let artist = req.artistOverride ?? parsedArtist
        let albumTitle = req.albumTitleOverride ?? parsedAlbumTitle
        let year = req.yearOverride ?? req.chosenResult?.year.flatMap(Int.init)
        let label = req.labelOverride ?? req.chosenResult?.labels.first

        let saveResponse = await wishlistAccessor.store(SaveWishlistItemRequest(
            artist: artist,
            albumTitle: albumTitle,
            year: year,
            label: label,
            genres: req.chosenResult?.genres ?? [],
            discogsId: req.chosenResult?.id,
            thumbURL: req.chosenResult?.thumbURL
        ))

        guard saveResponse.success, let itemId = (saveResponse as? SaveWishlistItemResponse)?.itemId else {
            return AddToWishlistResponse(correlationId: req.correlationId,
                                        errorMessage: saveResponse.errorMessage ?? "Failed to save to wishlist.")
        }

        let displayTitle = albumTitle.isEmpty ? artist : "\(artist) – \(albumTitle)"
        return AddToWishlistResponse(correlationId: req.correlationId,
                                     itemId: itemId,
                                     displayTitle: displayTitle)
    }

    private func splitDiscogsTitle(_ title: String) -> (artist: String, albumTitle: String) {
        if let range = title.range(of: " - ") {
            return (String(title[..<range.lowerBound]), String(title[range.upperBound...]))
        }
        return ("", title)
    }
}
