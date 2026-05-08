import Foundation

struct ArtistStat: Sendable {
    let artist: String
    let recordCount: Int
}

struct GenreStat: Sendable {
    let genre: String
    let recordCount: Int
    let percentage: Double
}

struct DecadeStat: Sendable {
    let decade: Int
    let recordCount: Int
}

struct CollectionStatistics: Sendable {
    let totalRecords: Int
    let totalEstimatedValue: Double
    let topArtists: [ArtistStat]
    let genreBreakdown: [GenreStat]
    let decadeBreakdown: [DecadeStat]
    let conditionBreakdown: [RecordCondition: Int]
    let mostRecentlyAdded: [VinylRecord]
}

final class GetStatisticsResponse: ResponseBase {
    let statistics: CollectionStatistics?

    init(correlationId: UUID, statistics: CollectionStatistics) {
        self.statistics = statistics
        super.init(correlationId: correlationId, success: true)
    }

    init(correlationId: UUID, errorMessage: String) {
        self.statistics = nil
        super.init(correlationId: correlationId, success: false, errorMessage: errorMessage)
    }
}
