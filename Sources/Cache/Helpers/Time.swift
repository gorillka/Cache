//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

@frozen
public enum Time {
    case seconds(Int)
    case minutes(Int)
    case hours(Int)
    case days(Int)

    private var seconds: Int {
        switch self {
        case let .seconds(value):
            return value
        case let .minutes(value):
            return Time.seconds(value * 60).seconds
        case let .hours(value):
            return Time.minutes(value * 60).seconds
        case let .days(value):
            return Time.hours(value * 24).seconds
        }
    }
}

extension Time: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .seconds(value)
    }
}

extension Time: RawRepresentable {
    /// Represents ``Time`` in seconds.
    public var rawValue: Int { seconds }

    public init(rawValue: Int) {
        self.init(integerLiteral: rawValue)
    }
}

extension Time: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .seconds(value):
            return "\(value) seconds"

        case let .minutes(value):
            return "\(value) minutes"

        case let .hours(value):
            return "\(value) hours"

        case let .days(value):
            return "\(value) minutes"
        }
    }
}
