import Foundation

@MainActor
final class APIConfiguration: ObservableObject, @unchecked Sendable {
    private enum Keys {
        static let anthropicKey = "vc_anthropic_api_key"
        static let discogsToken = "vc_discogs_token"
    }

    private let keychain: KeychainUtility

    @Published var anthropicAPIKey: String {
        didSet { keychain.set(anthropicAPIKey, forKey: Keys.anthropicKey) }
    }

    @Published var discogsToken: String? {
        didSet {
            let appGroup = UserDefaults(suiteName: "group.com.jdonner.deepgroove")
            if let token = discogsToken {
                keychain.set(token, forKey: Keys.discogsToken)
                appGroup?.set(token, forKey: "discogsToken")
            } else {
                keychain.delete(forKey: Keys.discogsToken)
                appGroup?.removeObject(forKey: "discogsToken")
            }
        }
    }

    init() {
        let keychain = KeychainUtility()
        self.keychain = keychain

        // Anthropic key — read from Keychain, migrate from UserDefaults if present
        if let key = keychain.get(forKey: Keys.anthropicKey) {
            self.anthropicAPIKey = key
        } else if let key = UserDefaults.standard.string(forKey: Keys.anthropicKey), !key.isEmpty {
            keychain.set(key, forKey: Keys.anthropicKey)
            UserDefaults.standard.removeObject(forKey: Keys.anthropicKey)
            self.anthropicAPIKey = key
        } else {
            self.anthropicAPIKey = ""
        }

        // Discogs token — read from Keychain, mirror to App Group for share extension
        let appGroup = UserDefaults(suiteName: "group.com.jdonner.deepgroove")
        if let token = keychain.get(forKey: Keys.discogsToken) {
            self.discogsToken = token
            appGroup?.set(token, forKey: "discogsToken")
        } else if let token = UserDefaults.standard.string(forKey: Keys.discogsToken) {
            keychain.set(token, forKey: Keys.discogsToken)
            UserDefaults.standard.removeObject(forKey: Keys.discogsToken)
            self.discogsToken = token
            appGroup?.set(token, forKey: "discogsToken")
        } else {
            self.discogsToken = nil
        }
    }

    var isValid: Bool { !anthropicAPIKey.isEmpty }
}
