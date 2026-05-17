import Foundation
import SwiftData

@MainActor
final class DeletePhotoHandler: IHandler {
    private let modelContext: ModelContext
    private let fileManagerUtility: FileManagerUtility

    init(modelContext: ModelContext, fileManagerUtility: FileManagerUtility) {
        self.modelContext = modelContext
        self.fileManagerUtility = fileManagerUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? DeletePhotoRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            guard let photo = try modelContext.fetchFirst(RecordPhoto.self, id: req.photoId) else {
                return DeletePhotoResponse(correlationId: req.correlationId,
                                           errorMessage: "Photo not found: \(req.photoId)")
            }
            fileManagerUtility.removeFiles(atRelativePaths: [photo.photoPath])
            modelContext.delete(photo)
            try modelContext.save()
            return DeletePhotoResponse(correlationId: req.correlationId)
        } catch {
            return DeletePhotoResponse(correlationId: req.correlationId,
                                       errorMessage: error.localizedDescription)
        }
    }
}
