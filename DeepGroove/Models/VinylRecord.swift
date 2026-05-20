import Foundation
import SwiftData

@Model
final class VinylRecord: ModelWithUUID {
    var id: UUID = UUID()
    var artist: String = ""
    var albumTitle: String = ""
    var year: Int?
    var label: String?
    var catalogNumber: String?
    var genres: [String] = []
    var styles: [String] = []
    var country: String?
    var barcode: String?
    var discogsId: Int?
    var notes: String?
    var condition: RecordCondition = RecordCondition.veryGoodPlus
    var artworkSource: ArtworkSource = ArtworkSource.downloaded
    var estimatedValue: Double?
    var appleMusicURL: String?
    var dateAdded: Date = Date()
    var lastModified: Date = Date()

    @Relationship(deleteRule: .cascade)
    var photos: [RecordPhoto]? = []

    init(
        id: UUID = UUID(),
        artist: String,
        albumTitle: String,
        year: Int? = nil,
        label: String? = nil,
        catalogNumber: String? = nil,
        genres: [String] = [],
        styles: [String] = [],
        country: String? = nil,
        barcode: String? = nil,
        discogsId: Int? = nil,
        notes: String? = nil,
        condition: RecordCondition = .veryGoodPlus,
        artworkSource: ArtworkSource = .downloaded,
        estimatedValue: Double? = nil
    ) {
        self.id = id
        self.artist = artist
        self.albumTitle = albumTitle
        self.year = year
        self.label = label
        self.catalogNumber = catalogNumber
        self.genres = genres
        self.styles = styles
        self.country = country
        self.barcode = barcode
        self.discogsId = discogsId
        self.notes = notes
        self.condition = condition
        self.artworkSource = artworkSource
        self.estimatedValue = estimatedValue
        self.dateAdded = Date()
        self.lastModified = Date()
        self.photos = []
    }

    var displayTitle: String { "\(artist) – \(albumTitle)" }
    var primaryPhoto: RecordPhoto? { (photos ?? []).first(where: { $0.photoType == .userCapture }) }
    var artworkPhoto: RecordPhoto? { (photos ?? []).first(where: { $0.photoType == .artwork }) }

    var thumbnailPhoto: RecordPhoto? {
        switch artworkSource {
        case .userPhoto: return primaryPhoto ?? artworkPhoto
        case .downloaded: return artworkPhoto ?? primaryPhoto
        case .both: return artworkPhoto ?? primaryPhoto
        }
    }
}

enum RecordCondition: String, Codable, CaseIterable, Sendable {
    case mint = "M"
    case nearMint = "NM"
    case veryGoodPlus = "VG+"
    case veryGood = "VG"
    case goodPlus = "G+"
    case good = "G"
    case fair = "F"
    case poor = "P"

    var displayName: String {
        switch self {
        case .mint: "Mint"
        case .nearMint: "Near Mint"
        case .veryGoodPlus: "Very Good+"
        case .veryGood: "Very Good"
        case .goodPlus: "Good+"
        case .good: "Good"
        case .fair: "Fair"
        case .poor: "Poor"
        }
    }
}

enum ArtworkSource: String, Codable, CaseIterable, Sendable {
    case userPhoto = "user_photo"
    case downloaded = "downloaded"
    case both = "both"

    var displayName: String {
        switch self {
        case .userPhoto: "My Photo"
        case .downloaded: "Album Art"
        case .both: "Both"
        }
    }
}
