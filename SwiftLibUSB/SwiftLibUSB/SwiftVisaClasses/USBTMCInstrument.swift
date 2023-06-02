//
//  USBTMCInstrument.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 6/2/23.
//

import Foundation
import CoreSwiftVISA

class USBTMCInstrument : USBInstrument {
    public var attributes = MessageBasedInstrumentAttributes()
    var messageIndex: UInt8
    var inEndpoint: Endpoint?
    var outEndpoint: Endpoint?
    
    override init(vendorID: Int, productID: Int, SerialNumber: String?) throws {
        try super.init(vendorID: vendorID, productID: productID, SerialNumber: SerialNumber)
        
        messageIndex = 1
    }
    
    func nextMessage() {
        messageIndex = (messageIndex % 255) + 1
    }
}

extension USBTMCInstrument : MessageBasedInstrument {
    func read(until terminator: String, strippingTerminator: Bool, encoding: String.Encoding, chunkSize: Int) throws -> String {
        return ""
    }
    
    func readBytes(length: Int, chunkSize: Int) throws -> Data {
        return Data()
    }
    
    func readBytes(maxLength: Int?, until terminator: Data, strippingTerminator: Bool, chunkSize: Int) throws -> Data {
        return Data()
    }
    
    func write(_ string: String, appending terminator: String?, encoding: String.Encoding) throws -> Int {
        var message = string + (terminator ?? "")
        var messageData = message.data(using: encoding)
        
        if(messageData == nil) {
            throw Error.cannotEncode
        }
        
        // Part 1 of header: Write Out (constant 1), message index, inverse of message index, padding
        var dataToSend = Data([1, messageIndex, 255-messageIndex, 0])
        // Part 2 of header: Little Endian length of the message (with added newline)
        withUnsafeBytes(of: Int32(message.count).littleEndian) { lengthBytes in
            dataToSend.append(Data(Array(lengthBytes)))
        }
        // Part 3 of header: End of Message (constant 1), three bytes of padding
        dataToSend.append(Data([1, 0, 0, 0]))
        // Add the message as bytes
        dataToSend.append(messageData!)
        
        // Pad to 4 byte boundary
        dataToSend.append(Data(Array(repeating: 0, count: (4 - message.count % 4) % 4)))
        
        print([UInt8](dataToSend))
        
        // Send the command message to a bulk out endpoint
        outEndpoint.unsafelyUnwrapped.clearHalt()
        var num = try outEndpoint.unsafelyUnwrapped.sendBulkTransfer(data: &dataToSend)
        print("Sent \(num) bytes")
        nextMessage()
        
        return 0
    }
    
    func writeBytes(_ data: Data, appending terminator: Data?) throws -> Int {
        return 0
    }
}
