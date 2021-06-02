
import Foundation

public protocol Middleware {
    func encode(_ value: Data) throws -> Data
    func decode(_ value: Data) throws -> Data
}

public extension Middleware {
    func encode(_ value: Data) throws -> Data { value }
    func decode(_ value: Data) throws -> Data { value }
}
