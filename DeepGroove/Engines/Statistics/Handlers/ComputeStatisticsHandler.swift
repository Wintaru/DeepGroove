import Foundation

final class ComputeStatisticsHandler: IHandler {

    private static let topArtistCount = 10
    private static let recentlyAddedCount = 5

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? ComputeStatisticsRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        let records = req.records
        let statistics = CollectionStatistics(
            totalRecords: records.count,
            totalEstimatedValue: totalValue(of: records),
            topArtists: topArtists(in: records),
            genreBreakdown: genreBreakdown(in: records),
            decadeBreakdown: decadeBreakdown(in: records),
            conditionBreakdown: conditionBreakdown(in: records),
            mostRecentlyAdded: recentlyAdded(from: records)
        )

        return ComputeStatisticsResponse(correlationId: req.correlationId, statistics: statistics)
    }

    // MARK: - Private computation methods

    private func totalValue(of records: [VinylRecord]) -> Double {
        records.compactMap { $0.estimatedValue }.reduce(0, +)
    }

    private func topArtists(in records: [VinylRecord]) -> [ArtistStat] {
        let counts = records.reduce(into: [String: Int]()) { $0[$1.artist, default: 0] += 1 }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(Self.topArtistCount)
            .map { ArtistStat(artist: $0.key, recordCount: $0.value) }
    }

    private func genreBreakdown(in records: [VinylRecord]) -> [GenreStat] {
        guard !records.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for record in records {
            for genre in record.genres {
                counts[genre, default: 0] += 1
            }
        }
        let total = Double(records.count)
        return counts
            .sorted { $0.value > $1.value }
            .map { GenreStat(genre: $0.key,
                             recordCount: $0.value,
                             percentage: Double($0.value) / total * 100) }
    }

    private func decadeBreakdown(in records: [VinylRecord]) -> [DecadeStat] {
        var counts: [Int: Int] = [:]
        for record in records {
            guard let year = record.year else { continue }
            let decade = (year / 10) * 10
            counts[decade, default: 0] += 1
        }
        return counts
            .sorted { $0.key < $1.key }
            .map { DecadeStat(decade: $0.key, recordCount: $0.value) }
    }

    private func conditionBreakdown(in records: [VinylRecord]) -> [RecordCondition: Int] {
        records.reduce(into: [RecordCondition: Int]()) { $0[$1.condition, default: 0] += 1 }
    }

    private func recentlyAdded(from records: [VinylRecord]) -> [VinylRecord] {
        Array(records.sorted { $0.dateAdded > $1.dateAdded }.prefix(Self.recentlyAddedCount))
    }
}
