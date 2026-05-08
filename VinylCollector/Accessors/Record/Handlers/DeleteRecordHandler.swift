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
            let all = try modelContext.fetch(FetchDescriptor<VinylRecord>())
            guard let record = all.first(where: { $0.id == id }) else {
                return DeleteRecordResponse(correlationId: req.correlationId,
                                            errorMessage: "Record not found: \(id)")
            }

            // Collect photo paths before deleting (cascade will remove the DB rows)
            let photoPaths = (record.photos ?? []).map { $0.resolvedPath }

            // Delete record — cascade rule removes RecordPhoto rows automatically
            modelContext.delete(record)
            try modelContext.save()

            // Clean up files from disk after the save succeeds
            for path in photoPaths {
                try? FileManager.default.removeItem(atPath: path)
            }

            return DeleteRecordResponse(correlationId: req.correlationId)
        } catch {
            return DeleteRecordResponse(correlationId: req.correlationId,
                                        errorMessage: error.localizedDescription)
        }
    }
}
