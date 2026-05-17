import Foundation

final class NetworkUtility: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(url: URL, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    func post(url: URL, body: Data, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.httpError(statusCode: http.statusCode)
        }
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case invalidURL
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Invalid server response."
        case .invalidURL: "Invalid URL."
        case .httpError(let code): "HTTP error \(code)."
        }
    }
}
