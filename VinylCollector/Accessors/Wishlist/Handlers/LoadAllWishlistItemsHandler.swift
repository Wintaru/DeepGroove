import Foundation
import SwiftData

@MainActor
final class LoadAllWishlistItemsHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? LoadAllWishlistItemsRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            let all = try modelContext.fetch(FetchDescriptor<WishlistRecord>())
            let sorted = all.sorted { $0.dateAdded > $1.dateAdded }
            return LoadAllWishlistItemsResponse(correlationId: req.correlationId, items: sorted)
        } catch {
            return LoadAllWishlistItemsResponse(correlationId: req.correlationId,
                                                errorMessage: error.localizedDescription)
        }
    }
}
