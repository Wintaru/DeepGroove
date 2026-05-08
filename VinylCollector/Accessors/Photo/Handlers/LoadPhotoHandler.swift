import UIKit

final class LoadPhotoHandler: IHandler {
    private let imageUtility: ImageUtility

    init(imageUtility: ImageUtility) {
        self.imageUtility = imageUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? LoadPhotoRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        guard let image = imageUtility.loadFromDisk(path: req.photoPath) else {
            return LoadPhotoResponse(correlationId: req.correlationId,
                                     errorMessage: "Image not found at path: \(req.photoPath)")
        }
        return LoadPhotoResponse(correlationId: req.correlationId, image: image)
    }
}
