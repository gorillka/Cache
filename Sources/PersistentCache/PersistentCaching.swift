//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Cache
import Foundation

public protocol PersistentCaching: Caching {
    /// The path for the directory managed by the cache.
    var path: URL { get }
    /// When performing a sweep, the cache will remote entries until the size of
    /// the remaining items is lower than or equal to `totalCost * trimRatio` and
    /// the total count is lower than or equal to `countLimit * trimRatio`.
    /// `0.7` by default.
    var trimRatio: Double { get set }
    /// The number of seconds between each LRU sweep. 30 by default.
    /// The first sweep is performed right after the cache is initialized.
    ///
    /// Sweeps are performed in a background and can be performed in parallel with reading.
    var sweepInterval: Time { get set }

    /// The total file allocated size of all the items written on disk.
    ///
    /// Uses `URLResourceKey.totalFileAllocatedSizeKey`.
    ///
    /// - warning: Requires disk IO, avoid using from the main thread.
    var totalAllocatedSize: Cost { get }

    /// A queue which is used for disk I/O.
    var queue: DispatchQueue { get }

    /// Synchronously performs a cache sweep and removes the least recently items which no longer fit in cache.
    func sweep()

    /// Synchronously waits on the caller's thread until all outstanding disk I/O operations are finished.
    func persist()
    /// Synchronously waits on the caller's thread until all outstanding disk I/O
    /// operations for the given key are finished.
    func persistValue(for key: Key)
}

public extension PersistentCaching {
    var countLimit: Int {
        get { .max }
        set {}
    }

    init(
        name: Key? = nil,
        dateProvider: @escaping () -> Date = Date.init,
        costLimit: Cost = .Mbyte(100)
    ) throws {
        try self.init(name: name, dateProvider: dateProvider, countLimit: 0, costLimit: costLimit)
    }
}
