import Foundation

final class LoadPhotoRequest: RequestBase {
    let photoPath: String

    init(photoPath: String) {
        self.photoPath = photoPath
        super.init()
    }
}
