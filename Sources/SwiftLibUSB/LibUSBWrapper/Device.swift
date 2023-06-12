//
//  Device.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation
import Usb

/// Class representing an available USB device.
/// Communicating with the device requires opening the device.
public class Device: Hashable {
    /// The device as libUSB understands it. It is managed as a pointer
    private var device: DeviceRef
    /// A C struct containing information about the device
    private var descriptor: libusb_device_descriptor
    /// Each device has "configurations" which manage their operation.
    public var configurations: [Configuration]
    
    /// Contruct a device from a context and a pointer to the device
    /// - Parameters:
    ///   - context: The associated context class
    ///   - pointer: The pointer to the device
    /// - Throws:  ``USBError`` if libUSB returns an error
    init(context: ContextRef, pointer: OpaquePointer) throws {
        try device = DeviceRef(context: context, device: pointer)
        
        descriptor = libusb_device_descriptor()
        let error = libusb_get_device_descriptor(device.rawDevice, &descriptor)
        if error < 0 {
            throw USBError.from(code: error)
        }

        configurations = []
        for i in 0..<descriptor.bNumConfigurations {
            do {
                try configurations.append(Configuration(device, index: i))
            } catch {} // Ignore configurations with errors
        }
    }
    
    /// Compare devices by their internal pointer. Two device classes that point to the same libUSB device are considered the same
    public static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.device.rawDevice == rhs.device.rawDevice
    }
    
    /// The product ID of the device.
    /// Can be accessed prior to a connection.
    ///  - Returns: An integer representing the product ID
    public var productId: Int {
        get {
            Int(descriptor.idProduct)
        }
    }
    
    /// The vendor ID of the device.
    /// Can be accessed prior to connection.
    ///  - Returns: An integer representing the vendor ID
    public var vendorId: Int {
        get {
            Int(descriptor.idVendor)
        }
    }
    
    /// The serial number of the device. Useful in identifying a device if there are multiple with the same product and vendor ID.
    ///  - Returns: A string representing the serial number of the device, or a blank string if the serial number cannot be found
    public var serialNumber: String {
        device.getStringDescriptor(index: descriptor.iSerialNumber) ?? ""
    }
    
    /// Get a human readable version descriptor of a device by indicating both its vendor and product IDs. Together they form a primary key that can uniquely indentify the connected device.
    /// - Returns: A string in the format "Vendor: [vendorID] Product: [productID]"
    public var displayName: String {
        device.getStringDescriptor(index: descriptor.iProduct) ?? "Vendor: \(vendorId) Product: \(productId)"
    }
    
    /// Close the connection to the device
    ///
    /// No communication can be done with the device while it is closed. It can be reopened by calling
    /// ``reopen()``. This does nothing if the device is already closed.
    public func close() {
        device.close()
    }
    
    /// Reopen the connection to the device
    ///
    /// Use this to restart a connection that has been closed using ``close()``. This does nothing if the device was already open.
    /// - Throws: a ``USBError``
    ///    * ``USBError/noMemory`` if the device handle could not be allocated
    ///    * ``USBError/access`` if the user has insufficient permissions
    ///    * ``USBError/noDevice`` if the device was disconnected
    public func reopen() throws {
        try device.reopen()
    }
    
    /// Send a control transfer to a device.
    /// - Parameters:
    ///   - requestType: The request type for the setup packet
    ///   - request: The request for the setup packet
    ///   - value: The value for the setup packet
    ///   - index: The index for the setup packet
    ///   - data: The data sent in the control transfer
    ///   - length: The length of the data to transfer
    ///   - timeout: Timeout (in milliseconds) that this function should wait before stopping due to no response being received. For an unlimited timeout, use value 0.
    /// - Returns: The data sent back from the device
    /// - Throws: a ``USBError`` if libUSB encounters an internal error
    public func sendControlTransfer(
        requestType: UInt8,
        request: UInt8,
        value: UInt16,
        index: UInt16,
        data: Data,
        length: UInt16,
        timeout: UInt32
    ) throws -> Data {
        var charArrayData = [UInt8](data)
        let returnVal = libusb_control_transfer(
            device.rawHandle,
            requestType,
            request,
            value,
            index,
            &charArrayData,
            length,
            timeout)
        if returnVal < 0 {
            throw USBError.from(code: returnVal)
        }
        return Data(charArrayData)
    }
    
    /// Send a control transfer to a device.
    /// - Parameters:
    ///   - direction: The direction of the transfer
    ///   - type: The request type
    ///   - recipient: Specifies what is receiving the request
    ///   - request: The request for the setup packet
    ///   - value: The value for the setup packet
    ///   - index: The index for the setup packet
    ///   - data: The data sent in the control transfer
    ///   - length: The length of the data to transfer
    ///   - timeout: Timeout (in milliseconds) that this function should wait before stopping due to no response being received. For an unlimited timeout, use value 0.
    ///- Returns: The data sent back from the device
    ///- Throws: a ``USBError`` if libUSB encounters and internal error
    public func sendControlTransfer(
        direction: Direction,
        type: LibUSBControlType,
        recipient: LibUSBRecipient,
        request: UInt8,
        value: UInt16,
        index: UInt16,
        data: Data,
        length: UInt16,
        timeout: UInt32
    ) throws -> Data {
        // Fill in bits of request Type
        var requestType : UInt8 = direction.val << 5
        requestType += type.val << 7
        requestType += recipient.val << 0
        
        // Make the control transfer
        return try sendControlTransfer(
            requestType: requestType,
            request: request,
            value: value,
            index: index,
            data: data,
            length: length,
            timeout: timeout)
    }
    
    /// A hash representation of the device
    public func hash(into hasher: inout Hasher) {
        device.rawDevice.hash(into: &hasher)
    }
}

/// Internal class for managing lifetimes
///
/// This ensures the libUSB context is not freed until all the devices have been closed.
internal class DeviceRef {
    let context: ContextRef
    let rawDevice: OpaquePointer
    var rawHandle: OpaquePointer?
    var open: Bool
    
    init(context: ContextRef, device: OpaquePointer) throws {
        self.context = context
        rawDevice = device
        rawHandle = nil
        let error = libusb_open(device, &rawHandle)
        if error < 0 {
            throw USBError.from(code: error)
        }
        open = rawHandle != nil
    }
    
    func close() {
        if open {
            libusb_close(rawHandle)
            open = false
        }
    }
    
    func reopen() throws {
        if !open {
            let error = libusb_open(rawDevice, &rawHandle)
            if error < 0 {
                throw USBError.from(code: error)
            }
            open = rawHandle != nil
        }
    }
    
    func getStringDescriptor(index: UInt8) -> String? {
        if index == 0 {
            return nil
        }
        
        let size = 256;
        var buffer: [UInt8] = Array(repeating: 0, count: size)
        let returnValue = libusb_get_string_descriptor_ascii(
            rawHandle,
            index,
            &buffer,
            Int32(size))
        
        // If the return value is negative, there was an error. If positive, it's the number
        // of bytes in the string.
        if returnValue <= 0 {
            return nil
        }
        
        return String(bytes: buffer[..<Int(returnValue)], encoding: .ascii)
    }
    
    deinit {
        if open {
            libusb_close(rawHandle)
        }
    }
}


