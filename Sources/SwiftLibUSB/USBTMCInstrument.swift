//
//  USBTMCInstrument.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 6/2/23.
//

import Foundation
import CoreSwiftVISA


/// A common type of instrument connected over USB.
/// This class controlls USB Test and Measurement Class Devices. [The specification for which can be found here](https://www.usb.org/document-library/test-measurement-class-specification).
/// This classification of devices is used for VISA-compatible instruments. If you need to connect to a USB device that does not support this protocol, you will need a new class to communicate with it.
///
/// A USBTMCInstrument is a USBInstrument, meaning it holds a USB session. The USBSession handles the connection and finding the device
/// This class a Message Based Instrument meaning it can read and write messages
///
/// A USBTMCInstrument can be created using either identifiying characteristics(vendorID,productID,serialNumber) or by the devices Visa String. For more detail on constructing, see the initlisers
///
/// Instruments are automatically found and connected to, and prepepared for communication on inilitisation. They can be written to and read from immedietly. If a problem is encountered, a ``USBTMCInstrument/USBTMCError`` is thrown
public class USBTMCInstrument : USBInstrument {
    // USB instruments are required to have various attributes, we use the defaults
    public var attributes = MessageBasedInstrumentAttributes()
    var messageIndex: UInt8
    var inEndpoint: Endpoint?
    var outEndpoint: Endpoint?
    var activeInterface: AltSetting?
    var canUseTerminator: Bool
    
    /// Attempts to connect to a USB device with the given identification.
    ///
    /// - Parameters:
    ///    - vendorID: the number assigned to the manufacturer of the device
    ///    - productID: the number assigned to this type of device
    ///    - SerialNumber: an optional string assigned uniquely to this device. This is needed if multiple of the same type of device are connected.
    ///
    ///    These can be found from the VISA identification string in the following format: `USB::<vendorID>::<productID>::<SerialNumber>::...`
    ///
    /// - Throws: ``USBInstrument/Error`` if there is an error establishing the instrument, ``USBError`` if the libUSB library encounters an error and ``USBTMCInstrument/Error`` if there is any other problem.
    override init(vendorID: Int, productID: Int, serialNumber: String? = nil) throws {
        messageIndex = 1
        inEndpoint = nil
        outEndpoint = nil
        activeInterface = nil
        canUseTerminator = false
        try super.init(vendorID: vendorID, productID: productID, serialNumber: serialNumber)
        try findEndpoints()
        getCapabilities()
    }
    
    /// An alternarte initiliser for creating a USB Test and Measurment Class Device
    ///
    /// This initliser uses a raw Visa String instead of the individual parameters. An example is
    /// `USB0::10893::5634::MY59001442::0::INSTR`
    /// - Parameters:
    ///     - visaString: A properly formatted visa string that corresponds to a physically connected device
    /// - Throws: ``USBInstrument/Error`` if there is an error establishing the instrument, ``USBError`` if the libUSB library encounters an error and ``USBTMCInstrument/Error`` if there is any other problem.
    convenience init (visaString: String) throws {
        let sections = visaString.split(separator: "::")
        if sections.count < 4 {
            throw Error.operationFailed // TODO: use a USBTMCInstrument Error
        }
        let vendorID = Int(sections[1])
        let productID = Int(sections[2])
        if vendorID == nil || productID == nil {
            throw Error.operationFailed // TODO: use a USBTMCInstrument Error
        }
        
        try self.init(vendorID:vendorID!,productID:productID!, serialNumber: String(sections[3]))
    }
}
extension USBTMCInstrument {
    private static let HEADER_SIZE = 12
    private static let TRANSFER_ATTRIBUTES_BYTE = 8
    private static let END_OF_MESSAGE_BIT: UInt8 = 1
    
    /// Message types defined by USBTMC specification, table 15
    private enum ControlMessages {
        case initiateAbortBulkOut
        case checkAbortBulkOutStatus
        case initiateAbortBulkIn
        case checkAbortBulkInStatus
        case initiateClear
        case checkClearStatus
        case getCapabilities
        case indicatorPulse
        
        func toByte() -> UInt8 {
            switch self {
            // 0 is reserved
            case .initiateAbortBulkOut: return 1
            case .checkAbortBulkOutStatus: return 2
            case .initiateAbortBulkIn: return 3
            case .checkAbortBulkInStatus: return 4
            case .initiateClear: return 5
            case .checkClearStatus: return 6
            case .getCapabilities: return 7
            case .indicatorPulse: return 64 // This is correct; there is a very large gap here
            }
        }
    }
    /// Looks through the available configurations and interfaces for an AltSetting that supports USBTMC
    private func findEndpoints() throws {
        let device = self._session.usbDevice
        
        for config in device.configurations {
            for interface in config.interfaces {
                for altSetting in interface.altSettings {
                    var validEndpoint = endpointCheck(altSetting: altSetting)
                    if validEndpoint {
                        try setupEndpoints(config: config, interface: interface, altSetting: altSetting)
                        return
                    }
                }
            }
        }
        // If the loop finishes without finding endpoints that meet our requirements, we must throw
        throw USBTMCError.couldNotFindEndpoint
    }
    
    /// Checks if an AltSetting supports USBTMC
    private func endpointCheck(altSetting: AltSetting) -> Bool {
        return altSetting.interfaceClass == .application &&
                altSetting.interfaceSubClass == 0x03 &&
        (altSetting.interfaceProtocol == 0 || altSetting.interfaceProtocol == 1)
    }
    
    /// Claims the interfaces and selects the in and out endpoints for communicating with a device
    private func setupEndpoints(config: Configuration, interface: Interface, altSetting: AltSetting) throws {
        try config.setActive()
        try interface.claim()
        try altSetting.setActive()
        activeInterface = altSetting
        inEndpoint = try getEndpoint(endpoints: altSetting.endpoints,direction: Direction.In)
        outEndpoint = try getEndpoint(endpoints: altSetting.endpoints,direction: Direction.Out)
    }
    
    /// Finds a bulk trasnfer endpoint with the intended direction
    private func getEndpoint(endpoints: [Endpoint], direction: Direction) throws -> Endpoint {
        for endpoint in endpoints {
            if endpoint.direction == direction && endpoint.transferType == .bulk {
                return endpoint
            }
        }
        throw USBTMCError.couldNotFindEndpoint
    }
    
    /// Increment the message index such that it remains in the range [1-255] inclusive
    private func nextMessage() {
        messageIndex = (messageIndex % 255) + 1
    }
    
    /// Creates the portion of the header described in Table 8 of the USBTMC specifications. It then adds the transfer size parameter. Almost all messages to and from a device include this header.
    /// - Parameters:
    ///   - read: Boolean describing whether the information flows to or from a device. Use `true` if reading from the devide, and `false` if writing to the device. By default, this value is `false`.
    ///   - bufferSize:The amount of data being sent or received. The default value is 1028.
    /// - Returns: The filled header of the message to be sent or received.
    private func makeHeader(read: Bool = false, bufferSize: Int = 1028) -> Data {
        // Part 1 of header: message type, message index, inverse of message index, padding
        var firstByte : UInt8 = read ? 2 : 1 // Reads are type 2, writes are type 1
        var message = Data([firstByte, messageIndex, 255-messageIndex, 0])

        // Part 2 of header: Little Endian length of the buffer
        withUnsafeBytes(of: Int32(bufferSize).littleEndian) { lengthBytes in
            message.append(Data(Array(lengthBytes)))
        }
        return message
    }
    
    /// Get the capabilities of the device.
    ///
    /// Available capabilities include whether the device supports sending data, receiving data, pulsing, or using a terminator character on reads.
    private func getCapabilities() {
        do {
            // These arguments are defined by the USBTMC specification, table 36
            let capabilities: Data = try _session.usbDevice.sendControlTransfer(
                direction: .In,
                type: .Class,
                recipient: .Interface,
                request: ControlMessages.getCapabilities.toByte(),
                value: 0,
                index: UInt16(activeInterface?.index ?? 0),
                data: Data(count: 24),
                length: 24,
                timeout: 10000
            )
            let termCapability = [UInt8](capabilities.subdata(in: 5..<6))[0]
            canUseTerminator = termCapability == 1
        } catch {
            // Ignore errors for now
            canUseTerminator = false
        }
    }

    /// Send a USBTMC request message as defined in section 3.2.1.2 of the USBTMC specifications.
    /// - Parameters:
    ///   - headerSuffix: Header for the read request
    ///   - length: The maximum amount of data to receive
    ///   - chunkSize: The amount of data to receive each time
    /// - Returns: The data read from the device
    func receiveUntilEndOfMessage(headerSuffix: Data, length: Int?, chunkSize: Int) throws -> Data {
        var readData = Data()
        var endOfMessage = false
        
        // TODO: get max transfer size
        
        while !endOfMessage {
            var message : Data
            
            // Send read request to out endpoint
            if length != nil {
                message = makeHeader(read: true, bufferSize: min(chunkSize, length! - readData.count))
            } else {
                message = makeHeader(read: true, bufferSize: chunkSize)
            }
            
            message += headerSuffix
            
            // Clear halt for the in endpoint
            inEndpoint!.clearHalt()
            
            // Send the request message to a bulk out endpoint
            let num = try outEndpoint!.sendBulkTransfer(data: &message)
            
            // Get the response message from a bulk in endpoint and print it
            let data = try inEndpoint.unsafelyUnwrapped.receiveBulkTransfer()
            print([UInt8](data))
            
            nextMessage()
            
            endOfMessage = data[Self.TRANSFER_ATTRIBUTES_BYTE] & Self.END_OF_MESSAGE_BIT != 0
            
            // Don't add the header to the data buffer
            readData += data[Self.HEADER_SIZE...]
        }
        
        return readData
    }
}
extension USBTMCInstrument : MessageBasedInstrument {
    func read(until terminator: String, strippingTerminator: Bool, encoding: String.Encoding, chunkSize: Int) throws -> String {
        // Prepare the parameters
        guard let terminatorBytes = terminator.data(using:encoding) else {
            throw USBTMCError.invalidTerminator
        }
        
        // Make the call to readBytes
        var dataRead = try readBytes(maxLength: nil, until: terminatorBytes, strippingTerminator: strippingTerminator, chunkSize: chunkSize)
        
        // Encode the output as a string
        var outputString : String? = String(data: dataRead, encoding: encoding)
        if outputString == nil{
            throw USBTMCError.cannotEncode
        }
        return outputString!
    }
    
    func readBytes(length: Int, chunkSize: Int) throws -> Data {
        return try receiveUntilEndOfMessage(headerSuffix: Data([0, 0, 0, 0]), length: length, chunkSize: chunkSize)
    }
    
    /// Reads bytes from a device until the terminator is reached.
    /// - Parameters:
    ///   - maxLength: The maximum number of bytes to read.
    ///   - terminator: The byte sequence to end reading at.
    ///   - strippingTerminator: If `true`, the terminator is stripped from the data before being returned, otherwise the data is returned with the terminator at the end.
    ///   - chunkSize: The number of bytes to read into a buffer at a time.
    /// - Throws: Error if the device could not be read from.
    /// - Returns: The data read from the device as bytes.
    func readBytes(maxLength: Int?, until terminator: Data, strippingTerminator: Bool, chunkSize: Int) throws -> Data {
        //check if terminator is ok
        if !canUseTerminator { throw Error.notSupported }
        if terminator.count != 1 { throw USBTMCError.invalidTerminator }
        
        var received: Data = try receiveUntilEndOfMessage(headerSuffix: Data([2, terminator[0], 0, 0]),
                                                          length: maxLength, chunkSize: chunkSize)
        
        if strippingTerminator {
           return received.dropLast(1)
        } else {
            return received
        }
    }
    
    /// Write data to the device as a string.
    /// - Parameters:
    ///   - string: The string to write to the device.
    ///   - terminator: The terminator to add to the end of `string`.
    ///   - encoding: The method to encode the string with.
    /// - Throws: Error if the device could not be written to.
    /// - Returns: The number of bytes that were written to the device.
    func write(_ string: String, appending terminator: String?, encoding: String.Encoding) throws -> Int {
        let message = string + (terminator ?? "")
        let messageData = message.data(using: encoding)
        
        if messageData == nil {
            throw USBTMCError.cannotEncode
        }
        return try writeBytes(messageData!, appending: nil)
    }
    
    /// Write data to a device as bytes.
    /// - Parameters:
    ///   - bytes: The data to write to the device.
    ///   - terminator: The sequence of bytes to append to the end of `bytes`.
    /// - Returns: The number of bytes that were written to the device.
    func writeBytes(_ data: Data, appending terminator: Data?) throws -> Int {
        let messageData = data + (terminator ?? Data())
        let writeSize = min(data.count,1024)
        
        // Split the message if necessary
        var sliceNum = 0
        var lastMessage = false
        while !lastMessage {
            sliceNum += 1
            let lowerBound = (sliceNum - 1) * writeSize
            var upperBound = sliceNum * writeSize
            
            if upperBound >= messageData.count {
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
            if lastMessage {
                dataToSend.append(1)
            } else {
                dataToSend.append(0)
            }
            // Part 4 of header: Three bytes of padding
            dataToSend.append(Data([0, 0, 0]))
            // Add the message as bytes
            dataToSend.append(dataSlice)
            
            // Pad to 4 byte boundary
            dataToSend.append(Data(Array(repeating: 0, count: (4 - dataSlice.count % 4) % 4)))
            
            // Send the command message to a bulk out endpoint
            (outEndpoint!).clearHalt()
            let num = try (outEndpoint!).sendBulkTransfer(data: &dataToSend)
            nextMessage()
        }
        return 0
    }
}

extension USBTMCInstrument {
    /// An error associated with a  USB Instrument.
    ///
    public enum USBTMCError: Swift.Error {
        /// When looking for USB endpoints to send messages through, no alternative setting could be found that has compliant endpoints
        /// Or an altsetting claims to have endpoints it doesn't have.
        case couldNotFindEndpoint
        
        ///The terminator given could not be accepted by the device
        case invalidTerminator
        
        /// When attempting to encode a user given string with a user given encoding, an error occurs
        case cannotEncode
    }
}

extension USBTMCInstrument.USBTMCError {
    public var localizedDescription: String {
        switch self {
        case .couldNotFindEndpoint:
            return "Could not find at least one required endpoint that satisfies requirements"
        case .invalidTerminator:
            return "Invalid terminator given"
        case .cannotEncode:
            return "Could not encode given string with given encoding"
        }
    }
}