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
    
    var handle: DeviceHandle?
    
    init(pointer: OpaquePointer) throws {
        device = pointer
        descriptor = libusb_device_descriptor()
        let error = libusb_get_device_descriptor(device, &descriptor)
        if error < 0 {
            throw USBError.from(code: error)
        }
        configurations = []
        for i in 0..<descriptor.bNumConfigurations {
            do {
                try configurations.append(Configuration(self, index: i))
            } catch {} // Ignore configurations with errors
        }
        handle = nil
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
        get {
            return "Vendor: \(vendorId) Product: \(productId)"
        }
    }

    /// Before a device can be used, a handle for that device must be opened. Each call to open handle opens one such handle
    /// Only one handle should be opened per device
    /// - Returns: The device handle class that will manage communication with this device.
    func openHandle() throws -> DeviceHandle {
        let createdHandle = try DeviceHandle(device: self)
        handle = createdHandle
        return createdHandle
    }
    
    /// A hash representation of the device
    func hash(into hasher: inout Hasher) {
        device.hash(into: &hasher)
    }
}
