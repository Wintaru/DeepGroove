import Foundation

@Observable
final class WishlistViewModel {
    var showingAddToWishlist = false
    var addedRecord: VinylRecord?
    var isAddingToCollection = false
    var errorMessage: String?

    private var recordManager: IRecordManager?
    private var wishlistManager: IWishlistManager?

    func setManagers(recordManager: IRecordManager, wishlistManager: IWishlistManager) {
        self.recordManager = recordManager
        self.wishlistManager = wishlistManager
    }

    func foundIt(_ item: WishlistRecord) async {
        guard let recordManager, let wishlistManager else { return }
        isAddingToCollection = true

        let searchResult: DiscogsSearchResult? = item.discogsId.map { id in
            DiscogsSearchResult(
                id: id,
                title: "\(item.artist) - \(item.albumTitle)",
                year: item.year.map { String($0) },
                labels: item.label.map { [$0] } ?? [],
                catalogNumber: nil,
                genres: item.genres,
                styles: [],
                country: nil,
                thumbURL: item.thumbURL,
                coverImageURL: nil,
                barcodes: []
            )
        }

        let addResponse = await recordManager.execute(AddRecordRequest(
            chosenResult: searchResult,
            artistOverride: searchResult == nil ? item.artist : nil,
            albumTitleOverride: searchResult == nil ? item.albumTitle : nil,
            yearOverride: searchResult == nil ? item.year : nil,
            labelOverride: searchResult == nil ? item.label : nil
        ))

        isAddingToCollection = false

        guard let result = addResponse as? AddRecordResponse, result.success,
              let recordId = result.recordId else {
            errorMessage = addResponse.errorMessage ?? "Failed to add to collection."
            return
        }

        let getResponse = await recordManager.query(GetRecordRequest(recordId: recordId))
        if let record = (getResponse as? GetRecordResponse)?.record {
            addedRecord = record
        }

        _ = await wishlistManager.execute(RemoveFromWishlistRequest(itemId: item.id))
    }

    func removeItem(_ item: WishlistRecord) async {
        guard let wishlistManager else { return }
        let response = await wishlistManager.execute(RemoveFromWishlistRequest(itemId: item.id))
        if !response.success {
            errorMessage = response.errorMessage ?? "Failed to remove item."
        }
    }
}
