import Foundation

final class StringUtility: Sendable {
    // Extracts the first { ... } JSON object from a string, stripping markdown fences.
    func extractJSON(from text: String) -> String? {
        guard let start = text.range(of: "{"),
              let end = text.range(of: "}", options: .backwards),
              start.lowerBound <= end.lowerBound
        else { return nil }
        return String(text[start.lowerBound...end.lowerBound])
    }
}
