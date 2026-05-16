import Foundation

final class AddToWishlistRequest: RequestBase, @unchecked Sendable {
    let chosenResult: DiscogsSearchResult?
    let artistOverride: String?
    let albumTitleOverride: String?
    let yearOverride: Int?
    let labelOverride: String?

    init(
        chosenResult: DiscogsSearchResult? = nil,
        artistOverride: String? = nil,
        albumTitleOverride: String? = nil,
        yearOverride: Int? = nil,
        labelOverride: String? = nil
    ) {
        self.chosenResult = chosenResult
        self.artistOverride = artistOverride
        self.albumTitleOverride = albumTitleOverride
        self.yearOverride = yearOverride
        self.labelOverride = labelOverride
        super.init()
    }
}
