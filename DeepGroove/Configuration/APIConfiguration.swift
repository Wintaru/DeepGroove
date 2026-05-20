import Foundation

@MainActor
final class APIConfiguration: ObservableObject, @unchecked Sendable {
    private enum Keys {
        static let anthropicKey = "vc_anthropic_api_key"
        static let discogsToken = "vc_discogs_token"
    }

    private static let appGroupID = "group.com.jdonner.deepgroove"

    private let keychain: KeychainUtility
    private let sharedKeychain: KeychainUtility

    @Published var anthropicAPIKey: String {
        didSet { keychain.set(anthropicAPIKey, forKey: Keys.anthropicKey) }
    }

    @Published var discogsToken: String? {
        didSet {
            if let token = discogsToken {
                sharedKeychain.set(token, forKey: Keys.discogsToken)
            } else {
                sharedKeychain.delete(forKey: Keys.discogsToken)
            }
        }
    }

    init() {
        let keychain = KeychainUtility()
        let sharedKeychain = KeychainUtility(accessGroup: APIConfiguration.appGroupID)
        self.keychain = keychain
        self.sharedKeychain = sharedKeychain

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

        // Discogs token — read from shared Keychain (access group), migrating from older
        // storage locations (private Keychain, then UserDefaults) if not yet migrated.
        let appGroup = UserDefaults(suiteName: APIConfiguration.appGroupID)
        if let token = sharedKeychain.get(forKey: Keys.discogsToken) {
            self.discogsToken = token
        } else if let token = keychain.get(forKey: Keys.discogsToken) {
            sharedKeychain.set(token, forKey: Keys.discogsToken)
            keychain.delete(forKey: Keys.discogsToken)
            appGroup?.removeObject(forKey: "discogsToken")
            self.discogsToken = token
        } else if let token = UserDefaults.standard.string(forKey: Keys.discogsToken) {
            sharedKeychain.set(token, forKey: Keys.discogsToken)
            UserDefaults.standard.removeObject(forKey: Keys.discogsToken)
            appGroup?.removeObject(forKey: "discogsToken")
            self.discogsToken = token
        } else {
            appGroup?.removeObject(forKey: "discogsToken")
            self.discogsToken = nil
        }
    }

    var isValid: Bool { !anthropicAPIKey.isEmpty }
}
