

#if canImport(CryptoKit)
    import CryptoKit
    import Foundation

    @propertyWrapper
    public struct Keychain<Value: RawRepresentable> where Value.RawValue == Data {
        private let key: String
        private let defaultValue: Value
        private let serviceName: String
        private let accessGroup: String?

        public var wrappedValue: Value {
            get { retriveSecKey() }
            set { storeValue(newValue) }
        }

        public init(
            key: String,
            defaultValue: Value,
            serviceName: String? = nil,
            accessGroup: String? = nil
        ) {
            self.key = key
            self.defaultValue = Value(rawValue: defaultValue.rawValue)!
            self.serviceName = serviceName ?? Bundle.main.bundleIdentifier ?? "CryptoCacheKit"
            self.accessGroup = accessGroup

            retriveSecKey()
        }

        private func setupQuery() -> [String: Any] {
            var result: [String: Any] = [:]
            result[kSecClass as String] = kSecClassKey
            result[kSecAttrApplicationTag as String] = key
            
            #if DEBUG
            #else
            result[kSecAttrService as String] = serviceName
            result[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            #endif

            if let accessGroup = accessGroup {
                result[kSecAttrAccessGroup as String] = accessGroup
            }

            return result
        }

        @discardableResult
        private func retriveSecKey() -> Value {
            var query = setupQuery()
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            query[kSecReturnData as String] = true

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            let generateAndSavePrivateKey = { () -> Value in
                storeValue(defaultValue)

                return defaultValue
            }

            return status == noErr ?
                Value(rawValue: result as! Data)!
                : generateAndSavePrivateKey()
        }

        private func storeValue(_ value: Value) {
            var query = setupQuery()

            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            query[kSecValueData as String] = value.rawValue

            if SecItemAdd(query as CFDictionary, nil) == errSecDuplicateItem {
                update(value)
            }
        }

        private func update(_ data: Value) {
            var query = setupQuery()
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

            SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        }
    }

#endif
