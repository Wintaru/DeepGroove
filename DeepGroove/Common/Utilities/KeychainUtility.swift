import Foundation
import Security

final class KeychainUtility: Sendable {
    private let service: String
    private let accessGroup: String?

    init(service: String = "com.jdonner.deepgroove", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    func set(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        if let group = accessGroup { query[kSecAttrAccessGroup] = group }
        if SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary) == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func get(forKey key: String) -> String? {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        if let group = accessGroup { query[kSecAttrAccessGroup] = group }
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(forKey key: String) {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        if let group = accessGroup { query[kSecAttrAccessGroup] = group }
        SecItemDelete(query as CFDictionary)
    }
}
