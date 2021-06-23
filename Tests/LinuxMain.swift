import XCTest

#if os(Linux) || os(FreeBSD)
@testable import CacheKitTests

var tests = [XCTestCaseEntry]()
tests += MemoryCacheTests.allTests()
tests += PersistentCacheTests.allTests()
XCTMain(tests)
#endif
