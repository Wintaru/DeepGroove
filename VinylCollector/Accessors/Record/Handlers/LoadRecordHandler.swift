import Foundation
import SwiftData

@MainActor
final class LoadRecordHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? LoadRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            guard let record = try modelContext.fetchFirst(VinylRecord.self, id: req.recordId) else {
                return LoadRecordResponse(correlationId: req.correlationId,
                                         errorMessage: "Record not found: \(req.recordId)")
            }
            return LoadRecordResponse(correlationId: req.correlationId, record: record)
        } catch {
            return LoadRecordResponse(correlationId: req.correlationId,
                                      errorMessage: error.localizedDescription)
        }
    }
}
