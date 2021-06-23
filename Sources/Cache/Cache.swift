//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Foundation

public protocol Caching {
    associatedtype ValueType

    /// The name of the cache.
    var name: String { get }

    /// The maximum total cost that the cache can hold.
    var costLimit: Cost { get set }
    /// The maximum number of items that the cache can hold.
    var countLimit: Int { get set }

    /// The total cost of items in the cache.
    var totalCost: Cost { get }
    /// The total number of items in the cache.
    var totalCount: Int { get }

    /// Stores value for the given key.
    func insert(_ value: ValueType, for key: Key, lifetime: Time)
    /// Removes value for the given key.
    func removeValue(at key: Key)

    /// Retrieves value from cache for the given key.
    func value(for key: Key) -> ValueType?
    /// Returns `true` if the cache contains value for the given key.
    func contains(at key: Key) -> Bool

    /// Removes all caches items.
    func removeAll()

    init(name: Key?, dateProvider: @escaping () -> Date, countLimit: Int, costLimit: Cost) throws

    subscript(key: Key) -> ValueType? { get set }
}

public extension Caching {
    init(
        name: Key? = nil,
        dateProvider: @escaping () -> Date = Date.init,
        countLimit: Int = 0,
        costLimit: Cost = 0
    ) throws {
        try self.init(name: name, dateProvider: dateProvider, countLimit: countLimit, costLimit: costLimit)
    }

    subscript(key: Key) -> ValueType? {
        get { value(for: key) }
        set { insert(newValue, for: key) }
    }

    /// Stores value for the given key.
    func insert(_ value: ValueType?, for key: Key, lifetime: Time? = nil) {
        guard let value = value else { return removeValue(at: key) }

        insert(value, for: key, lifetime: lifetime ?? .hours(12))
    }

    /// Returns `true` if the cache contains value for the given key.
    func contains(at key: Key) -> Bool { value(for: key) != nil }
}
