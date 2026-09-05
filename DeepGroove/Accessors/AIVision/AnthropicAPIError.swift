import Foundation

// Translates an Anthropic Messages API HTTP failure into a message a user can act on.
// Status codes and the {"error": {"type", "message"}} body shape are documented at
// https://platform.claude.com/docs/en/api/errors
enum AnthropicAPIError {
    static func message(for error: Error) -> String {
        guard case let NetworkError.httpError(statusCode, body) = error else {
            return error.localizedDescription
        }
        let apiMessage = body.flatMap { try? JSONDecoder().decode(ErrorBody.self, from: $0) }?.error.message

        switch statusCode {
        case 401:
            return "Anthropic rejected this API key. Check it was copied correctly in Settings."
        case 402:
            return "Anthropic reports a billing issue with this account. Check Plans & Billing at console.anthropic.com."
        case 403:
            return "This Anthropic API key does not have permission to use the Claude API."
        case 429:
            return "Anthropic's rate limit was reached. Try again in a moment."
        case 500, 529:
            return "Anthropic's servers are temporarily unavailable. Try again shortly."
        default:
            if let apiMessage {
                return "Anthropic rejected the request: \(apiMessage)"
            }
            return "Anthropic returned an unexpected error (HTTP \(statusCode))."
        }
    }

    private struct ErrorBody: Decodable {
        let error: ErrorDetail
        struct ErrorDetail: Decodable {
            let type: String
            let message: String
        }
    }
}
