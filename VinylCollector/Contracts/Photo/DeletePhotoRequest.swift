import Foundation

final class DeletePhotoRequest: RequestBase {
    let photoId: UUID

    init(photoId: UUID) {
        self.photoId = photoId
        super.init()
    }
}
