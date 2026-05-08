import Foundation

@MainActor
final class RemoveRecordHandler: IHandler {
    private let recordAccessor: IRecordAccessor

    init(recordAccessor: IRecordAccessor, photoAccessor: IPhotoAccessor) {
        self.recordAccessor = recordAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? RemoveRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        let response = await recordAccessor.remove(DeleteRecordRequest(recordId: req.recordId))
        if response.success {
            return RemoveRecordResponse(correlationId: req.correlationId)
        } else {
            return RemoveRecordResponse(correlationId: req.correlationId,
                                        errorMessage: response.errorMessage ?? "Failed to delete record.")
        }
    }
}
