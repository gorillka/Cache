# Cache

`Cache` provides composite in-memory `MemoryCache` and on-disk `PersistentCache` cache with LRU cleanup.

# Usage
## MemoryCache
### Store, retrieve and remove object
```swift
let cache = MemoryCache<String>()
let key  = "loremKey"
let value = """
    The standard Lorem Ipsum passage, used since the 1500s

        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

        Section 1.10.32 of "de Finibus Bonorum et Malorum", written by Cicero in 45 BC
    """

// Store string
cache.insert(value, for: key)
// Retrive string
let retrivedValue = cache.value(for: key)
// Remove value
cache.removeValue(for: key)
```

### Cost and count limit
`MemoryCache` discard a last recently cached value if either *cost* or *count* limit is reached.
```swift
// Configure cache
let cache = MemoryCache<String>(countLimit: 10, costLimit: .Mbyte(10))
```


## Installation

You can use the [Swift Package Manager](https://github.com/apple/swift-package-manager) by declaring **Cache** as a dependency in your `Package.swift` file:

```swift
.package(url: "https://github.com/gorillka/Cache", from: "1.0.3")
```

*For more information, see [the Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).*
