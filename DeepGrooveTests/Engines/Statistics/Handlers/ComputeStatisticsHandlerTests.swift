import Foundation
import Testing
@testable import DeepGroove

// MARK: - Test helper

@MainActor
private func makeRecord(
    artist: String = "Unknown Artist",
    albumTitle: String = "Unknown Album",
    year: Int? = nil,
    genres: [String] = [],
    condition: RecordCondition = .veryGoodPlus,
    estimatedValue: Double? = nil,
    dateAdded: Date = Date()
) -> VinylRecord {
    let record = VinylRecord(
        artist: artist,
        albumTitle: albumTitle,
        year: year,
        genres: genres,
        condition: condition,
        estimatedValue: estimatedValue
    )
    record.dateAdded = dateAdded
    return record
}

// MARK: - Tests

@MainActor
@Suite("ComputeStatisticsHandler")
struct ComputeStatisticsHandlerTests {

    let handler = ComputeStatisticsHandler()

    // MARK: - Wrong request type

    @Test func unhandledRequest() async throws {
        let response = await handler.handle(RequestBase())
        #expect(response is UnhandledRequestResponse)
        #expect(response.success == false)
    }

    // MARK: - Empty collection

    @Test func emptyCollection_zeros() async throws {
        let request = ComputeStatisticsRequest(records: [])
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        #expect(response.success == true)
        let stats = try #require(response.statistics)
        #expect(stats.totalRecords == 0)
        #expect(stats.totalEstimatedValue == 0)
        #expect(stats.topArtists.isEmpty)
        #expect(stats.genreBreakdown.isEmpty)
        #expect(stats.decadeBreakdown.isEmpty)
        #expect(stats.conditionBreakdown.isEmpty)
        #expect(stats.mostRecentlyAdded.isEmpty)
    }

    // MARK: - Total records

    @Test func totalRecords_matchesCount() async throws {
        let records = [
            makeRecord(artist: "A"),
            makeRecord(artist: "B"),
            makeRecord(artist: "C")
        ]
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        #expect(stats.totalRecords == 3)
    }

    // MARK: - Estimated value

    @Test func totalEstimatedValue_sumOfNonNilValues() async throws {
        let records = [
            makeRecord(estimatedValue: 10.0),
            makeRecord(estimatedValue: nil),
            makeRecord(estimatedValue: 25.50)
        ]
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        #expect(stats.totalEstimatedValue == 35.50)
    }

    // MARK: - Top artists

    @Test func topArtists_sortedDescendingByCount() async throws {
        let records = [
            makeRecord(artist: "Pink Floyd"),
            makeRecord(artist: "Pink Floyd"),
            makeRecord(artist: "Pink Floyd"),
            makeRecord(artist: "Radiohead"),
            makeRecord(artist: "Radiohead"),
            makeRecord(artist: "Kraftwerk")
        ]
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        #expect(stats.topArtists.count == 3)
        #expect(stats.topArtists[0].artist == "Pink Floyd")
        #expect(stats.topArtists[0].recordCount == 3)
        #expect(stats.topArtists[1].artist == "Radiohead")
        #expect(stats.topArtists[1].recordCount == 2)
        #expect(stats.topArtists[2].artist == "Kraftwerk")
        #expect(stats.topArtists[2].recordCount == 1)
    }

    @Test func topArtists_cappedAtTen() async throws {
        let records = (1...12).map { i in makeRecord(artist: "Artist \(i)") }
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        #expect(stats.topArtists.count == 10)
    }

    // MARK: - Genre breakdown

    @Test func genreBreakdown_percentagesCorrect() async throws {
        let records = [
            makeRecord(genres: ["Rock"]),
            makeRecord(genres: ["Rock"]),
            makeRecord(genres: ["Jazz"])
        ]
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        let rock = try #require(stats.genreBreakdown.first(where: { $0.genre == "Rock" }))
        let jazz = try #require(stats.genreBreakdown.first(where: { $0.genre == "Jazz" }))

        #expect(rock.recordCount == 2)
        #expect(rock.percentage.rounded() == 67)
        #expect(jazz.recordCount == 1)
        #expect(jazz.percentage.rounded() == 33)
    }

    @Test func genreBreakdown_multipleGenresPerRecord() async throws {
        let records = [
            makeRecord(genres: ["Rock", "Pop"]),
            makeRecord(genres: ["Rock"])
        ]
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        let rock = try #require(stats.genreBreakdown.first(where: { $0.genre == "Rock" }))
        let pop = try #require(stats.genreBreakdown.first(where: { $0.genre == "Pop" }))

        #expect(rock.recordCount == 2)
        #expect(pop.recordCount == 1)
    }

    @Test func genreBreakdown_emptyCollection() async throws {
        let request = ComputeStatisticsRequest(records: [])
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        #expect(stats.genreBreakdown.isEmpty)
    }

    // MARK: - Decade breakdown

    @Test func decadeBreakdown_sortedAscending() async throws {
        let records = [
            makeRecord(year: 1985),
            makeRecord(year: 1972),
            makeRecord(year: 1993)
        ]
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        let decades = stats.decadeBreakdown.map { $0.decade }
        #expect(decades == [1970, 1980, 1990])
    }

    @Test func decadeBreakdown_skipsNilYear() async throws {
        let records = [
            makeRecord(year: 1980),
            makeRecord(year: nil)
        ]
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        #expect(stats.decadeBreakdown.count == 1)
        #expect(stats.decadeBreakdown[0].decade == 1980)
    }

    // MARK: - Condition breakdown

    @Test func conditionBreakdown_correctCounts() async throws {
        let records = [
            makeRecord(condition: .mint),
            makeRecord(condition: .mint),
            makeRecord(condition: .good)
        ]
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        #expect(stats.conditionBreakdown[.mint] == 2)
        #expect(stats.conditionBreakdown[.good] == 1)
        #expect(stats.conditionBreakdown[.veryGoodPlus] == nil)
    }

    // MARK: - Recently added

    @Test func mostRecentlyAdded_sortedDescending_cappedAtFive() async throws {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let records = (0..<7).map { i in
            makeRecord(
                artist: "Artist \(i)",
                dateAdded: base.addingTimeInterval(Double(i) * 3600)
            )
        }
        let request = ComputeStatisticsRequest(records: records)
        let response = await handler.handle(request) as! ComputeStatisticsResponse

        let stats = try #require(response.statistics)
        #expect(stats.mostRecentlyAdded.count == 5)
        // Most recent first: index 6, 5, 4, 3, 2
        #expect(stats.mostRecentlyAdded[0].artist == "Artist 6")
        #expect(stats.mostRecentlyAdded[4].artist == "Artist 2")
    }
}
