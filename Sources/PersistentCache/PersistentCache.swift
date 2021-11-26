//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Cache
import Foundation
import MemoryCache

public final class PersistentCache<Value: Codable> {
    private typealias StagingType = Staging<Value>

    // MARK: - Private Properties

    private let lock = NSLock()
    private var staging: StagingType
    private var sweeper: Sweeper

    private var isSaveNeeded = false
    private var isPersistScheduled = false

    // MARK: - Public Properties

    public private(set) var name: String
    /// The number of seconds between each LRU sweep. 30 by default.
    /// The first sweep is performed right after the cache is initialized.
    ///
    /// Sweeps are performed in a background and can be performed in parallel with reading.
    public var saveInterval: Time = .seconds(1)

    /// A queue which is used for disk I/O.
    public let queue = DispatchQueue(label: "com.github.gorillka.PersistentCache.WriteQueue", qos: .utility)

    // MARK: - Inits

    /// Creates a cache instance with a given path.
    ///
    /// A filename generates using SHA1 hash function.
    public init(path: URL, costLimit: Cost = .Mbyte(150)) throws {
        let memoryCache = try MemoryCache<Value>()
        self.staging = Staging(memoryCache)
        self.sweeper = Sweeper(path, sizeLimit: costLimit, queue: queue)
        self.name = path.lastPathComponent

        try createDirectory(at: path)
    }

    /// Creates a cache instance with a given `name`. The cache creates a directory
    /// with the given `name` in a `.cachesDirectory` in `.userDomainMask`.
    ///
    /// A filename generates using SHA1 hash function.
    public convenience init(
        name: Key?,
        dateProvider: @escaping () -> Date,
        countLimit: Int,
        costLimit: Cost = .Mbyte(150)
    ) throws {
        let urls = FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)

        guard let cacheDirectory = urls.first else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }

        let name = name?.rawValue
            ?? Bundle.main.bundleIdentifier
            ?? "PersistentCache"
        let path = cacheDirectory.appendingPathComponent(name)

        try self.init(path: path, costLimit: costLimit)
    }
}

// MARK: - PersistentCaching

extension PersistentCache: PersistentCaching {
    /// The path for the directory managed by the cache.
    public var path: URL { sweeper.path }

    /// When performing a sweep, the cache will remote entries until the size of
    /// the remaining items is lower than or equal to `totalCost * trimRatio` and
    /// the total count is lower than or equal to `countLimit * trimRatio`.
    /// `0.7` by default.
    public var trimRatio: Double {
        get { sweeper.trimRation }
        set { sweeper.trimRation = newValue }
    }

    /// The number of seconds between each LRU sweep. 30 by default.
    /// The first sweep is performed right after the cache is initialized.
    ///
    /// Sweeps are performed in a background and can be performed in parallel with reading.
    public var sweepInterval: Time {
        get { sweeper.sweepInterval }
        set { sweeper.sweepInterval = newValue }
    }

    /// Size limit in bytes. `150 Mb` by default.
    ///
    /// Changes to `costLimit` will take effect when the next LRU sweep is run.
    public var costLimit: Cost {
        get { sweeper.sizeLimit }
        set { sweeper.sizeLimit = newValue }
    }

    /// The total file size of items written on disk.
    ///
    /// Uses `URLResourceKey.fileSizeKey` to calculate the size of each entry.
    /// The total allocated size (see `totalAllocatedSize`. on disk might
    /// actually be bigger.
    ///
    /// - warning: Requires disk IO, avoid using from the main thread.
    public var totalCost: Cost { .byte(sweeper.totalSize) }

    /// The total file allocated size of all the items written on disk.
    ///
    /// Uses `URLResourceKey.totalFileAllocatedSizeKey`.
    ///
    /// - warning: Requires disk IO, avoid using from the main thread.
    public var totalAllocatedSize: Cost { .byte(sweeper.totalAllocatedSize) }

    /// The total number of items in the cache.
    /// - warning: Requires disk IO, avoid using from the main thread.
    public var totalCount: Int { sweeper.totalCount }

    public func persist() { queue.sync(execute: saveChangesIfNeeded) }

    public func persistValue(for key: Key) {
        queue.sync {
            lock.lock()
            let change = staging.changes[key]
            lock.unlock()

            guard let change = change else { return }

            perform(change)
            lock.lock()
            staging.clean(change)
            lock.unlock()
        }
    }

    /// Returns `true` if the cache contains the value for the given key.
    public func contains(at key: Key) -> Bool {
        if change(for: key) != nil {
            return staging.value(for: key) != nil
        }

        return FileManager
            .default
            .fileExists(atPath: url(for: key).path)
    }

    /// Retrieves value for the given key.
    public func value(for key: Key) -> Value? {
        if let change = change(for: key) {
            switch change {
            case .add:
                return staging.value(for: key)

            default:
                return nil
            }
        }

        return try? Data(contentsOf: url(for: key)).decoded()
    }

    /// Stores value for the given key. The method returns instantly and the data is written asynchronously.
    public func insert(_ value: Value, for key: Key, lifetime: Time) {
        performStage { staging.insert(value, for: key, lifetime: lifetime) }
    }

    /// Removes value for the given key. The method returns instantly, the data is removed asynchronously.
    public func removeValue(at key: Key) {
        performStage { staging.removeValue(for: key) }
    }

    /// Removes all items. The method returns instantly, the data is removed asynchronously.
    public func removeAll() {
        performStage { staging.removeAll() }
    }

    /// Synchronously performs a cache sweep and removes the least recently items
    /// which no longer fit in cache.
    public func sweep() {
        sweeper()
    }
}

// MARK: - Private Methods

extension PersistentCache {
    private func createDirectory(at path: URL) throws {
        try FileManager
            .default
            .createDirectory(
                at: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
    }

    private func change(for key: Key) -> StagingType.ChangeType? {
        lock.lock()
        defer { lock.unlock() }

        return staging.changeType(for: key)
    }

    private final func performStage(_ stage: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        stage()
        setNeedsSaveChanges()
    }

    private func setNeedsSaveChanges() {
        if isSaveNeeded { return }
        isSaveNeeded = true

        scheduleNextPersist()
    }

    private func scheduleNextPersist() {
        if isPersistScheduled { return }
        isPersistScheduled = true
        queue.asyncAfter(deadline: .now() + saveInterval.seconds, execute: saveChangesIfNeeded)
    }

    private func saveChangesIfNeeded() {
        let staging: StagingType
        lock.lock()

        guard isSaveNeeded else { return lock.unlock() }

        staging = self.staging
        isSaveNeeded = false
        lock.unlock()

        performChanges(for: staging)

        lock.lock()
        self.staging.clean(staging)
        isPersistScheduled = false

        if isSaveNeeded { scheduleNextPersist() }

        lock.unlock()
    }

    // MARK: - I/O

    private func performChanges(for staging: StagingType) {
        autoreleasepool {
            staging
                .changes
                .values
                .forEach(perform)
        }
    }

    /// Performs the IO for the given change.
    private func perform(_ change: StagingType.Change) {
        switch change.type {
        case .add:
            guard let value = staging.value(for: change.key) else { return }
            guard let data = value.encoded() else { return }
            do {
                try data.write(to: url(for: change.key))
            } catch let error as NSError {
                if error.code != CocoaError.fileNoSuchFile.rawValue, error.domain != CocoaError.errorDomain { return }

                try? FileManager.default
                    .createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
                try? data.write(to: url(for: change.key))
            }

        case .remove:
            try? FileManager.default
                .removeItem(at: url(for: change.key))

        case .removeAll:
            try? FileManager.default
                .removeItem(at: path)
            try? FileManager.default
                .createDirectory(
                    at: path,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
        }
    }

    // MARK: - Sweep

    private final func url(for key: Key) -> URL {
        path.appendingPathComponent(key.SHA1, isDirectory: false)
    }
}

private extension Data {
    func decoded<Value: Decodable>() -> Value? {
        try? JSONDecoder().decode(Value.self, from: self)
    }
}

private extension Encodable {
    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }
}
