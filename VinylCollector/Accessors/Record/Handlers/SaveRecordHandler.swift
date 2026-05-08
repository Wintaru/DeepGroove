import Foundation
import SwiftData

@MainActor
final class SaveRecordHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? SaveRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        let d = req.data
        let record = VinylRecord(
            artist: d.artist,
            albumTitle: d.albumTitle,
            year: d.year,
            label: d.label,
            catalogNumber: d.catalogNumber,
            genres: d.genres,
            styles: d.styles,
            country: d.country,
            discogsId: d.discogsId,
            notes: d.notes,
            condition: d.condition,
            artworkSource: d.artworkSource,
            estimatedValue: d.estimatedValue
        )
        do {
            modelContext.insert(record)
            try modelContext.save()
            return SaveRecordResponse(correlationId: req.correlationId, recordId: record.id)
        } catch {
            return SaveRecordResponse(correlationId: req.correlationId,
                                      errorMessage: error.localizedDescription)
        }
    }
}
