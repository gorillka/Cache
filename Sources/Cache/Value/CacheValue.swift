//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Foundation

public protocol CacheValue {
    associatedtype Value

    var key: Key { get }
    var value: Value { get }
    var expiration: Date { get }
}

public final class CachedValue<T>: CacheValue {
    public let key: Key
    public let value: T
    public let expiration: Date

    public init(key: Key, value: T, expiration: Date) {
        self.key = key
        self.value = value
        self.expiration = expiration
    }
}
