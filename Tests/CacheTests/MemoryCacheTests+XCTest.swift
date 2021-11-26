
import XCTest

extension MemoryCacheTests {
    static var allTests: [(String, (MemoryCacheTests) -> () throws -> Void)] {
        [
            ("testCacheCreation", testCacheCreation),
            ("testToDifferentKeys", testToDifferentKeys),
            ("testThatBlobIsStored", testThatBlobIsStored),
            ("testThatBlobIsStoredUsingSubscript", testThatBlobIsStoredUsingSubscript),
            ("testThatTotalCountChanges", testThatTotalCountChanges),
            ("testThatCountLimitChanges", testThatCountLimitChanges),
            (
                "testThatItemsAreRemoveImmediatelyWhenCountLimitIsReached",
                testThatItemsAreRemoveImmediatelyWhenCountLimitIsReached
            ),
            ("testTrimToCount", testTrimToCount),
            ("testThatBlobAreRemovedOnCountLimitChange", testThatBlobAreRemovedOnCountLimitChange),
            ("testLifetime", testLifetime),
            ("testDefaultToNonExpiringEntries", testDefaultToNonExpiringEntries),
        ]
    }
}
