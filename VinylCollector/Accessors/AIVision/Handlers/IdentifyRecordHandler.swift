import UIKit

final class IdentifyRecordHandler: IHandler {
    private let networkUtility: NetworkUtility
    private let imageUtility: ImageUtility

    private static let identificationPrompt = """
        You are a vinyl record expert. Identify the record in this image.
        Return ONLY a JSON object with these fields (omit any you cannot determine):
        {
          "artist": "Artist Name",
          "albumTitle": "Album Title",
          "year": 1979,
          "label": "Label Name",
          "catalogNumber": "CAT-001",
          "genres": ["Rock", "Blues"],
          "country": "US"
        }
        If you cannot identify the record at all, return: {"unidentifiable": true}
        """

    init(networkUtility: NetworkUtility, imageUtility: ImageUtility) {
        self.networkUtility = networkUtility
        self.imageUtility = imageUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? IdentifyRecordRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        guard let base64 = imageUtility.toBase64(image: req.image) else {
            return IdentifyRecordResponse(correlationId: req.correlationId,
                                          errorMessage: "Failed to encode image.")
        }
        do {
            let body = ClaudeRequest(
                model: "claude-sonnet-4-6",
                maxTokens: 1024,
                messages: [
                    ClaudeMessage(role: "user", content: [
                        ClaudeContent.image(base64: base64, mediaType: "image/jpeg"),
                        ClaudeContent.text(Self.identificationPrompt)
                    ])
                ]
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
            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: responseData)
            guard let text = claudeResponse.content.first?.text else {
                return IdentifyRecordResponse(correlationId: req.correlationId,
                                              errorMessage: "Empty response from Claude.")
            }
            let identification = parseIdentification(from: text, correlationId: req.correlationId)
            return IdentifyRecordResponse(correlationId: req.correlationId, identification: identification)
        } catch {
            return IdentifyRecordResponse(correlationId: req.correlationId,
                                          errorMessage: "AI identification failed: \(error.localizedDescription)")
        }
    }

    private func parseIdentification(from text: String, correlationId: UUID) -> AIIdentification {
        // Extract JSON from the response (Claude may wrap it in markdown code fences)
        let jsonString = extractJSON(from: text)
        guard
            let data = jsonString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return AIIdentification(artist: nil, albumTitle: nil, year: nil, label: nil,
                                    catalogNumber: nil, genres: [], country: nil, rawJSON: text)
        }
        return AIIdentification(
            artist: json["artist"] as? String,
            albumTitle: json["albumTitle"] as? String,
            year: json["year"] as? Int,
            label: json["label"] as? String,
            catalogNumber: json["catalogNumber"] as? String,
            genres: json["genres"] as? [String] ?? [],
            country: json["country"] as? String,
            rawJSON: text
        )
    }

    private func extractJSON(from text: String) -> String {
        // Strip markdown code fences if present
        if let start = text.range(of: "{"), let end = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text
    }
}

// MARK: - Private Claude API types

private struct ClaudeRequest: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

private struct ClaudeMessage: Encodable {
    let role: String
    let content: [ClaudeContent]
}

private enum ClaudeContent: Encodable {
    case text(String)
    case image(base64: String, mediaType: String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)
        case .image(let base64, let mediaType):
            try container.encode("image", forKey: .type)
            var sourceContainer = container.nestedContainer(keyedBy: SourceCodingKeys.self,
                                                            forKey: .source)
            try sourceContainer.encode("base64", forKey: .type)
            try sourceContainer.encode(mediaType, forKey: .mediaType)
            try sourceContainer.encode(base64, forKey: .data)
        }
    }

    enum CodingKeys: String, CodingKey { case type, text, source }
    enum SourceCodingKeys: String, CodingKey {
        case type, data
        case mediaType = "media_type"
    }
}

private struct ClaudeResponse: Decodable {
    let content: [ClaudeResponseContent]
}

private struct ClaudeResponseContent: Decodable {
    let type: String
    let text: String?
}
