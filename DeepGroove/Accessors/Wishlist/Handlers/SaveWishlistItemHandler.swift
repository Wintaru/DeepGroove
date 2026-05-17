import Foundation
import SwiftData

@MainActor
final class SaveWishlistItemHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SaveWishlistItemRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        let item = WishlistRecord(
            artist: req.artist,
            albumTitle: req.albumTitle,
            year: req.year,
            label: req.label,
            genres: req.genres,
            discogsId: req.discogsId,
            thumbURL: req.thumbURL,
            estimatedValue: req.estimatedValue
        )
        do {
            modelContext.insert(item)
            try modelContext.save()
            return SaveWishlistItemResponse(correlationId: req.correlationId, itemId: item.id)
        } catch {
            return SaveWishlistItemResponse(correlationId: req.correlationId,
                                            errorMessage: error.localizedDescription)
        }
    }
}
