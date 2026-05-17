import Foundation

final class SaveWishlistItemRequest: RequestBase, @unchecked Sendable {
    let artist: String
    let albumTitle: String
    let year: Int?
    let label: String?
    let genres: [String]
    let discogsId: Int?
    let thumbURL: String?
    let estimatedValue: Double?

    init(
        artist: String,
        albumTitle: String,
        year: Int? = nil,
        label: String? = nil,
        genres: [String] = [],
        discogsId: Int? = nil,
        thumbURL: String? = nil,
        estimatedValue: Double? = nil
    ) {
        self.artist = artist
        self.albumTitle = albumTitle
        self.year = year
        self.label = label
        self.genres = genres
        self.discogsId = discogsId
        self.thumbURL = thumbURL
        self.estimatedValue = estimatedValue
        super.init()
    }
}
