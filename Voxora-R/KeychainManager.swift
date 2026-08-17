import Foundation
import Security

final class KeychainManager {

    static let shared = KeychainManager()

    private init() {}

    private let service = "com.voxora.openrouter"
    private let account = "api-key"

    // MARK: - Save

    func saveAPIKey(_ apiKey: String) throws {

        guard !apiKey.isEmpty else {
            throw KeychainError.emptyValue
        }

        let data = Data(apiKey.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,

            kSecAttrService as String: service,

            kSecAttrAccount as String: account,

            kSecValueData as String: data,

            // Allow Voxora to access its own Keychain item
            // without repeatedly asking the user.
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlock
        ]

        // Remove the old item first.
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(
            query as CFDictionary,
            nil
        )

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }

        print("VOXORA: API KEY SAVED TO KEYCHAIN")
    }

    // MARK: - Load

    func loadAPIKey() throws -> String {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,

            kSecAttrService as String: service,

            kSecAttrAccount as String: account,

            kSecReturnData as String: true,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess else {

            if status == errSecItemNotFound {
                throw KeychainError.notFound
            }

            throw KeychainError.unableToRead(status)
        }

        guard let data = result as? Data,
              let apiKey = String(
                data: data,
                encoding: .utf8
              ) else {

            throw KeychainError.invalidData
        }

        return apiKey
    }

    // MARK: - Delete

    func deleteAPIKey() throws {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,

            kSecAttrService as String: service,

            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(
            query as CFDictionary
        )

        guard status == errSecSuccess ||
              status == errSecItemNotFound else {

            throw KeychainError.unableToDelete(status)
        }

        print("VOXORA: API KEY REMOVED")
    }

    // MARK: - Exists

    func hasAPIKey() -> Bool {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,

            kSecAttrService as String: service,

            kSecAttrAccount as String: account,

            kSecReturnData as String: false,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        let status = SecItemCopyMatching(
            query as CFDictionary,
            nil
        )

        return status == errSecSuccess
    }
}


// MARK: - Errors

enum KeychainError: LocalizedError {

    case emptyValue
    case notFound
    case invalidData
    case unableToSave(OSStatus)
    case unableToRead(OSStatus)
    case unableToDelete(OSStatus)

    var errorDescription: String? {

        switch self {

        case .emptyValue:
            return "The API key is empty."

        case .notFound:
            return "No OpenRouter API key was found."

        case .invalidData:
            return "The saved API key could not be read."

        case .unableToSave(let status):
            return "Could not save API key. Keychain status: \(status)"

        case .unableToRead(let status):
            return "Could not read API key. Keychain status: \(status)"

        case .unableToDelete(let status):
            return "Could not delete API key. Keychain status: \(status)"
        }
    }
}
