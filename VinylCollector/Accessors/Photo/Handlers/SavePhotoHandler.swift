import UIKit
import SwiftData

@MainActor
final class SavePhotoHandler: IHandler {
    private let modelContext: ModelContext
    private let imageUtility: ImageUtility
    private let fileManagerUtility: FileManagerUtility

    init(modelContext: ModelContext, imageUtility: ImageUtility, fileManagerUtility: FileManagerUtility) {
        self.modelContext = modelContext
        self.imageUtility = imageUtility
        self.fileManagerUtility = fileManagerUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SavePhotoRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            let filename = "\(UUID().uuidString).jpg"
            try imageUtility.saveToDisk(image: req.image,
                                        directory: fileManagerUtility.photosDirectory,
                                        filename: filename)

            let relativePath = "RecordPhotos/\(filename)"
            let photo = RecordPhoto(photoPath: relativePath, photoType: req.photoType)

            if let record = try modelContext.fetchFirst(VinylRecord.self, id: req.recordId) {
                record.photos?.append(photo)
            }

            modelContext.insert(photo)
            try modelContext.save()
            return SavePhotoResponse(correlationId: req.correlationId, photo: photo)
        } catch {
            return SavePhotoResponse(correlationId: req.correlationId,
                                     errorMessage: error.localizedDescription)
        }
    }
}
