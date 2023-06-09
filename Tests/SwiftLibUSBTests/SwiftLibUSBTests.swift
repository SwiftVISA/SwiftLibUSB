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
        try instrument = USBTMCInstrument(visaString: "USB0::10893::5634::MY59001442::0::INSTR")
    }

    override func tearDown() {
        instrument = nil
    }

    func testLargeCommand() throws {
        try instrument?.write(":SOURCE:VOLTAGE MINIMUM; :SOURCE:CURRENT MINIMUM", appending: "\n", encoding: .ascii)
    }
    
    func testRawResponse() throws {
        try instrument?.write("VOLT 1;VOLT?")
        let response = try instrument!.readBytes(length: 1024, chunkSize: 16)
        XCTAssert(response == "+1.000000E+00 \n".data(using: .utf8))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
