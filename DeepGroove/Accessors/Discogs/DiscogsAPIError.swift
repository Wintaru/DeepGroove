import Foundation

// Translates a Discogs API HTTP failure into a message a user can act on.
// Discogs error bodies are a flat {"message": "..."} shape; status codes documented at
// https://www.discogs.com/developers
enum DiscogsAPIError {
    static func message(for error: Error) -> String {
        guard case let NetworkError.httpError(statusCode, body) = error else {
            return error.localizedDescription
        }
        let apiMessage = body.flatMap { try? JSONDecoder().decode(ErrorBody.self, from: $0) }?.message

        switch statusCode {
        case 401:
            return "Discogs rejected this token. Check it was copied correctly in Settings."
        case 404:
            return "Discogs could not find that item."
        case 429:
            return "Discogs's rate limit was reached. Try again in a moment."
        case 422:
            if let apiMessage {
                return "Discogs rejected the request: \(apiMessage)"
            }
            return "Discogs rejected the request."
        case 500...599:
            return "Discogs's servers are temporarily unavailable. Try again shortly."
        default:
            if let apiMessage {
                return "Discogs returned an error: \(apiMessage)"
            }
            return "Discogs returned an unexpected error (HTTP \(statusCode))."
        }
    }

    private struct ErrorBody: Decodable {
        let message: String
    }
}
