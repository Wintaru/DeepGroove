import UIKit

@MainActor
final class AttachPhotoHandler: IHandler {
    private let photoAccessor: IPhotoAccessor

    init(photoAccessor: IPhotoAccessor) {
        self.photoAccessor = photoAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? AttachPhotoRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        let response = await photoAccessor.store(
            SavePhotoRequest(image: req.image, photoType: .userCapture, recordId: req.recordId)
        )
        if response.success {
            return AttachPhotoResponse(correlationId: req.correlationId)
        } else {
            return AttachPhotoResponse(correlationId: req.correlationId,
                                       errorMessage: response.errorMessage ?? "Failed to save photo.")
        }
    }
}
