//
//  Uno.swift
//
//  Swift bindings and idiomatic API on top of the uno identity rust core ffi.
//

//
// Copyright 2021 WithUno, Inc.
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import C


///
/// An uno Id is a 32 byte entropy seed used to derive various keys for use
/// within the uno application.
///
public class ID {
    let ptr: OpaquePointer

    ///
    /// Initialize an uno Id from an array of 32 bytes of data.
    ///
    public convenience init(data: [UInt8]) throws {
        var ptr: OpaquePointer?
        let ret = C.uno_get_id_from_bytes(data, data.count, &ptr)
        if ret > 0 {
            throw Err.code(ret)
        }
        self.init(ptr!)
    }
    init(_ ptr: OpaquePointer) {
        self.ptr = ptr
    }

    deinit {
        C.uno_free_id(ptr)
    }

    ///
    /// Get the bytes backing the uno Id.
    ///
    public var bytes: [UInt8] {
        get throws {
            var out = Array<UInt8>(repeating: 0, count: 32)
            let ret = C.uno_copy_id_bytes(ptr, &out, out.count)
            if ret > 0 {
                throw Err.code(ret)
            }
            return out
        }
    }

    @available(swift, deprecated: 5.5, message: "use the property instead")
    public func getBytes() throws -> [UInt8] {
        var out = Array<UInt8>(repeating: 0, count: 32)
        let ret = C.uno_copy_id_bytes(ptr, &out, out.count)
        if ret > 0 {
            throw Err.code(ret)
        }
        return out
    }
}

public enum Err: Error {
    // An error from the underlying C ffi library.
    case code(Int32)
    case invalid

    public var details: String {
        get {
            switch self {
            case .code(let c):
                let ptr = C.uno_get_msg_from_err(c)!
                return String(cString: ptr)
            case .invalid:
                return "uno-swift: invalid value"
            }
        }
    }
}

///
/// Uno's implementation of the slip-0039 protocol for sharding a secret and
/// later reconstituting it provided a quorum of the groups and constituent
/// member shares can be assembled together. We use this to back our Trusted
/// Confidants feature.
///
///
public struct S39 {
    // Input for split. See withuno/identity/s39::split.
    public typealias Spec = C.UnoGroupSpec

    ///
    /// A Group is a high level collection of shares. The slip-0039 protocol is
    /// multi-level. A secret is split into a top level set of groups, and each
    /// group is then further split into shares.
    ///
    public class Group {
        public typealias Metadata = C.UnoGroupSplit

        public let metadata: Metadata

        init(_ c: C.UnoGroupSplit) {
            self.metadata = c
        }

        deinit {
            C.uno_free_group_split(metadata)
        }

        ///
        /// The constituent member shares.
        ///
        public var shares: [Share] {
            get throws { try
                (0 ..< metadata.share_count).map(UInt8.init).map {
                    var out = UnoShare()
                    let ret = C.uno_get_s39_share_by_index(metadata, $0, &out)
                    if ret > 0 {
                        throw Err.code(ret)
                    }
                    return Share(out)
                }
            }
        }

        @available(swift, deprecated: 5.5, message: "use the property instead")
        public func getShares() throws -> [Share] {
            try (0 ..< metadata.share_count).map(UInt8.init).map {
                var out = UnoShare()
                let ret = C.uno_get_s39_share_by_index(metadata, $0, &out)
                if ret > 0 {
                    throw Err.code(ret)
                }
                return Share(out)
            }
        }
    }

    ///
    /// A share is one of the members of a Group. The common form of a share is
    /// its 33 word mnemonic representation, however, a share contains metadata
    /// which may be viewed by parsing the mnemonic encoding. The metadata is
    /// available via the property of the same name.
    ///
    public class Share {
        public typealias Metadata = C.UnoShareMetadata

        private let cShare: C.UnoShare

        private var _metadata: Metadata?

        public convenience init(mnemonic m: String) throws {
            var out = C.UnoShare()
            let ret = C.uno_get_s39_share_from_mnemonic(m, &out)
            if ret > 0 {
                throw Err.code(ret)
            }
            self.init(out)
        }

        init(_ c: C.UnoShare) {
            self.cShare = c
        }

        deinit {
            _metadata.map { C.uno_free_s39_share_metadata($0) }
            C.uno_free_s39_share(cShare)
        }

        /// The slip-0039 mnemonic (string of 33 words) form of the share.
        public lazy var mnemonic = String(cString: cShare.mnemonic)

        /// Get additional information about the share. This call can fail if
        /// the backing library encounters an error.
        // TODO: Swift 5.5
//        public var metadata: Metadata {
//            get throws {
//                if let m = _metadata {
//                    return m
//                }
//                var out = Metadata()
//                let ret = C.uno_get_s39_share_metadata(cShare, &out)
//                if ret > 0 {
//                    throw Err.code(ret)
//                }
//                self._metadata = out
//                return out
//            }
//        }

        public func getMetadata() throws -> Metadata {
            if let m = _metadata {
                return m
            }
            var out = Metadata()
            let ret = C.uno_get_s39_share_metadata(cShare, &out)
            if ret > 0 {
                throw Err.code(ret)
            }
            self._metadata = out
            return out
        }
    }
    
    ///
    /// Shard an uno ID into different pieces according to the provided Spec
    /// list.
    ///
    public static func split(id: ID, specs: [Spec]) throws -> [Group] {
        var out: OpaquePointer?
        let ret = C.uno_s39_split(id.ptr, 1, specs, 1, &out)
        if ret > 0 {
            throw Err.code(ret)
        }
        let usr = out! // UnoSplitResult
        defer { C.uno_free_split_result(usr) }

        return try specs.enumerated().map {
            var ugs = UnoGroupSplit()
            let ret = C.uno_get_group_from_split_result(usr, $0.0, &ugs)
            if ret > 0 {
                throw Err.code(ret)
            }
            return Group(ugs)
        }
    }

    ///
    /// Reconstitute an uno ID previously split into a group of shares.
    ///
    public static func combine(shares: [Share]) throws -> ID {
        let mnemonics = shares.map { $0.mnemonic }
        var out: OpaquePointer?
        // TODO: rework ffi so we can just pass array of shares...
        let ret = withArrayOfCStrings(mnemonics) { arr -> Int32 in
            let const_arr = arr.map { UnsafePointer($0) }
            return C.uno_s39_combine(const_arr, mnemonics.count, &out)
        }
        if ret > 0 {
            throw Err.code(ret)
        }
        let id = out! // UnoId
        return ID(id)
    }
}

//
// TODO: Rework C ffi so this is not necessary.
//
// Other than this being slightly annoying, I think the api works better if the
// caller transforms the mnemonic string into a share first, anyway. That gives
// the caller visibility into any error and allows them to arrange/filter the
// shares to better ensure successful recombination.
//
// Convert an `[String]` to an array of C strings `[*char]`.
//
//    https://oleb.net/blog/2016/10/swift-array-of-c-strings/
//
// The implementation is taken from the private parts of the Swift standard
// library:
//
//    https://github.com/apple/swift/blob/main/stdlib/private/SwiftPrivate/SwiftPrivate.swift
//
func withArrayOfCStrings<R>(
  _ args: [String], _ body: ([UnsafeMutablePointer<CChar>?]) -> R
) -> R {
    let argsCounts = Array(args.map { $0.utf8.count + 1 })
    let argsOffsets = [ 0 ] + scan(argsCounts, 0, +)
    let argsBufferSize = argsOffsets.last!

    var argsBuffer = [UInt8]()
    argsBuffer.reserveCapacity(argsBufferSize)
    for arg in args {
        argsBuffer.append(contentsOf: arg.utf8)
        argsBuffer.append(0)
    }

    return argsBuffer.withUnsafeMutableBufferPointer { argsBuffer in
        let ptr = UnsafeMutableRawPointer(argsBuffer.baseAddress!).bindMemory(
            to: CChar.self,
            capacity: argsBuffer.count
        )
        var cStrings: [UnsafeMutablePointer<CChar>?] = argsOffsets
            .map { ptr + $0 }

        cStrings[cStrings.count - 1] = nil

        return body(cStrings)
    }
}

//
// Compute the prefix sum of `seq`.
//
// Used by withArrayOfCStrings. Also from the swift standard lib in the same
// file.
//
func scan<S : Sequence, U>
(
    _ seq: S,
    _ initial: U,
    _ combine: (U, S.Element) -> U
)
-> [U]
{
    var result: [U] = []
    result.reserveCapacity(seq.underestimatedCount)
    var runningResult = initial
    for element in seq {
        runningResult = combine(runningResult, element)
        result.append(runningResult)
    }
    return result
}
