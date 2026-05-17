import Foundation

final class GetRecordHandler: IHandler {
    private let recordAccessor: IRecordAccessor

    init(recordAccessor: IRecordAccessor) {
        self.recordAccessor = recordAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? GetRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let loadResponse = await recordAccessor.load(LoadRecordRequest(recordId: req.recordId))
        guard loadResponse.success, let record = (loadResponse as? LoadRecordResponse)?.record else {
            return GetRecordResponse(
                correlationId: req.correlationId,
                errorMessage: loadResponse.errorMessage ?? "Record not found."
            )
        }

        return GetRecordResponse(correlationId: req.correlationId, record: record)
    }
}
