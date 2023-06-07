//
//  Device.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

/// Class representing an available USB device.
/// Communicating with the device requires opening the device
class Device: Hashable {
    /// The device as libUSB understands it. It is managed as a pointer
    var device: DeviceRef
    /// A C struct containing information about the device
    var descriptor: libusb_device_descriptor
    /// Each device has "configurations" which manage their operation.
    var configurations: [Configuration]
    
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
    /// Compares devices by their internal pointer. Two device classes that point to the same libUSB device are considered the same
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.device.raw_device == rhs.device.raw_device
    }
    
    /// Get the product ID of the device
    /// Can be accessed prior to a connection
    ///  - Returns: An integer representing the product ID
    var productId: Int {
        get {
            Int(descriptor.idProduct)
        }
    }
    
    /// Simple getter for the vendor ID of the device
    /// Can be accessed prior to connection
    ///  - Returns: An integer representing the vendor ID
    var vendorId: Int {
        get {
            Int(descriptor.idVendor)
        }
    }
    
    /// Serial number of the device, useful in identifying a device if there are multiple with the same product and vendor id
    /// Returns a blank string if the serial number cannot be found
    var serialCode: String {
        get{
            if(descriptor.iSerialNumber == 0){
                return ""
            }
            let size = 256;
            var buffer: [UInt8] = Array(repeating: 0, count: size)
            let returnCode = libusb_get_string_descriptor_ascii(device.raw_handle, descriptor.iSerialNumber, &buffer, Int32(size))
            if(returnCode <= 0){
                return ""
            }
            return String(bytes: buffer, encoding: .ascii) ?? ("")
        }
    }
    
    /// Gets a human readable version of a device by indicating both the vendor and product id
    /// Together they form a primary key that can uniquely indentify the connected device
    /// - Returns: A string in the format "Vendor: [vendorID] Product: [productID]"
    var displayName: String {
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
    
    
    func sendControlTransfer(
        bmRequestTypeL: UInt8,
        bRequest: UInt8,
        wValue: UInt16,
        wIndex: UInt16,
        data: Data,
        wLength: UInt16,
        timeout: UInt32
    ) throws -> Data {
        var charArrayData = [UInt8](data)
        let returnVal = libusb_control_transfer(device.raw_handle,bmRequestTypeL,bRequest,wValue,wIndex,&charArrayData,wLength,timeout)
        if(returnVal < 0){
            throw USBError.from(code: returnVal)
        }
        return Data(charArrayData)
    }
    
    func sendControlTransfer(
        direction: Direction,
        type: LibUSBControlType,
        recipeint: LibUSBRecipient,
        bRequest: UInt8,
        wValue: UInt16,
        wIndex: UInt16,
        data: Data,
        wLength: UInt16,
        timeout: UInt32
    ) throws -> Data {
        // Fill in bits of request Type
        var requestType : UInt8 = (Direction.In.val << 5)
        requestType += (LibUSBControlType.Class.val << 7)
        requestType += (LibUSBRecipient.Interface.val << 0)
        
        // Make the control transfer
        return try sendControlTransfer(bmRequestTypeL: requestType, bRequest: bRequest, wValue: wValue, wIndex: wIndex, data: data, wLength: wLength, timeout: timeout)
    }
    
    /// A hash representation of the device
    func hash(into hasher: inout Hasher) {
        device.raw_device.hash(into: &hasher)
    }
}

/// Internal class for managing lifetimes
///
/// This ensures the libUSB context isn't freed until all devices have been closed.
internal class DeviceRef {
    let context: ContextRef
    let raw_device: OpaquePointer
    let raw_handle: OpaquePointer
    
    init(context: ContextRef, device: OpaquePointer) throws {
        self.context = context
        raw_device = device
        var base_handle: OpaquePointer? = nil
        let error = libusb_open(device, &base_handle)
        if error < 0 {
            throw USBError.from(code: error)
        }
        raw_handle = base_handle!
    }
    
    deinit {
        libusb_close(raw_handle)
    }
}


