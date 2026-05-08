import UIKit
import SwiftData

@MainActor
final class SavePhotoHandler: IHandler {
    private let modelContext: ModelContext
    private let imageUtility: ImageUtility

    init(modelContext: ModelContext, imageUtility: ImageUtility) {
        self.modelContext = modelContext
        self.imageUtility = imageUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SavePhotoRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            let directory = photosDirectory()
            let filename = "\(UUID().uuidString).jpg"
            let fileURL = try imageUtility.saveToDisk(
                image: req.image,
                directory: directory,
                filename: filename
            )
            let photo = RecordPhoto(photoPath: fileURL.path, photoType: req.photoType)
            modelContext.insert(photo)
            try modelContext.save()
            return SavePhotoResponse(correlationId: req.correlationId, photo: photo)
        } catch {
            return SavePhotoResponse(correlationId: req.correlationId,
                                     errorMessage: error.localizedDescription)
        }
    }

    private func photosDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("RecordPhotos")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
