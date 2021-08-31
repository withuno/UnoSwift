import XCTest
@testable import Uno

final class Functional: XCTestCase {
    func testIdInit() {
        let bytes = [UInt8](repeating: 0, count: 32)
        let id = try? Uno.ID(data: bytes)
        XCTAssertNotNil(id)
    }

    func testIdFail() {
        let bytes = [UInt8](repeating: 0, count: 31)
        let id = try? Uno.ID(data: bytes)
        XCTAssertNil(id)
    }

    func testS39single() {
        let bytes = [UInt8](repeating: 2, count: 32)
        let id = try? Uno.ID(data: bytes)
        XCTAssertNotNil(id)

        let specs = [
            Uno.S39.Spec(threshold: 1, total: 1),
        ]
        let groups = try? Uno.S39.split(id: id!, specs: specs)
        XCTAssertNotNil(groups)

        let shares = try! groups!.first!.getShares()
        let secret = try! Uno.S39.combine(shares: shares)

        XCTAssertEqual(bytes, try! secret.getBytes())
    }

    func testS39roundtrip() {
        let bytes = [UInt8](repeating: 1, count: 32)
        let id = try? Uno.ID(data: bytes)
        XCTAssertNotNil(id)

        let specs = [
            Uno.S39.Spec(threshold: 2, total: 3),
        ]
        let groups = try? Uno.S39.split(id: id!, specs: specs)
        XCTAssertNotNil(groups)

        let shares = try! groups!.first!.getShares()

        let secret1 = try! Uno.S39.combine(shares: Array(shares[0...1]))
        let secret2 = try! Uno.S39.combine(shares: Array(shares[1...2]))

        XCTAssertEqual(bytes, try! secret1.getBytes())
        XCTAssertEqual(bytes, try! secret2.getBytes())
    }

    func testS39metadata() {
        let mnemonic = """
            security flea academic academic album walnut mayor enjoy sniff ticket screw \
            junior freshman exchange emperor estimate fatal deal excuse require belong answer \
            payroll evidence duckling sidewalk wine verdict window formal firm review vocal
            """
        let bytes: [UInt8] = [
            103, 224, 142, 81, 253, 19, 149, 198,
            30, 181, 201, 53, 69, 18, 197, 56,
            192, 77, 238, 193, 44, 45, 163, 18,
            243, 227, 43, 251, 188, 223, 181, 107
        ]
        let share = try! Uno.S39.Share(mnemonic: mnemonic)
        let metadata = try! share.getMetadata()

        XCTAssertEqual(metadata.identifier, 25547)
        XCTAssertEqual(metadata.iteration_exponent, 0)
        XCTAssertEqual(metadata.group_index, 0)
        XCTAssertEqual(metadata.group_threshold, 1)
        XCTAssertEqual(metadata.group_count, 1)
        XCTAssertEqual(metadata.member_index, 0)
        XCTAssertEqual(metadata.member_threshold, 1)
        for i in 0 ..< metadata.share_value.len {
            let byte = metadata.share_value.ptr.advanced(by: i).pointee
            XCTAssertEqual(byte, bytes[i])
        }
        XCTAssertEqual(metadata.checksum, 0)
    }

    static var allTests = [
        ("Id init success", testIdInit),
        ("Id init failure", testIdFail),
        ("S39 1:1 roundtrip", testS39single),
        ("S39 2:3 roundtrip", testS39roundtrip),
        ("s39 metadata", testS39metadata),
    ]
}
