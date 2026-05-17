import Foundation
import SwiftData

@MainActor
final class DeleteRecordHandler: IHandler {
    private let modelContext: ModelContext
    private let fileManagerUtility: FileManagerUtility

    init(modelContext: ModelContext, fileManagerUtility: FileManagerUtility) {
        self.modelContext = modelContext
        self.fileManagerUtility = fileManagerUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? DeleteRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            guard let record = try modelContext.fetchFirst(VinylRecord.self, id: req.recordId) else {
                return DeleteRecordResponse(correlationId: req.correlationId,
                                            errorMessage: "Record not found: \(req.recordId)")
            }

            let relativePaths = (record.photos ?? []).map { $0.photoPath }
            modelContext.delete(record)
            try modelContext.save()
            fileManagerUtility.removeFiles(atRelativePaths: relativePaths)

            return DeleteRecordResponse(correlationId: req.correlationId)
        } catch {
            return DeleteRecordResponse(correlationId: req.correlationId,
                                        errorMessage: error.localizedDescription)
        }
    }
}
