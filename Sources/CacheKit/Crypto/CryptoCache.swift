
#if canImport(CryptoKit)
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public final class CryptoCache<Object: Codable>: Cache<Object> {
        override public init(
            name: String,
            dateProvider: @escaping () -> Date = Date.init,
            valueLifetime: TimeInterval = 12 * 60 * 60,
            maximumValueCount: Int = .max,
            persistent: Bool = true
        ) {
            super.init(
                name: name,
                dateProvider: dateProvider,
                valueLifetime: valueLifetime,
                maximumValueCount: maximumValueCount,
                persistent: persistent
            )

            use(CryptoMiddleware())
        }
    }

#endif
