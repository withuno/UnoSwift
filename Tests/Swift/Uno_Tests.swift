import XCTest
@testable import Uno

final class Functional: XCTestCase {
    func testIdInit() {
        let bytes = Array<UInt8>(repeating: 0, count: 32)
        let id = try? Uno.ID(data: bytes)
        XCTAssertNotNil(id)
    }

    func testIdFail() {
        let bytes = Array<UInt8>(repeating: 0, count: 31)
        let id = try? Uno.ID(data: bytes)
        XCTAssertNil(id)
    }

    func testS39roundtrip() {
        let bytes = Array<UInt8>(repeating: 1, count: 32)
        let id = try? Uno.ID(data: bytes)
        XCTAssertNotNil(id)

        let specs = [
            Uno.S39.Spec(threshold: 2, total: 3),
        ]
        let groups = try? Uno.S39.split(id: id!, specs: specs)
        XCTAssertNotNil(groups)

        let mnemonics = try! groups![0].shares.map { $0.mnemonic }

        let secret1 = try! Uno.S39.combine(shares: Array(mnemonics[0...1]))
        let secret2 = try! Uno.S39.combine(shares: Array(mnemonics[1...2]))

        XCTAssertEqual(bytes, try! secret1.bytes)
        XCTAssertEqual(bytes, try! secret2.bytes)
    }

    static var allTests = [
        ("Id init success", testIdInit),
        ("Id init failure", testIdFail),
        ("S39 full roundtrip", testS39roundtrip),
    ]
}
