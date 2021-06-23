//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

public enum Cost {
    case byte(Int)
    case Kbyte(Int)
    case Mbyte(Int)
    case Gbyte(Int)

    public var byte: Double {
        switch self {
        case let .byte(value):
            return Double(value)
        case let .Kbyte(value):
            return Cost.byte(value * 1024).byte
        case let .Mbyte(value):
            return Cost.Kbyte(value * 1024).byte
        case let .Gbyte(value):
            return Cost.Mbyte(value * 1024).byte
        }
    }

    public var Kbyte: Double { byte / 1024 }
    public var Mbyte: Double { Kbyte / 1024 }
    public var Gbyte: Double { Mbyte / 1024 }
}

extension Cost: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .byte(value)
    }
}

extension Cost: RawRepresentable {
    public var rawValue: Int { Int(byte) }

    public init(rawValue: Int) {
        self.init(integerLiteral: rawValue)
    }
}

extension Cost: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .byte(value):
            return "\(value) byte"

        case let .Kbyte(value):
            return "\(value) Kbyte"

        case let .Mbyte(value):
            return "\(value) Mbyte"

        case let .Gbyte(value):
            return "\(value) Gbyte"
        }
    }
}

public extension Cost {
    static func + (lhs: Cost, rhs: Cost) -> Cost {
        .byte(lhs.rawValue + rhs.rawValue)
    }

    static func - (lhs: Cost, rhs: Cost) -> Cost {
        .byte(lhs.rawValue - rhs.rawValue)
    }
}
