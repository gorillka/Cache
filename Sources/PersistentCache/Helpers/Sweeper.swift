//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Cache
import Foundation

struct Sweeper {
    // MARK: - Private Properties

    /// The path for directory managed by the cache.
    let path: URL
    private let initialSweepDelay = Time.seconds(10)

    // MARK: - Public Properties

    var sweepInterval = Time.seconds(30)

    var sizeLimit: Cost
    var trimRation: Double = 0.7

    var totalCount: Int { metadata(keys: []).count }
    var totalSize: Int { metadata(keys: [.fileSizeKey]).compactMap(\.meta.fileSize).reduce(0, +) }
    var totalAllocatedSize: Int {
        metadata(keys: [.totalFileAllocatedSizeKey]).compactMap(\.meta.totalFileAllocatedSize).reduce(0, +)
    }

    // MARK: - Inits

    init(_ path: URL, sizeLimit: Cost, queue: DispatchQueue) {
        self.path = path
        self.sizeLimit = sizeLimit
        queue.asyncAfter(deadline: .now() + initialSweepDelay.seconds) { [self, unowned queue] in
            self.performAndSchedule(on: queue)
        }
    }

    // MARK: - Public Methods

    func callAsFunction(on queue: DispatchQueue) {
        queue.sync(execute: performSweep)
    }

    func performAndSchedule(on queue: DispatchQueue) {
        performSweep()
        queue.asyncAfter(deadline: .now() + sweepInterval.seconds) { [unowned queue] in
            performAndSchedule(on: queue)
        }
    }

    // MARK: - Private Methods

    private func performSweep() {
        var metadata = metadata(keys: [.contentAccessDateKey, .totalFileAllocatedSizeKey])
        if metadata.isEmpty { return }

        var size = metadata
            .compactMap(\.meta.totalFileAllocatedSize)
            .reduce(0, +)

        print(sizeLimit.rawValue)
        guard size > sizeLimit.rawValue else { return }

        let targetSizeLimit = Int(Double(sizeLimit.rawValue) * trimRation)

        let past = Date.distantPast
        metadata
            .sort { ($0.meta.contentAccessDate ?? past) > ($1.meta.contentAccessDate ?? past) }

        while size > targetSizeLimit, let item = metadata.popLast() {
            size -= item.meta.totalFileAllocatedSize ?? 0
            try? FileManager.default.removeItem(at: item.url)
        }
    }

    private func urls(keys: [URLResourceKey]) -> [URL] {
        let urls = try? FileManager
            .default.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: keys,
                options: .skipsHiddenFiles
            )
        return urls ?? []
    }

    private func metadata(keys: [URLResourceKey]) -> [Metadata] {
        urls(keys: keys)
            .compactMap {
                guard let meta = try? $0.resourceValues(forKeys: Set(keys)) else { return nil }

                return Metadata(url: $0, meta: meta)
            }
    }
}

// MARK: - Metadata

extension Sweeper {
    private struct Metadata {
        let url: URL
        let meta: URLResourceValues
    }
}

extension Time {
    var seconds: DispatchTimeInterval { .seconds(rawValue) }
}
