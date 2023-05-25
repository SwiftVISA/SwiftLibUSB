//
//  Device.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

/// Class representing an available USB device
///
/// Communicating with the device requires opening the device
struct Device: Hashable {
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.device == rhs.device
    }
    
    func hash(into hasher: inout Hasher) {
        device.hash(into: &hasher)
    }
    
    var device: OpaquePointer
    var descriptor: libusb_device_descriptor
    var configurations: [Configuration]

    var productId: Int {
        get {
            Int(descriptor.idProduct)
        }
    }
    
    var vendorId: Int {
        get {
            Int(descriptor.idVendor)
        }
    }
    
    var displayName: String {
        get {
            return "Vendor: \(vendorId) Product: \(productId)"
        }
    }
    
    init(pointer: OpaquePointer) throws {
        device = pointer
        descriptor = libusb_device_descriptor()
        let error = libusb_get_device_descriptor(device, &descriptor)
        if error < 0 {
            throw USBError.from(code: error)
        }
        configurations = []
        for i in 0...descriptor.bNumConfigurations {
            do {
                try configurations.append(Configuration(self, index: i))
            } catch {} // Ignore configurations with errors
        }
    }

    func openHandle() throws -> DeviceHandle {
        return try DeviceHandle(device: self)
    }
}