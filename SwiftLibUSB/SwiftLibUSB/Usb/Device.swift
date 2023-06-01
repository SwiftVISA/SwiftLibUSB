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
    var device: OpaquePointer
    /// A C struct containing information about the device
    var descriptor: libusb_device_descriptor
    /// Each device has "configurations" which manage their operation.
    var configurations: [Configuration]
    
    var handle: OpaquePointer
    
    init(pointer: OpaquePointer) throws {
        device = pointer
        descriptor = libusb_device_descriptor()
        var error = libusb_get_device_descriptor(device, &descriptor)
        if error < 0 {
            throw USBError.from(code: error)
        }
        var base_handle: OpaquePointer? = nil
        error = libusb_open(device, &base_handle)
        if error < 0 {
            throw USBError.from(code: error)
        }
        handle = base_handle!
        configurations = []
        for i in 0..<descriptor.bNumConfigurations {
            do {
                try configurations.append(Configuration(self, index: i))
            } catch {} // Ignore configurations with errors
        }
    }
    /// Compares devices by their internal pointer. Two device classes that point to the same libUSB device are considered the same
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.device == rhs.device
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
        let returnCode = libusb_get_string_descriptor_ascii(handle, descriptor.iProduct, &buffer, Int32(size))
        
        // Check if there is an error when filling the buffer with the name
        if(returnCode <= 0){
            return "error getting name: \(USBError.from(code: returnCode).localizedDescription)"
        }
        
        return String(bytes: buffer, encoding: .ascii) ?? "Vendor: \(vendorId) Product: \(productId)"
    }

    /// A hash representation of the device
    func hash(into hasher: inout Hasher) {
        device.hash(into: &hasher)
    }

    deinit {
        libusb_close(handle)
    }
}
