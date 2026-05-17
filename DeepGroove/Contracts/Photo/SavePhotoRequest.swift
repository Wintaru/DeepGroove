import UIKit

final class SavePhotoRequest: RequestBase, @unchecked Sendable {
    let image: UIImage
    let photoType: PhotoType
    let recordId: UUID

    init(image: UIImage, photoType: PhotoType, recordId: UUID) {
        self.image = image
        self.photoType = photoType
        self.recordId = recordId
        super.init()
    }
}
