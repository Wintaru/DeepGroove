import Foundation

final class GetCollectionHandler: IHandler {
    private let recordAccessor: IRecordAccessor

    init(recordAccessor: IRecordAccessor) {
        self.recordAccessor = recordAccessor
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? GetCollectionRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let loadResponse = await recordAccessor.load(
            LoadAllRecordsRequest(filter: req.filter, sortOrder: req.sortOrder)
        )
        guard loadResponse.success, let loadResult = loadResponse as? LoadAllRecordsResponse else {
            return GetCollectionResponse(
                correlationId: req.correlationId,
                errorMessage: loadResponse.errorMessage ?? "Failed to load collection."
            )
        }

        var records = loadResult.records

        // Apply pagination if requested
        if let offset = req.offset {
            records = Array(records.dropFirst(offset))
        }
        if let limit = req.limit {
            records = Array(records.prefix(limit))
        }

        return GetCollectionResponse(
            correlationId: req.correlationId,
            records: records,
            totalCount: loadResult.records.count
        )
    }
}
