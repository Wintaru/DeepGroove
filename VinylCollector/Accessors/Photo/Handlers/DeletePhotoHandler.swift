import Foundation
import SwiftData

@MainActor
final class DeletePhotoHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? DeletePhotoRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            let id = req.photoId
            let all = try modelContext.fetch(FetchDescriptor<RecordPhoto>())
            guard let photo = all.first(where: { $0.id == id }) else {
                return DeletePhotoResponse(correlationId: req.correlationId,
                                           errorMessage: "Photo not found: \(id)")
            }
            // Delete file from disk
            try? FileManager.default.removeItem(atPath: photo.resolvedPath)
            modelContext.delete(photo)
            try modelContext.save()
            return DeletePhotoResponse(correlationId: req.correlationId)
        } catch {
            return DeletePhotoResponse(correlationId: req.correlationId,
                                       errorMessage: error.localizedDescription)
        }
    }
}
