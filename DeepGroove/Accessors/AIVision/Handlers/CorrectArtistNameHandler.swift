import Foundation

final class CorrectArtistNameHandler: IHandler {
    private let networkUtility: NetworkUtility

    init(networkUtility: NetworkUtility) {
        self.networkUtility = networkUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? CorrectArtistNameRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        let prompt = """
            A user typed "\(req.input)" as an artist name when searching for a vinyl record, but it returned no results. \
            What well-known recording artist do you think they most likely meant? \
            Reply with only the correctly spelled artist name and nothing else. \
            If you have no reasonable guess, reply with exactly: unknown
            """
        do {
            let body = AnthropicTextRequest(
                model: "claude-haiku-4-5-20251001",
                maxTokens: 64,
                messages: [AnthropicTextMessage(role: "user", content: prompt)]
            )
            let bodyData = try JSONEncoder().encode(body)
            let headers = [
                "x-api-key": req.apiKey,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json"
            ]
            let responseData = try await networkUtility.post(
                url: URL(string: "https://api.anthropic.com/v1/messages")!,
                body: bodyData,
                headers: headers
            )
            let decoded = try JSONDecoder().decode(AnthropicTextResponse.self, from: responseData)
            let text = decoded.content.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty, text.lowercased() != "unknown" else {
                return CorrectArtistNameResponse(correlationId: req.correlationId,
                                                errorMessage: "No correction found.")
            }
            return CorrectArtistNameResponse(correlationId: req.correlationId, correctedName: text)
        } catch {
            return CorrectArtistNameResponse(correlationId: req.correlationId,
                                            errorMessage: error.localizedDescription)
        }
    }
}

// MARK: - Private API types

private struct AnthropicTextRequest: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [AnthropicTextMessage]
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

private struct AnthropicTextMessage: Encodable {
    let role: String
    let content: String
}

private struct AnthropicTextResponse: Decodable {
    let content: [AnthropicTextContent]
}

private struct AnthropicTextContent: Decodable {
    let type: String
    let text: String?
}
