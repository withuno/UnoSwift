import XCTest
@testable import UnoSwift

final class Functional: XCTestCase {
    func testIdInit() {
        let bytes = Array<UInt8>(repeating: 0, count: 32)
        let id = UnoSwift.Id(data: bytes)
        XCTAssertNotNil(id)
    }
    
    func testIdFail() {
        let bytes = Array<UInt8>(repeating: 0, count: 31)
        let id = UnoSwift.Id(data: bytes)
        XCTAssertNil(id)
    }
    
    func testRoundtrip() {
//        let spec = Spec(threshold: 2, total: 3)
//        let data = "this secret".data(using: .utf8)!
//        let shares = try! Shamir.split(data: data, spec: spec)
//        let secret1 = try! Shamir.combine(shares: Array(shares[0...1]))
//        let secret2 = try! Shamir.combine(shares: Array(shares[1...2]))
//        XCTAssertEqual(data, secret1)
//        XCTAssertEqual(data, secret2)
    }

    static var allTests = [
        ("testIdInit", testIdInit),
        ("testIdFail", testIdFail),
        ("testRoundtrip", testRoundtrip),
    ]
}
