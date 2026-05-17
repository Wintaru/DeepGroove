import Foundation
import SwiftData

@MainActor
final class LoadAllRecordsHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? LoadAllRecordsRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            let all = try modelContext.fetch(FetchDescriptor<VinylRecord>())
            let sorted = req.sortOrder.apply(to: req.filter.applying(all))
            return LoadAllRecordsResponse(correlationId: req.correlationId, records: sorted)
        } catch {
            return LoadAllRecordsResponse(correlationId: req.correlationId,
                                          errorMessage: error.localizedDescription)
        }
    }
}
