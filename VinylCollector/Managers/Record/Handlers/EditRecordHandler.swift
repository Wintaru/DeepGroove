import Foundation
import SwiftData

@MainActor
final class EditRecordHandler: IHandler {
    private let recordAccessor: IRecordAccessor
    private let modelContext: ModelContext

    init(recordAccessor: IRecordAccessor, modelContext: ModelContext) {
        self.recordAccessor = recordAccessor
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? EditRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let loadResponse = await recordAccessor.load(LoadRecordRequest(recordId: req.recordId))
        guard loadResponse.success, let record = (loadResponse as? LoadRecordResponse)?.record else {
            return EditRecordResponse(
                correlationId: req.correlationId,
                errorMessage: loadResponse.errorMessage ?? "Record not found."
            )
        }

        if let artist = req.artist { record.artist = artist }
        if let albumTitle = req.albumTitle { record.albumTitle = albumTitle }
        if let year = req.year { record.year = year }
        if let label = req.label { record.label = label }
        if let catalogNumber = req.catalogNumber { record.catalogNumber = catalogNumber }
        if let genres = req.genres { record.genres = genres }
        if let styles = req.styles { record.styles = styles }
        if let country = req.country { record.country = country }
        if let notes = req.notes { record.notes = notes }
        if let condition = req.condition { record.condition = condition }
        if let artworkPreference = req.artworkPreference { record.artworkSource = artworkPreference }
        if let discogsId = req.discogsId { record.discogsId = discogsId }
        record.lastModified = Date()

        do {
            try modelContext.save()
        } catch {
            return EditRecordResponse(correlationId: req.correlationId,
                                      errorMessage: error.localizedDescription)
        }

        return EditRecordResponse(correlationId: req.correlationId, record: record)
    }
}
