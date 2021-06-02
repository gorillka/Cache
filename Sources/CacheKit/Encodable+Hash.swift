
import func CommonCrypto.CC_SHA512
import var CommonCrypto.CC_SHA512_DIGEST_LENGTH
import Foundation

#if canImport(CryptoKit)
    import CryptoKit
#endif

extension Encodable {
    var hash: String {
        do {
            return try encoded().hash
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

extension Data {
    private var sha512Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))

        _ = withUnsafeBytes { CC_SHA512($0.baseAddress, UInt32(count), &digest) }

        return digest
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    fileprivate var hash: String {
        #if canImport(CryptoKit)
            if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
                return SHA512
                    .hash(data: self)
                    .compactMap { String(format: "%02x", $0) }
                    .joined()
            }
        #endif

        return sha512Hex
    }
}
