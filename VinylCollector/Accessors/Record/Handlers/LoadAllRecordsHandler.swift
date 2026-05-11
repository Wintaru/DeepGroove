import Foundation
import SwiftData

@MainActor
final class LoadAllRecordsHandler: IHandler {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? LoadAllRecordsRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            let all = try modelContext.fetch(FetchDescriptor<VinylRecord>())
            let filtered = applyFilter(req.filter, to: all)
            let sorted = applySort(req.sortOrder, to: filtered)
            return LoadAllRecordsResponse(correlationId: req.correlationId, records: sorted)
        } catch {
            return LoadAllRecordsResponse(correlationId: req.correlationId,
                                          errorMessage: error.localizedDescription)
        }
    }

    private func applySort(_ order: CollectionSortOrder, to records: [VinylRecord]) -> [VinylRecord] {
        order.apply(to: records)
    }

    private func applyFilter(_ filter: CollectionFilter, to records: [VinylRecord]) -> [VinylRecord] {
        var result = records

        if let searchText = filter.searchText, !searchText.isEmpty {
            let lower = searchText.lowercased()
            result = result.filter {
                $0.artist.lowercased().contains(lower) ||
                $0.albumTitle.lowercased().contains(lower) ||
                ($0.label?.lowercased().contains(lower) ?? false)
            }
        }
        if let genres = filter.genres, !genres.isEmpty {
            result = result.filter { !Set($0.genres).isDisjoint(with: genres) }
        }
        if let artists = filter.artists, !artists.isEmpty {
            result = result.filter { artists.contains($0.artist) }
        }
        if let yearRange = filter.yearRange {
            result = result.filter { record in
                guard let year = record.year else { return false }
                return yearRange.contains(year)
            }
        }
        if let conditions = filter.conditions, !conditions.isEmpty {
            result = result.filter { conditions.contains($0.condition) }
        }
        if let labels = filter.labels, !labels.isEmpty {
            result = result.filter { record in
                guard let label = record.label else { return false }
                return labels.contains(label)
            }
        }
        return result
    }
}
