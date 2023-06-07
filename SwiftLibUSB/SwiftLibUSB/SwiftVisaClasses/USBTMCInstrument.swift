//
//  USBTMCInstrument.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 6/2/23.
//

import Foundation
import CoreSwiftVISA

/// An Instrument connected over USB
///
/// This depends on the USB device using the USBTMC interface, which should be the case for all VISA-compatible instruments. If you need to connect to a USB device that does not support this protocol, you will need a new class to communicate with it.
class USBTMCInstrument : USBInstrument {
    public var attributes = MessageBasedInstrumentAttributes()
    var messageIndex: UInt8
    var inEndpoint: Endpoint?
    var outEndpoint: Endpoint?
    
    /// Attempts to connect to a USB device with the given identification.
    ///
    /// - Parameters:
    ///    - vendorID: the number assigned to the manufacturer of the device
    ///    - productID: the number assigned to this type of device
    ///    - SerialNumber: an optional string assigned uniquely to this device. This is needed if multiple of the same type of device are connected.
    ///
    ///    These can be found from the VISA identification string in the following format: `USB::<vendorID>::<productID>::<SerialNumber>::...`
    ///
    /// - Throws: an error if the device was not found, or if it doesn't support the USBTMC interface.
    override init(vendorID: Int, productID: Int, SerialNumber: String?) throws {
        messageIndex = 1
        inEndpoint = nil
        outEndpoint = nil
        try super.init(vendorID: vendorID, productID: productID, SerialNumber: SerialNumber)
        try findEndpoints()
    }
}
extension USBTMCInstrument {
    /// Looks through the available configurations and interfaces for an AltSetting that supports USBTMC
    private func findEndpoints() throws {
        let device = self._session.usbDevice
        
        for config in device.configurations {
            for interface in config.interfaces {
                for altSetting in interface.altSettings {
                    var validEndpoint = endpointCheck(altSetting: altSetting)
                    if(validEndpoint){
                        try setupEndpoints(config: config, interface: interface, altSetting: altSetting)
                        return
                    }
                }
            }
        }
        // If the loop finishes without finding endpoints that meet our requirements, we must throw
        throw Error.couldNotFindEndpoint
    }
    
    /// Checks if an AltSetting supports USBTMC
    private func endpointCheck(altSetting: AltSetting) -> Bool {
        return altSetting.interfaceClass == .application &&
                altSetting.interfaceSubClass == 0x03 &&
        (altSetting.interfaceProtocol == 0 || altSetting.interfaceProtocol == 1)
    }
    
    /// Claims the interfaces and selects the endpoints for communicating
    private func setupEndpoints(config: Configuration, interface: Interface, altSetting: AltSetting) throws{
        try config.setActive()
        try interface.claim()
        try altSetting.setActive()
        
        inEndpoint = try getEndpoint(endpoints: altSetting.endpoints,direction: Direction.In)
        outEndpoint = try getEndpoint(endpoints: altSetting.endpoints,direction: Direction.Out)
    }
    
    /// Finds an endpoint with the intended direction
    private func getEndpoint(endpoints: [Endpoint],direction: Direction) throws -> Endpoint  {
        for endpoint in endpoints {
            if endpoint.direction == direction && endpoint.transferType == .bulk {
                return endpoint
            }
        }
        throw Error.couldNotFindEndpoint
    }
    
    /// Increment the message index such that it remains in the range [1-255] inclusive
    private func nextMessage() {
        messageIndex = (messageIndex % 255) + 1
    }
}
extension USBTMCInstrument : MessageBasedInstrument {
    func read(until terminator: String, strippingTerminator: Bool, encoding: String.Encoding, chunkSize: Int) throws -> String {
        var dataRead = try readBytes(maxLength: nil, until: terminator.data(using: encoding), strippingTerminator: strippingTerminator, chunkSize: chunkSize)
        return String(decoding: dataRead, as: UTF8.self)
    }
    
    func readBytes(length: Int, chunkSize: Int) throws -> Data {
        // Send read request to out endpoint
        let readBufferSize = 1024
        // Part 1 of header: Read In (constant 2), message index, inverse of message index, padding
        var message = Data([2, messageIndex, 255-messageIndex, 0])
        // Part 2 of header: Little Endian length of the buffer
        withUnsafeBytes(of: Int32(readBufferSize).littleEndian) { lengthBytes in
            message.append(Data(Array(lengthBytes)))
        }
        // Part 3 of header: Bit to indicate presence of terminator byte, Optional terminator byte (not used here), two bytes of padding
        message.append(Data([0,0,0,0]))
        
        // Clear halt for the in endpoint
        inEndpoint.unsafelyUnwrapped.clearHalt()
        
        // Send the request message to a bulk out endpoint
        let num = try outEndpoint.unsafelyUnwrapped.sendBulkTransfer(data: &message)
        print("Sent \(num) bytes")
        print ("Sent request message")
        
        // Get the response message from a bulk in endpoint and print it
        let data = try inEndpoint.unsafelyUnwrapped.receiveBulkTransfer()
        print([UInt8](data))
        
        nextMessage()
        
        return data[12...]
    }
    
    func readBytes(maxLength: Int?, until terminator: Data, strippingTerminator: Bool, chunkSize: Int) throws -> Data {
        throw USBError.notSupported
    }
    
    func write(_ string: String, appending terminator: String?, encoding: String.Encoding) throws -> Int {
        let message = string + (terminator ?? "")
        let messageData = message.data(using: encoding)
        
        if(messageData == nil) {
            throw Error.cannotEncode
        }
        return try writeBytes(messageData!, appending: nil)
    }
    
    func writeBytes(_ data: Data, appending terminator: Data?) throws -> Int {
        let messageData = data + (terminator ?? Data())
        let writeSize = 12 // TODO: Increase to a larger number
        
        var sliceNum = 0
        var lastMessage = false
        while(!lastMessage) {
            sliceNum += 1
            let lowerBound = (sliceNum - 1) * writeSize
            var upperBound = sliceNum * writeSize
            
            if(upperBound >= messageData.count){
                lastMessage = true
                upperBound = messageData.count
            }
            var dataSlice = messageData.subdata(in: lowerBound..<upperBound)
            
            // Part 1 of header: Write Out (constant 1), message index, inverse of message index, padding
            var dataToSend = Data([1, messageIndex, 255-messageIndex, 0])
            // Part 2 of header: Little Endian length of the message (with added newline)
            withUnsafeBytes(of: Int32(dataSlice.count).littleEndian) { lengthBytes in
                dataToSend.append(Data(Array(lengthBytes)))
            }
            // Part 3 of header: end of field
            if(lastMessage){
                dataToSend.append(1)
            }else{
                dataToSend.append(0)
            }
            // Part 4 of header: Three bytes of padding
            dataToSend.append(Data([0, 0, 0]))
            // Add the message as bytes
            dataToSend.append(dataSlice)
            
            // Pad to 4 byte boundary
            dataToSend.append(Data(Array(repeating: 0, count: (4 - dataSlice.count % 4) % 4)))
            
            print([UInt8](dataToSend)) // TODO: Remove debug print
            
            // Send the command message to a bulk out endpoint
            (outEndpoint!).clearHalt()
            let num = try (outEndpoint!).sendBulkTransfer(data: &dataToSend)
            print("Sent \(num) bytes") // TODO: Remove debug print
            nextMessage()
        }
        return 0
    }
}
