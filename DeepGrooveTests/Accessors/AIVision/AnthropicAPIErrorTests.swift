import Foundation
import Testing
@testable import DeepGroove

@Suite("AnthropicAPIError")
struct AnthropicAPIErrorTests {

    private func errorBody(type: String, message: String) -> Data {
        Data(#"{"type":"error","error":{"type":"\#(type)","message":"\#(message)"},"request_id":"req_1"}"#.utf8)
    }

    @Test func unauthorized_reportsBadKey() {
        let error = NetworkError.httpError(statusCode: 401, body: nil)
        #expect(AnthropicAPIError.message(for: error) == "Anthropic rejected this API key. Check it was copied correctly in Settings.")
    }

    @Test func billingError_reportsBilling() {
        let error = NetworkError.httpError(statusCode: 402, body: nil)
        #expect(AnthropicAPIError.message(for: error).contains("billing issue"))
    }

    @Test func forbidden_reportsPermission() {
        let error = NetworkError.httpError(statusCode: 403, body: nil)
        #expect(AnthropicAPIError.message(for: error).contains("does not have permission"))
    }

    @Test func rateLimited_reportsRateLimit() {
        let error = NetworkError.httpError(statusCode: 429, body: nil)
        #expect(AnthropicAPIError.message(for: error).contains("rate limit"))
    }

    @Test func serverError_reportsTemporary() {
        let error = NetworkError.httpError(statusCode: 500, body: nil)
        #expect(AnthropicAPIError.message(for: error).contains("temporarily unavailable"))
    }

    @Test func overloaded_reportsTemporary() {
        let error = NetworkError.httpError(statusCode: 529, body: nil)
        #expect(AnthropicAPIError.message(for: error).contains("temporarily unavailable"))
    }

    @Test func badRequest_withDecodableBody_surfacesAPIMessage() {
        let body = errorBody(type: "invalid_request_error", message: "max_tokens: field required")
        let error = NetworkError.httpError(statusCode: 400, body: body)
        #expect(AnthropicAPIError.message(for: error) == "Anthropic rejected the request: max_tokens: field required")
    }

    @Test func badRequest_withoutDecodableBody_fallsBackToGenericMessage() {
        let error = NetworkError.httpError(statusCode: 400, body: nil)
        #expect(AnthropicAPIError.message(for: error) == "Anthropic returned an unexpected error (HTTP 400).")
    }

    @Test func nonNetworkError_fallsBackToLocalizedDescription() {
        struct OtherError: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        #expect(AnthropicAPIError.message(for: OtherError()) == "boom")
    }
}
