import Foundation
import SwiftData

@Model
final class WishlistRecord: ModelWithUUID {
    var id: UUID = UUID()
    var artist: String = ""
    var albumTitle: String = ""
    var year: Int?
    var label: String?
    var genres: [String] = []
    var discogsId: Int?
    var thumbURL: String?
    var estimatedValue: Double?
    var dateAdded: Date = Date()

    init(
        id: UUID = UUID(),
        artist: String,
        albumTitle: String,
        year: Int? = nil,
        label: String? = nil,
        genres: [String] = [],
        discogsId: Int? = nil,
        thumbURL: String? = nil,
        estimatedValue: Double? = nil
    ) {
        self.id = id
        self.artist = artist
        self.albumTitle = albumTitle
        self.year = year
        self.label = label
        self.genres = genres
        self.discogsId = discogsId
        self.thumbURL = thumbURL
        self.estimatedValue = estimatedValue
        self.dateAdded = Date()
    }

    var displayTitle: String { "\(artist) – \(albumTitle)" }
}
