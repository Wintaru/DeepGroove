import Foundation
import SwiftData

@MainActor
final class SaveRecordHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SaveRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            modelContext.insert(req.record)
            try modelContext.save()
            return SaveRecordResponse(correlationId: req.correlationId, record: req.record)
        } catch {
            return SaveRecordResponse(correlationId: req.correlationId,
                                      errorMessage: error.localizedDescription)
        }
    }
}
