import Foundation

struct APIConfiguration: Sendable {
    let anthropicAPIKey: String
    let discogsToken: String?

    static let empty = APIConfiguration(anthropicAPIKey: "", discogsToken: nil)

    var isValid: Bool { !anthropicAPIKey.isEmpty }
}
