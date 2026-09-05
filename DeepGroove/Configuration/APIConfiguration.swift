import Foundation

@MainActor
final class APIConfiguration: ObservableObject, @unchecked Sendable {
    private enum Keys {
        static let anthropicKey = "vc_anthropic_api_key"
        static let discogsToken = "vc_discogs_token"
    }

    private let keychain: KeychainUtility
    private let sharedKeychain: KeychainUtility

    // Pasted keys routinely carry a trailing newline or space (copied from a web page or
    // notes app); left in place it becomes part of the HTTP header and both Anthropic's and
    // Discogs's edge servers reject the malformed header with a 400 instead of a clear 401.
    // `didSet` never fires for a property's own first assignment inside `init()`, so `init`
    // below calls `normalized(_:)` explicitly on every branch instead of relying on it.

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    // Re-assigning a normalized value re-enters didSet once; normalizing is idempotent so the
    // second pass falls through to the persist branch below instead of recursing further.
    @Published var anthropicAPIKey: String {
        didSet {
            let normalized = Self.normalized(anthropicAPIKey)
            guard normalized == anthropicAPIKey else {
                anthropicAPIKey = normalized
                return
            }
            keychain.set(anthropicAPIKey, forKey: Keys.anthropicKey)
        }
    }

    @Published var discogsToken: String? {
        didSet {
            let normalized = Self.normalized(discogsToken)
            guard normalized == discogsToken else {
                discogsToken = normalized
                return
            }
            if let token = discogsToken {
                sharedKeychain.set(token, forKey: Keys.discogsToken)
            } else {
                sharedKeychain.delete(forKey: Keys.discogsToken)
            }
        }
    }

    init(keychain: KeychainUtility = KeychainUtility(),
         sharedKeychain: KeychainUtility = KeychainUtility(accessGroup: AppGroup.id)) {
        self.keychain = keychain
        self.sharedKeychain = sharedKeychain

        // Anthropic key — read from Keychain, migrate from UserDefaults if present
        if let key = keychain.get(forKey: Keys.anthropicKey) {
            self.anthropicAPIKey = Self.normalized(key)
        } else if let key = UserDefaults.standard.string(forKey: Keys.anthropicKey), !key.isEmpty {
            let normalizedKey = Self.normalized(key)
            keychain.set(normalizedKey, forKey: Keys.anthropicKey)
            UserDefaults.standard.removeObject(forKey: Keys.anthropicKey)
            self.anthropicAPIKey = normalizedKey
        } else {
            self.anthropicAPIKey = ""
        }

        // Discogs token — read from shared Keychain (access group), migrating from older
        // storage locations (private Keychain, then UserDefaults) if not yet migrated.
        let appGroup = UserDefaults(suiteName: AppGroup.id)
        if let token = sharedKeychain.get(forKey: Keys.discogsToken) {
            self.discogsToken = Self.normalized(Optional(token))
        } else if let token = keychain.get(forKey: Keys.discogsToken) {
            let normalizedToken = Self.normalized(Optional(token))
            if let normalizedToken {
                sharedKeychain.set(normalizedToken, forKey: Keys.discogsToken)
            }
            keychain.delete(forKey: Keys.discogsToken)
            appGroup?.removeObject(forKey: "discogsToken")
            self.discogsToken = normalizedToken
        } else if let token = UserDefaults.standard.string(forKey: Keys.discogsToken) {
            let normalizedToken = Self.normalized(Optional(token))
            if let normalizedToken {
                sharedKeychain.set(normalizedToken, forKey: Keys.discogsToken)
            }
            UserDefaults.standard.removeObject(forKey: Keys.discogsToken)
            appGroup?.removeObject(forKey: "discogsToken")
            self.discogsToken = normalizedToken
        } else {
            appGroup?.removeObject(forKey: "discogsToken")
            self.discogsToken = nil
        }
    }

    var isValid: Bool { !anthropicAPIKey.isEmpty }
}
