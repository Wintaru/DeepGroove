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
        let c = req.candidate
        let record = VinylRecord(
            artist: c.artist,
            albumTitle: c.albumTitle,
            year: c.year,
            label: c.label,
            catalogNumber: c.catalogNumber,
            genres: c.genres,
            styles: c.styles,
            country: c.country,
            discogsId: c.discogsId,
            notes: c.notes,
            condition: c.condition,
            artworkSource: c.artworkSource,
            estimatedValue: c.estimatedValue
        )
        record.appleMusicURL = c.appleMusicURL
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
