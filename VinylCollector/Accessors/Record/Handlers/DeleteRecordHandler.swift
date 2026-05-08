import Foundation
import SwiftData

@MainActor
final class DeleteRecordHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? DeleteRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            let id = req.recordId
            let descriptor = FetchDescriptor<VinylRecord>(
                predicate: #Predicate { $0.id == id }
            )
            let results = try modelContext.fetch(descriptor)
            guard let record = results.first else {
                return DeleteRecordResponse(correlationId: req.correlationId,
                                            errorMessage: "Record not found: \(id)")
            }
            modelContext.delete(record)
            try modelContext.save()
            return DeleteRecordResponse(correlationId: req.correlationId)
        } catch {
            return DeleteRecordResponse(correlationId: req.correlationId,
                                        errorMessage: error.localizedDescription)
        }
    }
}
