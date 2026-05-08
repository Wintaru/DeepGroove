import UIKit

final class AttachPhotoRequest: RequestBase {
    let recordId: UUID
    let image: UIImage

    init(recordId: UUID, image: UIImage) {
        self.recordId = recordId
        self.image = image
        super.init()
    }
}
