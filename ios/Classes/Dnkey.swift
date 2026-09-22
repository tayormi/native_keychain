import Foundation
import Security

// FFI contract: caller owns returned UTF-8 bytes and must call DnkeyFree.
@_cdecl("DnkeyRequest")
public func DnkeyRequest(_ input: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    guard let input else { return strdup("{\"error\":\"invalid_request\"}") }
    do {
        guard let bytes = String(cString: input).data(using: .utf8),
              let request = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else {
            throw StorageFailure("invalid_request")
        }
        let result = try handle(request)
        let data = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
        return strdup(String(decoding: data, as: UTF8.self))
    } catch let error as StorageFailure {
        let data = try! JSONSerialization.data(withJSONObject: ["error": error.code])
        return strdup(String(decoding: data, as: UTF8.self))
    } catch {
        return strdup("{\"error\":\"native_operation_failed\"}")
    }
}
@_cdecl("DnkeyFree")
public func DnkeyFree(_ pointer: UnsafeMutablePointer<CChar>?) {
    if let pointer {
        memset(pointer, 0, strlen(pointer))
        free(pointer)
    }
}
private struct StorageFailure: Error { let code: String; init(_ code: String) { self.code = code } }

// Source: https://developer.apple.com/documentation/security/keychain-services
private func handle(_ request: [String: Any]) throws -> [String: Any] {
    guard let operation = request["operation"] as? String,
          let service = request["service"] as? String, !service.isEmpty,
          let account = request["key"] as? String, !account.isEmpty else {
        throw StorageFailure("invalid_request")
    }
    // flutter_secure_storage's accountName maps to service, key maps to account.
    var query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecAttrSynchronizable as String: false
    ]
    if let group = request["accessGroup"] as? String {
        guard !group.isEmpty else { throw StorageFailure("invalid_access_group") }
        query[kSecAttrAccessGroup as String] = group
    }
    switch operation {
    case "read":
        query[kSecReturnData as String] = true
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return ["value": NSNull()] }
        guard status == errSecSuccess else { throw StorageFailure("keychain_\(status)") }
        guard let attributes = item as? [String: Any],
              let data = attributes[kSecValueData as String] as? Data else {
            throw StorageFailure("invalid_keychain_result")
        }
        return ["value": data.base64EncodedString(),
                "accessibility": attributes[kSecAttrAccessible as String] as? String ?? "unknown"]
    case "write":
        guard let encoded = request["value"] as? String,
              let data = Data(base64Encoded: encoded),
              let protection = request["accessibility"] as? String else {
            throw StorageFailure("invalid_value")
        }
        let accessibility: CFString
        switch protection {
        case "whenUnlockedThisDeviceOnly": accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case "afterFirstUnlockThisDeviceOnly": accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case "whenPasscodeSetThisDeviceOnly": accessibility = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        default: throw StorageFailure("invalid_accessibility")
        }
        let values: [String: Any] = [kSecValueData as String: data, kSecAttrAccessible as String: accessibility]
        var status = SecItemUpdate(query as CFDictionary, values as CFDictionary)
        if status == errSecItemNotFound {
            query.merge(values) { _, new in new }
            status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecDuplicateItem {
                for key in values.keys { query.removeValue(forKey: key) }
                status = SecItemUpdate(query as CFDictionary, values as CFDictionary)
            }
        }
        guard status == errSecSuccess else { throw StorageFailure("keychain_\(status)") }
        return ["written": true]
    case "delete":
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StorageFailure("keychain_\(status)")
        }
        return ["deleted": status == errSecSuccess]
    default: throw StorageFailure("unsupported_operation")
    }
}
