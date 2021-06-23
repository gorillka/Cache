//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import func CommonCrypto.CC_SHA1
import var CommonCrypto.CC_SHA1_DIGEST_LENGTH
import Foundation

public extension Key {
    /// Calculates SHA1 from the given string and returns its hex representation.
    var SHA1: String {
        if rawValue.isEmpty {
            fatalError("\(Self.self) shouldn't be empty!")
        }

        guard let data = rawValue.data(using: .utf8) else {
            fatalError("Couldn't get data from \(rawValue)!")
        }

        return data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            CC_SHA1(bytes.baseAddress, UInt32(data.count), &digest)
            return digest
        }
        .map { String(format: "%02x", $0) }
        .joined()
    }
}
