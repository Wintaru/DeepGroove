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
            let id = req.recordId
            let all = try modelContext.fetch(FetchDescriptor<VinylRecord>())
            guard let record = all.first(where: { $0.id == id }) else {
                return LoadRecordResponse(correlationId: req.correlationId,
                                         errorMessage: "Record not found: \(id)")
            }
            return LoadRecordResponse(correlationId: req.correlationId, record: record)
        } catch {
            return LoadRecordResponse(correlationId: req.correlationId,
                                      errorMessage: error.localizedDescription)
        }
    }
}
