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
        var error = libusb_get_device_descriptor(device.device, &descriptor)
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
        lhs.device.device == rhs.device.device
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

    /// A hash representation of the device
    func hash(into hasher: inout Hasher) {
        device.device.hash(into: &hasher)
    }
}

/// Internal class for managing lifetimes
///
/// This ensures the libUSB context isn't freed until all devices have been closed.
internal class DeviceRef {
    let context: ContextRef
    let device: OpaquePointer
    let handle: OpaquePointer
    
    init(context: ContextRef, device: OpaquePointer) throws {
        self.context = context
        self.device = device
        var base_handle: OpaquePointer? = nil
        let error = libusb_open(device, &base_handle)
        if error < 0 {
            throw USBError.from(code: error)
        }
        handle = base_handle!
    }
    
    deinit {
        libusb_close(handle)
    }
}
