import Foundation
import SwiftData

@Model
final class RecordPhoto {
    @Attribute(.unique) var id: UUID
    var photoPath: String
    var photoType: PhotoType
    var dateAdded: Date
    var record: VinylRecord?

    init(id: UUID = UUID(), photoPath: String, photoType: PhotoType) {
        self.id = id
        self.photoPath = photoPath
        self.photoType = photoType
        self.dateAdded = Date()
    }
}

enum PhotoType: String, Codable, CaseIterable, Sendable {
    case userCapture = "user_capture"
    case artwork = "artwork"
}
