import Foundation
import SwiftData

@MainActor
final class UpdateRecordHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? UpdateRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            try modelContext.save()
            return UpdateRecordResponse(correlationId: req.correlationId)
        } catch {
            return UpdateRecordResponse(correlationId: req.correlationId,
                                        errorMessage: error.localizedDescription)
        }
    }
}
