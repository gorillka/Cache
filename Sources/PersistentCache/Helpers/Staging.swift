//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Cache
import Foundation
import MemoryCache

struct Staging<Value: Codable> {
    // MARK: - Private Properties

    private let cache: MemoryCache<Value>

    private let removeAllKey = Key(UUID().uuidString)
    private(set) var changes = [Key: Change]()

    init(_ cache: MemoryCache<Value>) {
        self.cache = cache
    }
}

// MARK: - Staging

extension Staging {
    func changeType(for key: Key) -> ChangeType? {
        changes[key]?.type ?? changes[removeAllKey]?.type
    }

    func value(for key: Key) -> Value? {
        cache.value(for: key)
    }

    mutating func insert(_ value: Value, for key: Key, lifetime: Time) {
        cache.insert(value, for: key, lifetime: lifetime)
        changes[key] = Change(key: key, type: .add)
    }

    mutating func removeValue(for key: Key) {
        cache.removeValue(at: key)
        changes[key] = Change(key: key, type: .remove)
    }

    mutating func removeAll() {
        cache.removeAll()
        changes.removeAll()
        changes[removeAllKey] = Change(key: removeAllKey, type: .removeAll)
    }
}

// MARK: - Cleaning

extension Staging {
    mutating func clean(_ staging: Staging) {
        staging
            .changes
            .values
            .forEach { clean($0) }
    }

    mutating func clean(_ change: Change) {
        guard let index = changes.index(forKey: change.key), changes[index].value.id == change.id else { return }

        changes.remove(at: index)
    }
}

// MARK: - Change

extension Staging {
    struct Change {
        fileprivate let id = UUID()
        let key: Key
        let type: ChangeType
    }
}

// MARK: - ChangeType

extension Staging {
    enum ChangeType {
        case add, remove, removeAll
    }
}
