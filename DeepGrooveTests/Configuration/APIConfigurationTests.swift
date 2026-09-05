import Foundation
import Testing
@testable import DeepGroove

// Mirrors APIConfiguration's private Keys enum — there's no way to share it without
// exposing an implementation detail, so these keys are duplicated here deliberately.
private enum TestKeys {
    static let anthropicKey = "vc_anthropic_api_key"
    static let discogsToken = "vc_discogs_token"
}

// Each test uses a freshly UUID-named Keychain service/access-group so runs never
// collide with each other or with real on-device app data, and clean up after themselves.
@MainActor
@Suite("APIConfiguration")
struct APIConfigurationTests {

    @Test func init_trimsAnthropicKeyAlreadyStoredInKeychain() {
        let service = "test.\(UUID().uuidString)"
        let keychain = KeychainUtility(service: service)
        let sharedKeychain = KeychainUtility(service: service, accessGroup: nil)
        keychain.set("sk-ant-abc123 \n", forKey: TestKeys.anthropicKey)
        defer { keychain.delete(forKey: TestKeys.anthropicKey) }

        let config = APIConfiguration(keychain: keychain, sharedKeychain: sharedKeychain)

        #expect(config.anthropicAPIKey == "sk-ant-abc123")
    }

    @Test func init_trimsDiscogsTokenAlreadyStoredInSharedKeychain() {
        let service = "test.\(UUID().uuidString)"
        let keychain = KeychainUtility(service: service)
        let sharedKeychain = KeychainUtility(service: service, accessGroup: nil)
        sharedKeychain.set(" tok-456\n", forKey: TestKeys.discogsToken)
        defer { sharedKeychain.delete(forKey: TestKeys.discogsToken) }

        let config = APIConfiguration(keychain: keychain, sharedKeychain: sharedKeychain)

        #expect(config.discogsToken == "tok-456")
    }

    @Test func settingAnthropicKey_trimsBeforeStoring() {
        let service = "test.\(UUID().uuidString)"
        let keychain = KeychainUtility(service: service)
        let sharedKeychain = KeychainUtility(service: service, accessGroup: nil)
        defer { keychain.delete(forKey: TestKeys.anthropicKey) }
        let config = APIConfiguration(keychain: keychain, sharedKeychain: sharedKeychain)

        config.anthropicAPIKey = "sk-ant-xyz \n"

        #expect(config.anthropicAPIKey == "sk-ant-xyz")
        #expect(keychain.get(forKey: TestKeys.anthropicKey) == "sk-ant-xyz")
    }

    @Test func settingDiscogsTokenToWhitespaceOnly_normalizesToNilAndDeletes() {
        let service = "test.\(UUID().uuidString)"
        let keychain = KeychainUtility(service: service)
        let sharedKeychain = KeychainUtility(service: service, accessGroup: nil)
        sharedKeychain.set("tok-456", forKey: TestKeys.discogsToken)
        defer { sharedKeychain.delete(forKey: TestKeys.discogsToken) }
        let config = APIConfiguration(keychain: keychain, sharedKeychain: sharedKeychain)

        config.discogsToken = "   "

        #expect(config.discogsToken == nil)
        #expect(sharedKeychain.get(forKey: TestKeys.discogsToken) == nil)
    }
}
