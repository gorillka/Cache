
import XCTest

@testable import MemoryCache

class MemoryCacheTests: XCTestCase {
    var cache: MemoryCache<String>!
    
    override func setUp() {
        super.setUp()
        
        cache = try! MemoryCache<String>()
    }
    
    // MARK: - Basic
    
    func testCacheCreation() {
        XCTAssertEqual(cache.totalCount, 0)
        XCTAssertNil(cache[Test.testNilKey])
    }
    
    func testThatBlobIsStored() {
        // When
        cache[Test.blobKey] = Test.blob
        
        // Then
        XCTAssertEqual(cache.totalCount, 1)
        XCTAssertNotNil(cache[Test.blobKey])
    }
    
    // MARK: - Subscript
    
    func testThatBlobIsStoredUsingSubscript() {
        // When
        cache[Test.blobKey] = Test.blob
        
        // Then
        XCTAssertNotNil(cache[Test.blobKey])
    }
    
    // MARK: - Count
    
    func testThatTotalCountChanges() {
        XCTAssertEqual(cache.totalCount, 0)
        
        cache[Test.blobKey] = Test.blob
        XCTAssertEqual(cache.totalCount, 1)
        
        cache[Test.otherBlobKey] = Test.otherBlob
        XCTAssertEqual(cache.totalCount, 2)
        
        cache[Test.blobKey] = nil
        XCTAssertEqual(cache.totalCount, 1)
        
        cache[Test.otherBlobKey] = nil
        XCTAssertEqual(cache.totalCount, 0)
    }
    
    func testThatCountLimitChanges() {
        // When
        cache.countLimit = 1
        
        // Then
        XCTAssertEqual(cache.countLimit, 1)
    }
    
    func testThatItemsAreRemoveImmediatelyWhenCountLimitIsReached() {
        // Given
        cache.countLimit = 1
        
        // When
        cache[Test.blobKey] = Test.blob
        cache[Test.otherBlobKey] = Test.otherBlob
        
        // Then
        XCTAssertNil(cache[Test.blobKey])
        XCTAssertNotNil(cache[Test.otherBlobKey])
    }
    
    func testTrimToCount() {
        // Given
        cache[Test.blobKey] = Test.blob
        cache[Test.otherBlobKey] = Test.blob
        
        // When
        cache.countLimit = 1
        
        // Then
        XCTAssertNil(cache[Test.blobKey])
        XCTAssertNotNil(cache[Test.otherBlobKey])
    }
    
    func testThatBlobAreRemovedOnCountLimitChange() {
        // Given
        cache.countLimit = 2
        
        cache[Test.blobKey] = Test.blob
        cache[Test.otherBlobKey] = Test.blob
        
        // When
        cache.countLimit = 1
        
        // Then
        XCTAssertNil(cache[Test.blobKey])
        XCTAssertNotNil(cache[Test.otherBlobKey])
    }
    
    // TODO: write test for coast
    
    // MARK: - Lifetime
    
    func testLifetime() {
        // Given
        cache.insert(Test.blob, for: Test.blobKey, lifetime: .seconds(1))
        XCTAssertNotNil(cache.value(for:Test.blobKey))
        
        // When
        usleep(useconds_t(1.1 * 1000000))
        
        // Then
        XCTAssertNil(cache.value(for: Test.blobKey))
    }
    
    func testDefaultToNonExpiringEntries() {
        // Given
        cache.insert(Test.blob, for: Test.blobKey, lifetime: .seconds(2))
        XCTAssertNotNil(cache.value(for: Test.blobKey))
        
        // When
        usleep(useconds_t(1.9 * 1000000))
        
        // Then
        XCTAssertNotNil(cache.value(for: Test.blobKey))
    }
}
