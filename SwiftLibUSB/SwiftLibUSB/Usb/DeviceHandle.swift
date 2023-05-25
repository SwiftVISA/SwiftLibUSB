//
//  DeviceHandle.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

/// Each device has one open handle when the device is connected. When a device handle is initlilized, the device is opened
/// Device handle manages both the opening and the closing of the handle automatically
class DeviceHandle {
    /// The pointer that libUSB understands as the actual handle
    var handle: OpaquePointer
    /// The device this handle belongs to
    var device: Device
    
    init(device: Device) throws {
        var base_handle: OpaquePointer? = nil
        let error = libusb_open(device.device, &base_handle)
        if error < 0 {
            throw USBError.from(code: error)
        }
        handle = base_handle!
        self.device = device
    }

    deinit {
        libusb_close(handle)
    }
}
