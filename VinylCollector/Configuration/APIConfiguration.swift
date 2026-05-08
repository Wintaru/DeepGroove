import Foundation

final class APIConfiguration: ObservableObject, @unchecked Sendable {
    private enum Keys {
        static let anthropicKey = "vc_anthropic_api_key"
        static let discogsToken = "vc_discogs_token"
    }

    @Published var anthropicAPIKey: String {
        didSet { UserDefaults.standard.set(anthropicAPIKey, forKey: Keys.anthropicKey) }
    }

    @Published var discogsToken: String? {
        didSet { UserDefaults.standard.set(discogsToken, forKey: Keys.discogsToken) }
    }

    init() {
        self.anthropicAPIKey = UserDefaults.standard.string(forKey: Keys.anthropicKey) ?? ""
        self.discogsToken = UserDefaults.standard.string(forKey: Keys.discogsToken)
    }

    var isValid: Bool { !anthropicAPIKey.isEmpty }
}
