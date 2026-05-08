import Foundation

final class ParseIdentificationHandler: IHandler {

    private static let minimumYear = 1900
    private static let maximumYear = Calendar.current.component(.year, from: Date()) + 1

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? ParseIdentificationRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }

        guard let json = extractJSON(from: req.rawJSON),
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return ParseIdentificationResponse(
                correlationId: req.correlationId,
                errorMessage: "Could not parse identification JSON."
            )
        }

        if dict["unidentifiable"] as? Bool == true {
            return ParseIdentificationResponse(
                correlationId: req.correlationId,
                errorMessage: "Record could not be identified."
            )
        }

        let artist = (dict["artist"] as? String)?.trimmingCharacters(in: .whitespaces)
        let albumTitle = (dict["albumTitle"] as? String)?.trimmingCharacters(in: .whitespaces)

        guard let validArtist = artist, !validArtist.isEmpty,
              let validTitle = albumTitle, !validTitle.isEmpty
        else {
            return ParseIdentificationResponse(
                correlationId: req.correlationId,
                errorMessage: "Identification missing required artist or album title."
            )
        }

        let rawYear = dict["year"] as? Int
        let validatedYear = rawYear.flatMap { year -> Int? in
            (Self.minimumYear...Self.maximumYear).contains(year) ? year : nil
        }

        let identification = AIIdentification(
            artist: validArtist,
            albumTitle: validTitle,
            year: validatedYear,
            label: (dict["label"] as? String)?.trimmingCharacters(in: .whitespaces),
            catalogNumber: (dict["catalogNumber"] as? String)?.trimmingCharacters(in: .whitespaces),
            genres: (dict["genres"] as? [String])?.map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            country: (dict["country"] as? String)?.trimmingCharacters(in: .whitespaces),
            rawJSON: req.rawJSON
        )

        return ParseIdentificationResponse(correlationId: req.correlationId, identification: identification)
    }

    private func extractJSON(from text: String) -> String? {
        guard let start = text.range(of: "{"),
              let end = text.range(of: "}", options: .backwards)
        else { return nil }
        return String(text[start.lowerBound...end.upperBound])
    }
}
