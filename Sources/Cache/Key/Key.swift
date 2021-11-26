//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Foundation
/// A cache key.
public final class Key: NSObject, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue

        super.init()
    }

    public init(_ value: String) {
        self.rawValue = value

        super.init()
    }

    override public var hash: Int { SHA1.hashValue }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let key = object as? Key else { return false }

        return SHA1 == key.SHA1
    }
}

extension Key: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: String) {
        self.init(value)
    }
}

public extension Key {
    override var description: String { SHA1 }
}

extension Key: Codable {}
