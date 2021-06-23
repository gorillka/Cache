//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Cache
import Foundation

/// In-memory cache.
public class MemoryCache<Value> {
    // MARK: - Public Properties

    typealias WrappedValue = CachedValue<Value>

    /// The total cost of items in the cache.
    public private(set) var totalCost: Cost = 0

    /// The maximum total cost that the cache can hold.
    public var costLimit: Cost {
        get { .byte(wrapped.totalCostLimit) }
        set { wrapped.totalCostLimit = newValue.rawValue }
    }

    /// The maximum number of items that the cache can hold.
    public var countLimit: Int {
        get { wrapped.countLimit }
        set { wrapped.countLimit = newValue }
    }

    private let keyTracker = KeyTracker()
    private let wrapped = NSCache<Key, WrappedValue>()

    private let dateProvider: () -> Date

    public required init(
        name: Key?,
        dateProvider: @escaping () -> Date,
        countLimit: Int,
        costLimit: Cost
    ) throws {
        self.dateProvider = dateProvider

        self.countLimit = countLimit
        self.costLimit = costLimit
        wrapped.name = name?.rawValue
            ?? Bundle.main.bundleIdentifier
            ?? "MemoryCache"
    }
}

// MARK: - Caching

extension MemoryCache: Caching {
    public var name: String { wrapped.name }

    /// The total number of items in the cache.
    public var totalCount: Int { keyTracker.keys.count }

    /// Stores value for the given key.
    public func insert(_ value: Value, for key: Key, lifetime: Time) {
        let expiration = dateProvider().addingTimeInterval(TimeInterval(lifetime.rawValue))
        let value = WrappedValue(key: key, value: value, expiration: expiration)

        wrapped.setObject(value, forKey: key)
        keyTracker.keys.insert(key)
        totalCost = totalCost + value.size
    }

    /// Removes value for the given key.
    public func removeValue(at key: Key) {
        if let value = wrapped.object(forKey: key) {
            totalCost = totalCost - value.size
        }
        wrapped.removeObject(forKey: key)
        keyTracker.keys.remove(key)
    }

    /// Retrieves value from cache for the given key.
    public func value(for key: Key) -> Value? {
        guard let value = wrapped.object(forKey: key) else { return nil }

        if dateProvider() > value.expiration {
            removeValue(at: key)
            return nil
        }

        return value.value
    }

    /// Removes all caches items.
    public func removeAll() {
        wrapped.removeAllObjects()
    }
}

// MARK: - KeyTracker

extension MemoryCache {
    private final class KeyTracker: NSObject, NSCacheDelegate {
        var keys = Set<Key>()

        func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
            guard let value = obj as? WrappedValue else { return }

            keys.remove(value.key)
        }
    }
}
