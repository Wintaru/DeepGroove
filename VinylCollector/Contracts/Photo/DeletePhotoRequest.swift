import Foundation

final class DeletePhotoRequest: RequestBase, @unchecked Sendable {
    let photoId: UUID

    init(photoId: UUID) {
        self.photoId = photoId
        super.init()
    }
}
