//
//  Uno.swift
//  Uno
//
//  Created by David Cowden on 8/24/21.
//

import Foundation
import C

/**
 *
 * An uno Id is a 32 byte entropy seed used to derive various keys for use
 * within the uno application.
 *
 */
public class Id {
    let ptr: OpaquePointer
    
    /**
     *
     * Initialize an uno Id from an array of 32 bytes of data.
     *
     */
    public init!(data: [UInt8]) {
        var ptr: OpaquePointer?
        let ret = C.uno_get_id_from_bytes(data, data.count, &ptr)
        if ret > 0 {
            return nil
        }
        self.ptr = ptr!
    }

    deinit {
        C.uno_free_id(ptr)
    }
}

public enum Err: Error {
    // An error from the underlying c library.
    // TODO: make this useful.
    case C(code: Int)
    case Invalid
}

public struct Shamir {
}

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}
