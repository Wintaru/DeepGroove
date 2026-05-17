import Foundation

final class StringUtility: Sendable {
    func splitDiscogsTitle(_ title: String) -> (artist: String, album: String) {
        if let range = title.range(of: " - ") {
            return (String(title[..<range.lowerBound]), String(title[range.upperBound...]))
        }
        return ("", title)
    }

    // Extracts the first { ... } JSON object from a string, stripping markdown fences.
    func extractJSON(from text: String) -> String? {
        guard let start = text.range(of: "{"),
              let end = text.range(of: "}", options: .backwards),
              start.lowerBound <= end.lowerBound
        else { return nil }
        return String(text[start.lowerBound...end.lowerBound])
    }
}
