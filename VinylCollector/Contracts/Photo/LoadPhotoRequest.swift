import Foundation

final class LoadPhotoRequest: RequestBase, @unchecked Sendable {
    let photoPath: String

    init(photoPath: String) {
        self.photoPath = photoPath
        super.init()
    }
}
