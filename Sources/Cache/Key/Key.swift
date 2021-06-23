//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

/// A cache key.
public final class Key: RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ value: String) {
        self.rawValue = value
    }
}

extension Key: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Key: CustomStringConvertible {
    public var description: String { rawValue }
}

extension Key: Hashable {
    public static func == (lhs: Key, rhs: Key) -> Bool { lhs.SHA1 == rhs.SHA1 }
}

extension Key: Codable {}
