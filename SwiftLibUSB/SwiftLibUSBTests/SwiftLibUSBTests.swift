//
//  SwiftLibUSBTests.swift
//  SwiftLibUSBTests
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import XCTest
@testable import SwiftLibUSB

final class SwiftLibUSBTests: XCTestCase {
    var instrument: USBTMCInstrument?

    override func setUpWithError() throws {
        try instrument = USBTMCInstrument(vendorID: 10893, productID: 5634, serialNumber: nil)
    }

    override func tearDown() {
        instrument = nil
    }

    func testLargeCommand() throws {
        try instrument?.write(":SOURCE:VOLTAGE MINIMUM; :SOURCE:CURRENT MINIMUM", appending: "\n", encoding: .ascii)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
