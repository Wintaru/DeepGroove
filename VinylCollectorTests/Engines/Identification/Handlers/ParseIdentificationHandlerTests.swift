import Foundation
import Testing
@testable import VinylCollector

@Suite("ParseIdentificationHandler")
struct ParseIdentificationHandlerTests {

    let handler = ParseIdentificationHandler()

    // MARK: - Wrong request type

    @Test func unhandledRequest() async throws {
        let response = await handler.handle(RequestBase())
        #expect(response is UnhandledRequestResponse)
        #expect(response.success == false)
    }

    // MARK: - Happy path

    @Test func validJSON_allFieldsParsed() async throws {
        let json = """
        {
            "artist": "Pink Floyd",
            "albumTitle": "The Wall",
            "year": 1979,
            "label": "Harvest",
            "catalogNumber": "SHDW 411",
            "genres": ["Rock", "Progressive Rock"],
            "country": "UK"
        }
        """
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == true)
        let id = try #require(response.identification)
        #expect(id.artist == "Pink Floyd")
        #expect(id.albumTitle == "The Wall")
        #expect(id.year == 1979)
        #expect(id.label == "Harvest")
        #expect(id.catalogNumber == "SHDW 411")
        #expect(id.genres == ["Rock", "Progressive Rock"])
        #expect(id.country == "UK")
    }

    // MARK: - Unidentifiable flag

    @Test func unidentifiableFlag_returnsError() async throws {
        let json = #"{"unidentifiable": true}"#
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == false)
        #expect(response.identification == nil)
        #expect(response.errorMessage == "Record could not be identified.")
    }

    // MARK: - Missing required fields

    @Test func missingArtist_returnsError() async throws {
        let json = #"{"albumTitle": "The Wall"}"#
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == false)
        #expect(response.identification == nil)
    }

    @Test func missingAlbumTitle_returnsError() async throws {
        let json = #"{"artist": "Pink Floyd"}"#
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == false)
        #expect(response.identification == nil)
    }

    @Test func emptyArtist_returnsError() async throws {
        let json = #"{"artist": "   ", "albumTitle": "The Wall"}"#
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == false)
        #expect(response.identification == nil)
    }

    @Test func emptyAlbumTitle_returnsError() async throws {
        let json = #"{"artist": "Pink Floyd", "albumTitle": "  "}"#
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == false)
        #expect(response.identification == nil)
    }

    // MARK: - Invalid JSON

    @Test func invalidJSON_returnsError() async throws {
        let request = ParseIdentificationRequest(rawJSON: "not json at all")
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == false)
        #expect(response.identification == nil)
        #expect(response.errorMessage == "Could not parse identification JSON.")
    }

    @Test func markdownFencedJSON_parsesCorrectly() async throws {
        let fenced = """
        ```json
        {"artist": "Radiohead", "albumTitle": "OK Computer"}
        ```
        """
        let request = ParseIdentificationRequest(rawJSON: fenced)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == true)
        #expect(response.identification?.artist == "Radiohead")
        #expect(response.identification?.albumTitle == "OK Computer")
    }

    // MARK: - Year validation

    @Test func yearBelowMinimum_nilYear() async throws {
        let json = #"{"artist": "Someone", "albumTitle": "Old Record", "year": 1800}"#
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == true)
        #expect(response.identification?.year == nil)
    }

    @Test func yearAboveMaximum_nilYear() async throws {
        let futureYear = Calendar.current.component(.year, from: Date()) + 5
        let json = "{\"artist\": \"Someone\", \"albumTitle\": \"Future Record\", \"year\": \(futureYear)}"
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == true)
        #expect(response.identification?.year == nil)
    }

    // MARK: - Whitespace trimming

    @Test func fieldWhitespace_trimmed() async throws {
        let json = """
        {
            "artist": "  Pink Floyd  ",
            "albumTitle": "  The Wall  ",
            "label": "  Harvest  ",
            "country": "  UK  "
        }
        """
        let request = ParseIdentificationRequest(rawJSON: json)
        let response = await handler.handle(request) as! ParseIdentificationResponse

        #expect(response.success == true)
        let id = try #require(response.identification)
        #expect(id.artist == "Pink Floyd")
        #expect(id.albumTitle == "The Wall")
        #expect(id.label == "Harvest")
        #expect(id.country == "UK")
    }
}
