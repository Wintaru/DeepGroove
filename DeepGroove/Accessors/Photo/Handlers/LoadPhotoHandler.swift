import UIKit

final class LoadPhotoHandler: IHandler {
    private let imageUtility: ImageUtility
    private let fileManagerUtility: FileManagerUtility

    init(imageUtility: ImageUtility, fileManagerUtility: FileManagerUtility) {
        self.imageUtility = imageUtility
        self.fileManagerUtility = fileManagerUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? LoadPhotoRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        let path = fileManagerUtility.resolvedPath(for: req.photoPath)
        guard let image = imageUtility.loadFromDisk(path: path) else {
            return LoadPhotoResponse(correlationId: req.correlationId,
                                     errorMessage: "Image not found at path: \(path)")
        }
        return LoadPhotoResponse(correlationId: req.correlationId, image: image)
    }
}
