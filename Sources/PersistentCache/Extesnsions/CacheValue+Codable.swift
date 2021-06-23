//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Cache
import Foundation

extension CachedValue: Codable where Value: Codable {
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let key = try container.decode(Key.self)
        let value = try container.decode(Value.self)
        let expiration = try container.decode(Date.self)

        self.init(key: key, value: value, expiration: expiration)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(key)
        try container.encode(value)
        try container.encode(expiration)
    }
}
