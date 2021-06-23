//
// Copyright © 2021. Orynko Artem
//
// MIT license, see LICENSE file for details
//

import Cache
import Foundation

extension CacheValue where Self: AnyObject {
    var size: Cost { .byte(malloc_size(Unmanaged.passRetained(self).toOpaque())) }
}
