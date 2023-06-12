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
        let error = libusb_get_device_descriptor(device.raw_device, &descriptor)
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
        lhs.device.raw_device == rhs.device.raw_device
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
    public var serialCode: String {
        get {
            if(descriptor.iSerialNumber == 0){
                return ""
            }
            let size = 256;
            var buffer: [UInt8] = Array(repeating: 0, count: size)
            let returnCode = libusb_get_string_descriptor_ascii(device.raw_handle, descriptor.iSerialNumber, &buffer, Int32(size))
            if(returnCode <= 0){
                return ""
            }
            // Buffer is now filled with the bytes of the serial code. Convert to string
            let asciibuffer = String(bytes: buffer, encoding: .ascii)  ?? ("")
            // If we cannot encode, we use a blank string, we then remove all extra bytes on the end
            return String(asciibuffer.prefix(Int(returnCode)))
            
        }
    }
    
    /// Get a human readable version descriptor of a device by indicating both its vendor and product IDs. Together they form a primary key that can uniquely indentify the connected device.
    /// - Returns: A string in the format "Vendor: [vendorID] Product: [productID]"
    public var displayName: String {
        // If the index is 0 give the name as indicated
        if(descriptor.iProduct == 0){
            return "Vendor: \(vendorId) Product: \(productId)"
        }
        
        // Make a buffer for the name of the device
        let size = 256;
        var buffer: [UInt8] = Array(repeating: 0, count: size)
        let returnCode = libusb_get_string_descriptor_ascii(device.raw_handle, descriptor.iProduct, &buffer, Int32(size))
        
        // Check if there is an error when filling the buffer with the name
        if(returnCode <= 0){
            return "error getting name: \(USBError.from(code: returnCode).localizedDescription)"
        }
        
        return String(bytes: buffer, encoding: .ascii) ?? "Vendor: \(vendorId) Product: \(productId)"
    }
    
    /// Name of the manufacturer of the device
    /// If no name can be found, the name is blank
    /// Retrieved from the iManufacturer index
    public var manufacturerName: String {
        get {
            return ""
        }
    }
    
    /// A string description of this product.
    /// If this description was not provided by the device, this string is empty
    public var productName: String {
        get {
            return ""
        }
    }
    
    /// The device's class, broadly describes what type of device this is
    /// These classes are described in more detail in the ``ClassCode`` enumerable
    /// This is derived from the bDeviceClass value
    public var deviceClass: ClassCode {
        get {
            return ClassCode.from(code: UInt32(descriptor.bDeviceClass))
        }
    }
    
    /// Each class has a variety of subclasses that describe the device's purpose in more detail.
    /// These codes are specific to the class of the device, which is stored in the ``deviceClass`` value
    /// This is derived from the bDeviceSubClass value
    public var deviceSubclass: Int {
        get {
            Int(descriptor.bDeviceClass)
        }
    }
    
    /// Each class can be described by their class (``deviceClass``), Sub class (``deviceSubclass``) and their protocol.
    /// The protocol is specific to the subclass of the device.
    public var deviceProtocol: Int {
        get {
            Int(descriptor.bDeviceProtocol)
        }
    }
    
    /// The raw verson value of the USB specifications used by this device
    /// This value is not useful practically. For the version in a human readable form, use ``version``
    /// Represented as a 4 digit hex value where the period of the version lies between the 2nd and 3rd digit
    /// For example,
    /// - 512: is 0x0200 in hex, which is interpreted as USB version 2.0
    /// - 272: is 0x0110 in hex, which is interpreted as USB 1.1
    ///
    public var usbVersionVal: Int {
        get {
            Int(descriptor.bcdUSB)
        }
    }
    
    /// The version of the USB specifications used by this device
    /// written as a human-readable string in the form "[major version].[minor version][patch]"
    /// The versions do support hex characters. idk why
    public var usbVersion: String {
        get {
            let hexString = String(NSString(format:"%2X", usbVersionVal))
            if(hexString.count == 1){
                return "0.0"+hexString
            }
            return hexString.prefix(hexString.count-2) + "." + hexString.suffix(2)
        }
    }
    
    /// The maximum size of packets for the 0th endpoint.
    /// The endpoint at index 0 is treated seperatly and managed by the device
    /// This is measured in bytes
    public var packetSizeEndpoint0: Int {
        get {
            Int(descriptor.bMaxPacketSize0)
        }
    }
    
    /// Close the connection to the device
    ///
    /// No communication can be done with the device while it is closed. It can be reopened by calling
    /// ``reopen``. This does nothing if the device is already closed.
    public func close() {
        device.close()
    }
    
    /// Reopen the connection to the device
    ///
    /// Use this to restart a connection that has been closed using ``close``. This does nothing if the device was already open.
    /// - Throws:
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
        let returnVal = libusb_control_transfer(device.raw_handle,
                                                requestType,request,value,index,
                                                &charArrayData,length,timeout)
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
        return try sendControlTransfer(requestType: requestType, request: request,
                                       value: value, index: index, data: data, length: length,
                                       timeout: timeout)
    }
    
    /// A hash representation of the device
    public func hash(into hasher: inout Hasher) {
        device.raw_device.hash(into: &hasher)
    }
}

/// Internal class for managing lifetimes
///
/// This ensures the libUSB context is not freed until all the devices have been closed.
internal class DeviceRef {
    let context: ContextRef
    let raw_device: OpaquePointer
    var raw_handle: OpaquePointer?
    var open: Bool
    
    init(context: ContextRef, device: OpaquePointer) throws {
        self.context = context
        raw_device = device
        raw_handle = nil
        let error = libusb_open(device, &raw_handle)
        if error < 0 {
            throw USBError.from(code: error)
        }
        open = raw_handle != nil
    }
    
    func close() {
        if open {
            libusb_close(raw_handle)
            open = false
        }
    }
    
    func reopen() throws {
        if !open {
            let error = libusb_open(raw_device, &raw_handle)
            if error < 0 {
                throw USBError.from(code: error)
            }
            open = raw_handle != nil
        }
    }
    
    deinit {
        if open {
            libusb_close(raw_handle)
        }
    }
}


