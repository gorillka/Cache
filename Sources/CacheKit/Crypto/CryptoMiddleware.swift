
#if canImport(CryptoKit)
    import CryptoKit
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public struct CryptoMiddleware {
        @Keychain(key: "privateKey", defaultValue: Curve25519.KeyAgreement.PrivateKey())
        private var privateKey: Curve25519.KeyAgreement.PrivateKey

        private func deriveSymmetricKey() throws -> SymmetricKey {
            try privateKey
                .sharedSecretFromKeyAgreement(with: privateKey.publicKey)
                .hkdfDerivedSymmetricKey(
                    using: SHA512.self,
                    salt: "com.chache.kit".data(using: .utf8)!,
                    sharedInfo: Data(),
                    outputByteCount: 32
                )
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension CryptoMiddleware: Middleware {
        public func encode(_ value: Data) throws -> Data {
            try AES.GCM.seal(value, using: deriveSymmetricKey()).combined!
        }

        public func decode(_ value: Data) throws -> Data {
            let sealedBox = try AES.GCM.SealedBox(combined: value)

            let symmetricKey = try deriveSymmetricKey()
            
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension Curve25519.KeyAgreement.PrivateKey: RawRepresentable {
        public var rawValue: Data { rawRepresentation }

        public init?(rawValue: Data) {
            try? self.init(rawRepresentation: rawValue)
        }
    }

#endif
