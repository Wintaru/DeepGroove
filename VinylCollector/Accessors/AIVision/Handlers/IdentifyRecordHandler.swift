import UIKit

final class IdentifyRecordHandler: IHandler {
    private let networkUtility: NetworkUtility
    private let imageUtility: ImageUtility

    private static let identificationPrompt = """
        You are an expert vinyl record identifier with deep knowledge of album art across all genres and eras.

        Examine this image carefully. It may show:
        - The full album cover (front or back)
        - Just the vinyl record label (the paper disc in the center)
        - A barcode or spine

        Use every visual clue available to identify the record:
        - Any visible text: artist name, album title, label name, catalog number, copyright year
        - Record label design: color, logo, font style (e.g. blue Columbia, orange Atlantic, Apple Records logo)
        - Artwork style, imagery, photography, or illustration that may be iconic or recognizable
        - Spine text if visible
        - Matrix/runout etchings if visible on the vinyl itself

        Even if the cover has no text and is primarily photographic or abstract art, do your best to identify it from the visual content alone. Many iconic albums are recognizable purely by their artwork.

        Return ONLY a valid JSON object with these fields (omit fields you cannot determine with reasonable confidence):
        {
          "artist": "Artist Name",
          "albumTitle": "Album Title",
          "year": 1979,
          "label": "Label Name",
          "catalogNumber": "CAT-001",
          "genres": ["Rock", "Blues"],
          "country": "US"
        }

        Only return {"unidentifiable": true} if you truly have no useful information at all. Even a partial identification (just artist, or just album title) is valuable — include whatever you can determine.
        """

    private let stringUtility = StringUtility()

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
        let jsonString = stringUtility.extractJSON(from: text) ?? text
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
