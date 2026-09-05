import Foundation
import Testing
@testable import DeepGroove

@Suite("DiscogsAPIError")
struct DiscogsAPIErrorTests {

    private func errorBody(message: String) -> Data {
        Data(#"{"message":"\#(message)"}"#.utf8)
    }

    @Test func unauthorized_reportsBadToken() {
        let error = NetworkError.httpError(statusCode: 401, body: nil)
        #expect(DiscogsAPIError.message(for: error) == "Discogs rejected this token. Check it was copied correctly in Settings.")
    }

    @Test func notFound_reportsNotFound() {
        let error = NetworkError.httpError(statusCode: 404, body: nil)
        #expect(DiscogsAPIError.message(for: error).contains("could not find"))
    }

    @Test func rateLimited_reportsRateLimit() {
        let error = NetworkError.httpError(statusCode: 429, body: nil)
        #expect(DiscogsAPIError.message(for: error).contains("rate limit"))
    }

    @Test func unprocessable_withDecodableBody_surfacesAPIMessage() {
        let body = errorBody(message: "Invalid query parameter")
        let error = NetworkError.httpError(statusCode: 422, body: body)
        #expect(DiscogsAPIError.message(for: error) == "Discogs rejected the request: Invalid query parameter")
    }

    @Test func serverError_reportsTemporary() {
        let error = NetworkError.httpError(statusCode: 502, body: nil)
        #expect(DiscogsAPIError.message(for: error).contains("temporarily unavailable"))
    }

    @Test func unrecognizedStatus_withoutBody_fallsBackToGenericMessage() {
        let error = NetworkError.httpError(statusCode: 418, body: nil)
        #expect(DiscogsAPIError.message(for: error) == "Discogs returned an unexpected error (HTTP 418).")
    }

    @Test func nonNetworkError_fallsBackToLocalizedDescription() {
        struct OtherError: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        #expect(DiscogsAPIError.message(for: OtherError()) == "boom")
    }
}
