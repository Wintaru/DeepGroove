import Foundation

final class RemoveRecordHandler: IHandler {
    private let recordAccessor: IRecordAccessor
    private let photoAccessor: IPhotoAccessor

    init(recordAccessor: IRecordAccessor, photoAccessor: IPhotoAccessor) {
        self.recordAccessor = recordAccessor
        self.photoAccessor = photoAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? RemoveRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let loadResponse = await recordAccessor.load(LoadRecordRequest(recordId: req.recordId))
        guard loadResponse.success, let record = (loadResponse as? LoadRecordResponse)?.record else {
            return RemoveRecordResponse(
                correlationId: req.correlationId,
                errorMessage: loadResponse.errorMessage ?? "Record not found."
            )
        }

        // Delete each photo file from disk before the SwiftData cascade removes the rows
        for photo in record.photos {
            await photoAccessor.remove(DeletePhotoRequest(photoId: photo.id))
        }

        let deleteResponse = await recordAccessor.remove(DeleteRecordRequest(recordId: req.recordId))
        guard deleteResponse.success else {
            return RemoveRecordResponse(
                correlationId: req.correlationId,
                errorMessage: deleteResponse.errorMessage ?? "Failed to delete record."
            )
        }

        return RemoveRecordResponse(correlationId: req.correlationId)
    }
}
