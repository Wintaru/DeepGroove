import Foundation
import SwiftData

@Model
final class RecordPhoto: ModelWithUUID {
    var id: UUID = UUID()
    var photoPath: String = ""  // relative path from Documents directory, e.g. "RecordPhotos/uuid.jpg"
    var photoType: PhotoType = PhotoType.userCapture
    var dateAdded: Date = Date()
    var record: VinylRecord?

    init(id: UUID = UUID(), photoPath: String, photoType: PhotoType) {
        self.id = id
        self.photoPath = photoPath
        self.photoType = photoType
        self.dateAdded = Date()
    }

    // Resolves the stored relative path to the current absolute path.
    // The app container UUID changes on reinstall, so we never store absolute paths.
    var resolvedPath: String {
        FileManagerUtility().resolvedPath(for: photoPath)
    }
}

enum PhotoType: String, Codable, CaseIterable, Sendable {
    case userCapture = "user_capture"
    case artwork = "artwork"
}
