
import XCTest
import Cache

@testable import PersistentCache

class PersistentCacheTests: XCTestCase {
    var cache: PersistentCache<String>!
    
    override func setUp() {
        super.setUp()
        
        cache = try! PersistentCache<String>(name: Key(UUID().uuidString))
    }
    
    override func tearDown() {
        super.tearDown()
        
        try? FileManager.default.removeItem(at: cache.path)
    }
    
    // MARK: - Init
    
    func testInitWithName() {
        // Given
        let name = Key(UUID().uuidString)
        
        // When
        let cache = try! PersistentCache<String>(name: name)
        
        // Then
        XCTAssertEqual(cache.path.lastPathComponent, name.rawValue)
        XCTAssertNotNil(FileManager.default.fileExists(atPath: cache.path.absoluteString))
    }
    
    // MARK: - Add
    
    func testAdd() {
        cache.withSuspendedIO {
            // When
            cache[Test.blobKey] = Test.blob
            
            // Then
            XCTAssertEqual(cache[Test.blobKey], Test.blob)
        }
    }
    
    func testWhenAddContentNotPersistedImmediately() {
        cache.withSuspendedIO {
            // When
            cache[Test.blobKey] = Test.blob
            
            // Then
            XCTAssertEqual(cache.contents.count, 0)
        }
    }
    
    func testAddAndPersist() {
        // Given
        cache.withSuspendedIO {
            cache[Test.blobKey] = Test.blob
        }
        
        // When
        cache.persist()
        
        // Then
        XCTAssertEqual(cache.contents.count, 1)
        XCTAssertEqual(cache[Test.blobKey], Test.blob)
        
        XCTAssertNotNil(try? Data(contentsOf: cache.contents.first!))
        
        let data = try! Data(contentsOf: cache.contents.first!)
        XCTAssertNotNil(try? JSONDecoder().decode(type(of: cache).ValueType.self, from: data))
        let cachedBlob = try! JSONDecoder().decode(type(of: cache).ValueType.self, from: data)
        XCTAssertEqual(cachedBlob, Test.blob)
    }
    
    func testReplace() {
        cache.withSuspendedIO {
            // Given
            cache[Test.blobKey] = Test.blob
            
            // When
            cache[Test.blobKey] = Test.otherBlob
            
            // Then
            XCTAssertEqual(cache[Test.blobKey], Test.otherBlob)
        }
    }
    
    func testReplacePersisted() {
        // Given
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        cache.withSuspendedIO {
            cache[Test.blobKey] = Test.otherBlob
            XCTAssertEqual(cache.contents.count, 1)
            // Test that before persist we still have the old blob on disk,
            // but new blob in staging
            XCTAssertNotNil(try? Data(contentsOf: cache.contents.first!))
            let data = try! Data(contentsOf: cache.contents.first!)
            XCTAssertNotNil(try? JSONDecoder().decode(type(of: cache).ValueType.self, from: data))
            let oldBlob = try! JSONDecoder().decode(type(of: cache).ValueType.self, from: data)
            XCTAssertEqual(oldBlob, Test.blob)
            XCTAssertEqual(cache[Test.blobKey], Test.otherBlob)
        }
        
        // Persist and test that data on disk was updated.
        cache.persist()
        XCTAssertEqual(cache.contents.count, 1)
        XCTAssertNotNil(try? Data(contentsOf: cache.contents.first!))
        let data = try! Data(contentsOf: cache.contents.first!)
        XCTAssertNotNil(try? JSONDecoder().decode(type(of: cache).ValueType.self, from: data))
        let otherBlob = try! JSONDecoder().decode(type(of: cache).ValueType.self, from: data)
        XCTAssertEqual(otherBlob, Test.otherBlob)
        XCTAssertEqual(cache[Test.blobKey], otherBlob)
    }
    
    // MARK: - Removal
    
    func testRemoveNonExistent() {
        cache[Test.blobKey] = nil
        cache.persist()
    }
    
    func testRemoveFromStage() {
        cache.withSuspendedIO {
            cache[Test.blobKey] = Test.blob
            cache[Test.blobKey] = nil
            XCTAssertNil(cache[Test.blobKey])
        }
        
        cache.persist()
        XCTAssertNil(cache[Test.blobKey])
    }
    
    func testRemoveReplacePersist() {
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        cache.withSuspendedIO {
            cache[Test.blobKey] = Test.otherBlob
            cache[Test.blobKey] = nil
            XCTAssertNil(cache[Test.blobKey])
            
            XCTAssertNotNil(try? Data(contentsOf: cache.contents.first!))
            let data = try! Data(contentsOf: cache.contents.first!)
            XCTAssertNotNil(try? JSONDecoder().decode(type(of: cache).ValueType.self, from: data))
            let blob = try! JSONDecoder().decode(type(of: cache).ValueType.self, from: data)
            XCTAssertEqual(blob, Test.blob)
        }
        
        cache.persist()
        XCTAssertEqual(cache.contents.count, 0)
    }
    
    func testRemovePersisted() {
        // Given
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        cache.withSuspendedIO {
            cache[Test.blobKey] = nil
            XCTAssertNil(cache[Test.blobKey])
            XCTAssertEqual(cache.contents.count, 1)
            XCTAssertNotNil(try? Data(contentsOf: cache.contents.first!))
            let data = try! Data(contentsOf: cache.contents.first!)
            XCTAssertNotNil(try? JSONDecoder().decode(type(of: cache).ValueType.self, from: data))
            let blob = try! JSONDecoder().decode(type(of: cache).ValueType.self, from: data)
            XCTAssertEqual(blob, Test.blob)
        }
        
        cache.persist()
        
        XCTAssertNil(cache[Test.blobKey])
        XCTAssertEqual(cache.contents.count, 0)
    }
    
    func testRemoveWhenRemovalAlreadyScheduled() {
        // Given
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        // When
        cache[Test.blobKey] = nil
        cache[Test.blobKey] = nil
        cache.persist()
        
        // Then
        XCTAssertEqual(cache.contents.count, 0)
    }
    
    func testRemoveAndThenReplace() {
        // Given
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        // When
        cache[Test.blobKey] = nil
        cache[Test.blobKey] = Test.otherBlob
        cache.persist()
        
        // Then
        XCTAssertEqual(cache[Test.blobKey], Test.otherBlob)
        XCTAssertEqual(cache.contents.count, 1)
        XCTAssertNotNil(try? Data(contentsOf: cache.contents.first!))
        
        let data = try! Data(contentsOf: cache.contents.first!)
        XCTAssertNotNil(try? JSONDecoder().decode(type(of: cache).ValueType.self, from: data))
        let blob = try! JSONDecoder().decode(type(of: cache).ValueType.self, from: data)
        XCTAssertEqual(blob, Test.otherBlob)
    }
    
    // MARK: - Remove All
    
    func testRemoveAll() {
        cache.withSuspendedIO {
            // Given
            cache[Test.blobKey] = Test.blob
            cache[Test.otherBlobKey] = Test.otherBlob
            
            // When
            cache.removeAll()
            
            // Then
            XCTAssertNil(cache[Test.blobKey])
            XCTAssertNil(cache[Test.otherBlobKey])
        }
    }
    
    func testRemoveAllPersisted() {
        // Given
        cache[Test.blobKey] = Test.blob
        cache[Test.otherBlobKey] = Test.otherBlob
        cache.persist()
        
        // When
        cache.withSuspendedIO {
            cache.removeAll()
            
            // Then
            XCTAssertNil(cache[Test.blobKey])
            XCTAssertNil(cache[Test.otherBlobKey])
        }
    }
    
    func testRemoveAllPersistedAndPersist() {
        // Given
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        // When
        cache.removeAll()
        cache.persist()
        
        // Then
        XCTAssertNil(cache[Test.blobKey])
        XCTAssertEqual(cache.contents.count, 0)
    }
    
    func testRemoveAllAndAdd() {
        // Given
        cache.withSuspendedIO {
            cache[Test.blobKey] = Test.blob
            
            // When
            cache.removeAll()
            cache[Test.blobKey] = Test.blob
            
            // Then
            XCTAssertEqual(cache[Test.blobKey], Test.blob)
        }
    }
    
    func testRemoveAllTwice() {
        // Given
        cache.withSuspendedIO {
            cache[Test.blobKey] = Test.blob
            
            // When
            cache.removeAll()
            cache[Test.blobKey] = Test.blob
            cache.removeAll()
            
            // Then
            XCTAssertNil(cache[Test.blobKey])
        }
    }
    
    // MARK: - Persist
    
    func testPersist() {
        // Given
        cache.saveInterval = 20
        cache[Test.blobKey] = Test.blob
        
        // When
        cache.persist()
        
        // Then
        let path = cache.path.appendingPathComponent(Test.blobKey.SHA1)
        XCTAssertEqual(cache.contents, [path])
    }
    
    func testPersistForKey() {
        // Given
        cache.saveInterval = 20
        cache[Test.blobKey] = Test.blob
        
        // When
        cache.persistValue(for: Test.blobKey)
        
        // Then
        let path = cache.path.appendingPathComponent(Test.blobKey.SHA1)
        XCTAssertEqual(cache.contents, [path])
    }
    
    func testPersistForKey2() {
        // Given
        cache.saveInterval = 20
        cache[Test.blobKey] = Test.blob
        cache[Test.otherBlobKey] = Test.blob
        
        // When
        cache.persistValue(for: Test.blobKey)
        
        // Then only persists content for the specific key
        let path = cache.path.appendingPathComponent(Test.blobKey.SHA1)
        XCTAssertEqual(cache.contents, [path])
    }
    
    // MARK: - Clear
    
    func testClear() {
        // Given
        let cost: Cost = .Mbyte(1)
        cache.costLimit = .Mbyte(4)
        cache[Test.blobKey] = Data(repeating: 1, count: cost.rawValue).base64EncodedString()
        cache[Test.otherBlobKey] = Data(repeating: 1, count: cost.rawValue).base64EncodedString()
        cache[Test.bigBlobKey] = Data(repeating: 1, count: cost.rawValue).base64EncodedString()
        
        cache.persist()
        
        // When
        cache.sweep()
        
        // Then
        XCTAssertEqual(cache.contents.count, 2)
    }
    
    // MARK: - Inspection
    
    func testTotalCount() {
        XCTAssertEqual(cache.totalCount, 0)
        
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        XCTAssertEqual(cache.totalCount, 1)
    }
    
    func testTotalSize() {
        XCTAssertEqual(cache.totalCost.rawValue, 0)
        
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        XCTAssertTrue(cache.totalCost.rawValue > 0)
    }
    
    // MARK: - Resilience
    
    func testWhenDirectoryDeletedCacheAutomaticallyRecreatesIt() {
        cache[Test.blobKey] = Test.blob
        cache.persist()
        
        do {
            try FileManager.default.removeItem(at: cache.path)
        } catch {
            XCTFail("Fail to remove cache directory")
        }
        
        cache[Test.blobKey] = Test.blob
        cache.persist()
        print(cache.contents.first!)
        do {
            let url = cache.path.appendingPathComponent(Test.blobKey.SHA1)
            let data = try Data(contentsOf: url)
            let blob = try JSONDecoder().decode(type(of: cache).ValueType.self, from: data)
            XCTAssertEqual(blob, Test.blob)
        } catch {
            XCTFail("Failed to read data")
        }
    }
}

extension PersistentCache {
    var contents: [URL] {
        try! FileManager.default
            .contentsOfDirectory(
                at: self.path,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
    }
    func withSuspendedIO(_ closure: () -> Void) {
        queue.suspend()
        closure()
        queue.resume()
    }
}
