import UIKit

final class IdentifyRecordRequest: RequestBase {
    let image: UIImage
    let apiKey: String

    init(image: UIImage, apiKey: String) {
        self.image = image
        self.apiKey = apiKey
        super.init()
    }
}
