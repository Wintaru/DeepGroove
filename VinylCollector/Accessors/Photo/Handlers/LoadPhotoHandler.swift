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
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let resolvedPath = docs.appendingPathComponent(req.photoPath).path
        guard let image = imageUtility.loadFromDisk(path: resolvedPath) else {
            return LoadPhotoResponse(correlationId: req.correlationId,
                                     errorMessage: "Image not found at path: \(resolvedPath)")
        }
        return LoadPhotoResponse(correlationId: req.correlationId, image: image)
    }
}
