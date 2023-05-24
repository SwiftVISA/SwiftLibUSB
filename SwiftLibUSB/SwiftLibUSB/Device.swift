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
class Device {
    var device: OpaquePointer
    var descriptor: libusb_device_descriptor
    
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
    
    init(pointer: OpaquePointer) throws {
        device = pointer
        descriptor = libusb_device_descriptor()
        let error = withUnsafeMutablePointer(to: &descriptor) { (dp) -> Int32 in libusb_get_device_descriptor(device, dp)}
        if error < 0 {
            throw USBError.from(code: error)
        }
    }
}
