import Foundation
import SwiftData

enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [VinylRecord.self, RecordPhoto.self, WishlistRecord.self]

    @Model
    final class VinylRecord {
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
        var dateAdded: Date = Date()
        var lastModified: Date = Date()

        @Relationship(deleteRule: .cascade)
        var photos: [RecordPhoto]? = []

        init() {}
    }

    @Model
    final class RecordPhoto {
        var id: UUID = UUID()
        var photoPath: String = ""
        var photoType: PhotoType = PhotoType.userCapture
        var dateAdded: Date = Date()
        var record: VinylRecord?

        init() {}
    }

    @Model
    final class WishlistRecord {
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

        init() {}
    }
}
