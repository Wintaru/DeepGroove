import UIKit

final class AttachPhotoRequest: RequestBase, @unchecked Sendable {
    let recordId: UUID
    let image: UIImage

    init(recordId: UUID, image: UIImage) {
        self.recordId = recordId
        self.image = image
        super.init()
    }
}
