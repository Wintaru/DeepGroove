import UIKit

final class LoadPhotoResponse: ResponseBase {
    let image: UIImage?

    init(correlationId: UUID, image: UIImage) {
        self.image = image
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.image = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
