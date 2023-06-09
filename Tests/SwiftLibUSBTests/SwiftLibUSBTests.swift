import XCTest
@testable import SwiftLibUSB

final class SwiftLibUSBTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftLibUSB().text, "Hello, World!")
    }
}
