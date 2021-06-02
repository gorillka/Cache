
import Foundation

public class Cache<Object: Codable> {
    private let wrapped: NSCache<Key, Value> = .init()
    private let keyTracker = KeyTracker()

    private var dateProvider: () -> Date
    private let valueLifetime: TimeInterval
    private var persistent: Bool

    private lazy var middlewares: [Middleware] = []
    private var removingValues: Set<Key> = []

    private lazy var persistentStore = PersistentStore(directoryName: wrapped.name)

    private var expirationDate: Date { dateProvider().addingTimeInterval(valueLifetime) }

    public init(
        name: String,
        dateProvider: @escaping () -> Date = Date.init,
        valueLifetime: TimeInterval = 12 * 60 * 60,
        maximumValueCount: Int = .max,
        persistent: Bool = true
    ) {
        self.dateProvider = dateProvider
        self.valueLifetime = valueLifetime
        self.persistent = persistent

        wrapped.name = name
        wrapped.countLimit = maximumValueCount
        wrapped.delegate = keyTracker
    }
}

// MARK: - Middleware

public extension Cache {
    @discardableResult
    final func use(_ middleware: Middleware) -> Cache {
        persistent = true

        middlewares.append(middleware)

        return self
    }
}

// MARK: - API

public extension Cache {
    private func insert(_ value: Value, force: Bool = true) throws {
        wrapped.setObject(value, forKey: value.key)
        keyTracker.keys.insert(value.key)

        guard persistent, force else { return }

        let data = try value
            .encode()
            .encode(middlewares)
        try persistentStore.store(data, for: value.key)
    }

    @discardableResult
    final func insert(_ value: Object, for key: Key) throws -> Object {
        let wrappedValue = Value(key: key, value: value, expirationDate: expirationDate)
        try insert(wrappedValue)

        return wrappedValue.value
    }

    final func value(for key: Key) throws -> Object? {
        let checkExpirationDate: (Value) throws -> Object? = { [unowned self] in
            if self.dateProvider() > $0.expirationDate {
                if self.removingValues.contains($0.key) {
                    return $0.value
                } else {
                    try self.removeValue(for: key)
                    
                    return nil
                }
            } else {
                return $0.value
            }
        }
        
        if let value = wrapped.object(forKey: key) {
            return try checkExpirationDate(value)
        }
        
        guard persistent else { return nil }
        
        let data = try persistentStore.retrieveValue(for: key)
        let value: Value
        
        do {
            value = try data.decode(middlewares).decode()
        } catch {
            try? persistentStore.removeValue(at: key)
            
            throw error
        }
        
        try insert(value)
        
        return try checkExpirationDate(value)
    }

    final func removeValue(for key: Key) throws {
        removingValues.insert(key)
        defer { removingValues.remove(key) }

        wrapped.removeObject(forKey: key)

        if persistent {
            try persistentStore.removeValue(at: key)
        }
    }

    final func clear(permanent: Bool = true) {
        defer { wrapped.removeAllObjects() }

        guard permanent else { return }

        try? keyTracker
            .keys
            .forEach(persistentStore.removeValue)
        
        try? persistentStore.removeAll()
    }
}

// MARK: - Subscripting

public extension Cache {
    final subscript(key: Key) -> Object? {
        get {
            try? value(for: key)
        }
        set {
            guard let value = newValue else {
                _ = try? removeValue(for: key)
                return
            }

            _ = try? insert(value, for: key)
        }
    }
}

// MARK: - Key

public extension Cache {
    final class Key: Hashable, RawRepresentable {
        public let rawValue: String

        public convenience init(_ value: String) {
            self.init(rawValue: value)
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension Cache.Key: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension Cache.Key: CustomStringConvertible {
    public var description: String { rawValue }
}

extension Cache.Key: Codable {}


// MARK: - WrappedValue

private extension Cache {
    typealias Value = WrappedValue<Object>

    final class WrappedValue<Value: Codable> {
        let key: Key
        let value: Value
        let expirationDate: Date

        init(key: Key, value: Value, expirationDate: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

extension Cache.WrappedValue: Codable {}

// MARK: - Persistent Store

private extension Cache {
    final class PersistentStore<Object: Value> {
        private let directoryName: String
        
        private var fileManager: FileManager { .default }
        private var cachesDirectory: URL {
            let cachePath = fileManager
                .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let dataPath = cachePath.appendingPathComponent("\(directoryName.hash.suffix(16))")
            if !fileManager.fileExists(atPath: dataPath.path) {
                do {
                    try fileManager.createDirectory(at: dataPath, withIntermediateDirectories: true, attributes: [:])
                    
                    return dataPath
                } catch {
                    print(error)
                    return cachePath
                }
            }
            
            return dataPath
        }
        
        init(directoryName: String) {
            self.directoryName = directoryName
        }

        private func fileName(for key: Key) -> String {
            "\(key.hash.suffix(16)).cache"
        }

        private func fileURL(for key: Key) -> URL {
            cachesDirectory
                .appendingPathComponent(fileName(for: key))
        }

        fileprivate func store(_ value: Data?, for key: Key) throws {
            let fileURL = fileURL(for: key)

            guard let value = value else {
                return try removeValue(at: key)
            }

            try value
                .write(to: fileURL)
        }

        fileprivate func retrieveValue(for key: Key) throws -> Data {
            try fileURL(for: key)
                .getData()
        }

        fileprivate func removeValue(at key: Key) throws {
            try fileManager
                .removeItem(at: fileURL(for: key))
        }
        
        fileprivate func removeAll() throws {
            let cachesDirectory = cachesDirectory
            
            if fileManager.fileExists(atPath: cachesDirectory.path) {
                try fileManager.removeItem(at: cachesDirectory)
            }
        }
    }
}

// MARK: - KeyTracker

private extension Cache {
    final class KeyTracker: NSObject, NSCacheDelegate {
        var keys: Set<Key> = []

        final func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject object: Any) {
            guard let value = object as? Value else { return }

            keys.remove(value.key)
        }
    }
}

// MARK: - Helpers

private extension URL {
    func getData() throws -> Data {
        try .init(contentsOf: self)
    }
}

private extension Data {
    func encode(_ middlewares: [Middleware]) throws -> Data {
        try middlewares.reduce(self) { value, middlware in try middlware.encode(value) }
    }

    func decode(_ middlewares: [Middleware]) throws -> Data {
        try middlewares.reduce(self) { value, middleware in try middleware.decode(value) }
    }
}

private extension Encodable {
    func encode(_ encoder: JSONEncoder = JSONEncoder()) throws -> Data { try encoder.encode(self) }
}

private extension Data {
    func decode<Value: Decodable>(_ decoder: JSONDecoder = JSONDecoder()) throws -> Value {
        try decoder.decode(Value.self, from: self)
    }
}
