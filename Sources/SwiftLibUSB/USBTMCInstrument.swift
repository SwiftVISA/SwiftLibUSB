//
//  USBTMCInstrument.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 6/2/23.
//

import Foundation
import CoreSwiftVISA


/// A USB instrument communicating using USBTMC.
///
/// This class controlls [USB Test and Measurement Class Devices](https://www.usb.org/document-library/test-measurement-class-specification).
/// This classification of devices is used for VISA-compatible instruments. If you need to connect to a USB device that does not support this protocol, you will need a new class to communicate with it.
public class USBTMCInstrument: Instrument {
    // We use an internal session property so we can use the USBSession methods.
    private var _session: USBSession
    
    public var session: Session {
        _session
    }
    
    // USB instruments are required to have various attributes, we use the defaults
    public var attributes = MessageBasedInstrumentAttributes()
    private var messageIndex: UInt8
    private var inEndpoint: Endpoint
    private var outEndpoint: Endpoint
    private var activeInterface: AltSetting
    private var canUseTerminator: Bool
    
    /// Attempts to connect to a USB device with the given identification.
    ///
    /// The product ID, vendor ID, and serial number can be found from the VISA identification string in the following format:
    ///
    /// `USB::<vendor ID>::<product ID>::<serial number>::...`
    ///
    /// - Parameters:
    ///    - vendorID: The number assigned to the manufacturer of the device
    ///    - productID: The number assigned to this type of device
    ///    - serialNumber: An optional string assigned uniquely to this device. This is needed if multiple of the same type of device are connected.
    ///
    /// - Throws: ``USBSession/Error`` if there is an error establishing the instrument, ``USBError`` if the libUSB library encounters an error and ``USBTMCInstrument/USBTMCError`` if there is any other problem.
    public init(vendorID: Int, productID: Int, serialNumber: String? = nil) throws {
        messageIndex = 1
        canUseTerminator = false
        try _session = USBSession(vendorID: vendorID, productID: productID, serialNumber: serialNumber)
        try (activeInterface, inEndpoint, outEndpoint) = Self.findEndpoints(device: _session.device)
        getCapabilities()
    }
    
    /// Attempt to connect to a device described by a VISA identifier.
    ///
    /// - Parameters:
    ///     - visaString: A properly formatted VISA string that corresponds to a physically connected device
    /// - Throws: ``USBSession/Error`` if there is an error establishing the instrument, ``USBError`` if the libUSB library encounters an error, and ``USBTMCInstrument/USBTMCError`` if there is any other problem.
    public convenience init (visaString: String) throws {
        let sections = visaString.components(separatedBy: "::")
        if sections.count < 4 {
            throw Error.invalidVisa
        }
        
        let vID = Int(sections[1])
        let pID = Int(sections[2])
        let serialNumber = sections[3]
        
        guard let vendorID = vID, let productID = pID else {
            throw Error.invalidVisa
        }
        
        try self.init(
            vendorID: vendorID,
            productID: productID,
            serialNumber: serialNumber)
    }
}

extension USBTMCInstrument {
    private static let headerSize = 12
    private static let transferAttributesByteIndex = 8
    private static let endOfMessageBit: UInt8 = 1
    private static let readLengthStartIndex = 4
    private static let readLengthEndIndex = 8
    private static let capabilitiesIndex = 5
    
    /// Message types defined by USBTMC specification, table 15
    private enum ControlMessage: UInt8 {
        case initiateAbortBulkOut = 1
        case checkAbortBulkOutStatus = 2
        case initiateAbortBulkIn = 3
        case checkAbortBulkInStatus = 4
        case initiateClear = 5
        case checkClearStatus = 6
        case getCapabilities = 7
        case indicatorPulse = 64
    }
    
    private enum MessageKind: UInt8 {
        case write = 1
        case read = 2
    }
    
    /// Looks through the available configurations and interfaces for an AltSetting that supports USBTMC
    /// - throws: An ``Error`` if no endpoints can be found that fit the requiements of USBTMC
    private static func findEndpoints(device: Device) throws -> (AltSetting, Endpoint, Endpoint) {
        for config in device.configurations {
            for interface in config.interfaces {
                for altSetting in interface.altSettings where isTMC(altSetting: altSetting) {
                    // Stop looking after the first USBTMC interface we find
                    return try setupEndpoints(
                        config: config,
                        interface: interface,
                        altSetting: altSetting)
                }
            }
        }
        // If the loop finishes without finding endpoints that meet our requirements, we must throw
        throw Error.couldNotFindEndpoint
    }
    
    /// Checks if an ``AltSetting`` supports USBTMC
    /// - Parameter altSetting: The ``AltSetting`` whose endpoints to check
    /// - Returns: True if the endpoint is compatible false otherwise
    private static func isTMC(altSetting: AltSetting) -> Bool {
        return altSetting.interfaceClass == .application &&
            altSetting.interfaceSubClass == 0x03 &&
            (altSetting.interfaceProtocol == 0 || altSetting.interfaceProtocol == 1)
    }
    
    
    /// Claims the interfaces and selects the in and out endpoints for communicating with a device
    /// - Parameters:
    ///   - config: The chosen device ``Configuration``
    ///   - interface: The chosen ``Interface``
    ///   - altSetting: The chosen ``AltSetting``
    /// - Throws: An ``Error`` if no suitable endpoint could be found
    private static func setupEndpoints(
        config: Configuration,
        interface: Interface,
        altSetting: AltSetting
    ) throws -> (AltSetting, Endpoint, Endpoint) {
        try config.setActive()
        try interface.claim()
        try altSetting.setActive()
        let inEndpoint = try getEndpoint(endpoints: altSetting.endpoints, direction: Direction.in)
        let outEndpoint = try getEndpoint(endpoints: altSetting.endpoints, direction: Direction.out)
        return (altSetting, inEndpoint, outEndpoint)
    }
    
    
    /// Finds the first bulk transfer endpoint with the intended direction
    /// - Parameters:
    ///   - endpoints: An array of ``Endpoint`` to check
    ///   - direction: The intended ``Direction``
    /// - Returns: The first bulk transfer ``Endpoint`` with the requested ``Direction``
    /// - Throws: An ``Error`` if no suitable endpoint can be found in the array
    private static func getEndpoint(endpoints: [Endpoint], direction: Direction) throws -> Endpoint {
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
    
    /// Creates the portion of the header described in Table 8 of the USBTMC specifications. It then adds the transfer size parameter. Almost all messages to and from a device include this header.
    /// - Parameters:
    ///   - kind: Whether this message is going to write to the device or request to read from the device
    ///   - bufferSize:The amount of data being sent or received.
    /// - Returns: The filled header of the message to be sent.
    private func makeHeader(kind: MessageKind, bufferSize: Int) -> Data {
        // Part 1 of header: message type, message index, inverse of message index, padding
        var message = Data([kind.rawValue, messageIndex, 255-messageIndex, 0])

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
            let capabilities: Data = try _session.device.sendControlTransfer(
                direction: .in,
                type: .class,
                recipient: .interface,
                request: ControlMessage.getCapabilities.rawValue,
                value: 0,
                index: UInt16(activeInterface.index),
                data: Data(count: 24),
                length: 24,
                timeout: UInt32(Int(attributes.operationDelay * 1000))
            )
            let termCapability = capabilities[Self.capabilitiesIndex]
            canUseTerminator = termCapability == 1
        } catch {
            // Ignore errors for now; assume no capabilities
            canUseTerminator = false
        }
    }

    /// Send a USBTMC request message as defined in section 3.2.1.2 of the USBTMC specifications.
    /// - Parameters:
    ///   - headerSuffix: Header for the read request
    ///   - length: The maximum amount of data to receive
    ///   - chunkSize: The amount of data to receive each time
    /// - Returns: The data read from the device
    /// - Throws: a ``USBError`` if at any point a data transfer fails
    func receiveUntilEndOfMessage(
        headerSuffix: Data,
        length: Int?,
        chunkSize: Int
    ) throws -> Data {
        var readData = Data()
        var endOfMessage = false
        
        // TODO: get max transfer size
        
        while !endOfMessage {
            var message : Data
            
            // Send read request to out endpoint
            if let length = length {
                message = makeHeader(
                    kind: MessageKind.read,
                    bufferSize: min(chunkSize, length - readData.count))
            } else {
                message = makeHeader(kind: MessageKind.read, bufferSize: chunkSize)
            }
            
            message += headerSuffix
            
            // Clear halt for the in endpoint
            try inEndpoint.clearHalt()
            
            // Send the request message to a bulk out endpoint
            try outEndpoint.sendBulkTransfer(
                data: &message,
                timeout: Int(attributes.operationDelay * 1000))
            
            // Get the response message from a bulk in endpoint
            let data = try inEndpoint.receiveBulkTransfer(
                length: chunkSize + Self.headerSize + 3,
                timeout: Int(attributes.operationDelay * 1000))
            
            nextMessage()
            
            // Don't add the header to the data buffer
            readData += data[Self.headerSize...]
            
            let resultLength = UInt32(littleEndian: data[Self.readLengthStartIndex..<Self.readLengthEndIndex].withUnsafeBytes { $0.pointee })
            if resultLength <= readData.count + data.count - Self.headerSize {
                endOfMessage = data[Self.transferAttributesByteIndex] & Self.endOfMessageBit != 0
            }
        }
        
        return readData
    }
}

extension USBTMCInstrument: MessageBasedInstrument {
    
    /// Read data from a device until the sepcified terminator is reached and return it as a string
    /// - Parameters:
    ///   - terminator: A string representing the terminator sequence
    ///   - strippingTerminator: If true removes the terminator from the data returned
    ///   - encoding: The encoding for the returned string and the terminator
    ///   - chunkSize: The number of bytes to read into a buffer at a time.
    /// - Returns: The data received as a string with the specified encoding
    /// - Throws: A ``USBError`` if a failure occurs during a data transfer or a ``Error`` if the data cannot be encoded
    public func read(
        until terminator: String,
        strippingTerminator: Bool,
        encoding: String.Encoding,
        chunkSize: Int
    ) throws -> String {
        // Prepare the parameters
        guard let terminatorBytes = terminator.data(using:encoding) else {
            throw Error.invalidTerminator
        }
        
        // Make the call to readBytes
        let dataRead = try readBytes(
            maxLength: nil,
            until: terminatorBytes,
            strippingTerminator: strippingTerminator,
            chunkSize: chunkSize)
        
        // Encode the output as a string
        guard let outputString = String(data: dataRead, encoding: encoding) else {
            throw Error.cannotEncode
        }
        return outputString
    }
    
    /// Read bytes from a device with no terminator
    /// - Parameters:
    ///   - length: The maximum number of bytes to read
    ///   - chunkSize: The number of bytes to read into a buffer at a time.
    /// - Returns: The data received
    /// - Throws: A ``USBError`` if a failure occurs during a data transfer
    public func readBytes(length: Int, chunkSize: Int) throws -> Data {
        return try receiveUntilEndOfMessage(
            headerSuffix: Data([0, 0, 0, 0]),
            length: length,
            chunkSize: chunkSize)
    }
    
    /// Reads bytes from a device until the terminator is reached.
    /// - Parameters:
    ///   - maxLength: The maximum number of bytes to read.
    ///   - terminator: The byte sequence to end reading at. USBTMC devices may not support terminator bytes, and
    ///     only support a single byte terminator if at all.
    ///   - strippingTerminator: If `true`, the terminator is stripped from the data before being returned, otherwise the data is returned with the terminator at the end.
    ///   - chunkSize: The number of bytes to read into a buffer at a time.
    /// - Throws: Error if the device could not be read from.
    /// - Returns: The data read from the device as bytes.
    /// - Throws: ``USBInstrument/Error/notSupported`` if the device does not support terminators, ``USBTMCInstrument/Error/invalidTerminator`` if the terminator has more than one byte, or a ``USBError`` if a failure occurs during a data transfer
    public func readBytes(
        maxLength: Int?,
        until terminator: Data,
        strippingTerminator: Bool,
        chunkSize: Int
    ) throws -> Data {
        //check if terminator is ok
        if !canUseTerminator { throw USBSession.Error.notSupported }
        if terminator.count != 1 { throw Error.invalidTerminator }
        
        let received: Data = try receiveUntilEndOfMessage(
            headerSuffix: Data([2, terminator[0], 0, 0]),
            length: maxLength,
            chunkSize: chunkSize)
        
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
    /// - Throws: A ``USBError`` if a failure occurs during a data transfer or an ``USBTMCInstrument/Error`` if the data cannot be encoded
    public func write(
        _ string: String,
        appending terminator: String?,
        encoding: String.Encoding
    ) throws -> Int {
        let message = string + (terminator ?? "")
        guard let messageData = message.data(using: encoding) else {
            throw Error.cannotEncode
        }
        return try writeBytes(messageData, appending: nil)
    }
    
    /// Write data to a device as bytes.
    /// - Parameters:
    ///   - bytes: The data to write to the device.
    ///   - terminator: The sequence of bytes to append to the end of `bytes`.
    /// - Returns: The number of bytes that were written to the device.
    /// - Throws: A ``USBError`` if a failure occurs during a data transfer
    public func writeBytes(_ data: Data, appending terminator: Data?) throws -> Int {
        let messageData = data + (terminator ?? Data())

        let writeSize = min(data.count,1024)

        try outEndpoint.clearHalt()

        var lastMessage = false
        var lowerBound = 0
        while !lastMessage {
            var upperBound = lowerBound + writeSize
            
            if upperBound >= messageData.count {
                lastMessage = true
                upperBound = messageData.count
            }
            let dataSlice = messageData.subdata(in: lowerBound..<upperBound)
            
            var dataToSend = makeHeader(kind: MessageKind.write, bufferSize: dataSlice.count)
            
            // After the header, there is one byte to indicate the end of message, then
            // three bytes of padding.
            dataToSend.append(Data([lastMessage ? 1 : 0, 0, 0, 0]))
            
            dataToSend.append(dataSlice)
            
            // Pad to 4 byte boundary
            let paddingLength = (4 - dataSlice.count % 4) % 4
            dataToSend.append(Data(Array(repeating: 0, count: paddingLength)))
            
            let numSent = try outEndpoint.sendBulkTransfer(
                data: &dataToSend,
                timeout: Int(attributes.operationDelay * 1000))
            
            lowerBound += numSent - Self.headerSize - paddingLength // Move up by the amount sent

            nextMessage()
        }
        return lowerBound
    }
}

extension USBTMCInstrument {
    /// An error associated with a  USBTMC Instrument.
    public enum Error: Swift.Error {
        /// When looking for USB endpoints to send messages through, no alternative setting could be found that has compliant endpoints
        /// Or an altsetting claims to have endpoints it doesn't have.
        case couldNotFindEndpoint
        
        ///The terminator given could not be accepted by the device
        case invalidTerminator
        
        /// When attempting to encode a user given string with a user given encoding, an error occurs
        case cannotEncode
        
        /// The given VISA string was not understood
        case invalidVisa
    }
}

extension USBTMCInstrument.Error {
    public var localizedDescription: String {
        switch self {
        case .couldNotFindEndpoint:
            return "Could not find at least one required endpoint that satisfies requirements"
        case .invalidTerminator:
            return "Invalid terminator given"
        case .cannotEncode:
            return "Could not encode given string with given encoding"
        case .invalidVisa:
            return "The given visa string could not be interpreted"
        }
    }
}

extension InstrumentManager {
    public func instrumentAt(vendorID: Int, productID: Int, serialNumber: String?) throws -> USBTMCInstrument {
        try USBTMCInstrument(vendorID: vendorID, productID: productID, serialNumber: serialNumber)
    }
}
