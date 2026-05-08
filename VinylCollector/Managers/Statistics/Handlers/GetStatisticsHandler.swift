import Foundation

final class GetStatisticsHandler: IHandler {
    private let recordAccessor: IRecordAccessor
    private let statisticsEngine: IStatisticsEngine

    init(recordAccessor: IRecordAccessor, statisticsEngine: IStatisticsEngine) {
        self.recordAccessor = recordAccessor
        self.statisticsEngine = statisticsEngine
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? GetStatisticsRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let loadResponse = await recordAccessor.load(LoadAllRecordsRequest())
        guard loadResponse.success, let loadResult = loadResponse as? LoadAllRecordsResponse else {
            return GetStatisticsResponse(
                correlationId: req.correlationId,
                errorMessage: loadResponse.errorMessage ?? "Failed to load records for statistics."
            )
        }

        let computeResponse = await statisticsEngine.evaluate(
            ComputeStatisticsRequest(records: loadResult.records)
        )
        guard computeResponse.success,
              let statistics = (computeResponse as? ComputeStatisticsResponse)?.statistics
        else {
            return GetStatisticsResponse(
                correlationId: req.correlationId,
                errorMessage: computeResponse.errorMessage ?? "Failed to compute statistics."
            )
        }

        return GetStatisticsResponse(correlationId: req.correlationId, statistics: statistics)
    }
}
