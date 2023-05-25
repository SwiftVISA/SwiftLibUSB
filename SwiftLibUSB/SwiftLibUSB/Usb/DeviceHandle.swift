//
//  DeviceHandle.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

class DeviceHandle {
    var handle: OpaquePointer

    init(device: Device) throws {
        var base_handle: OpaquePointer? = nil
        let error = libusb_open(device.device, &base_handle)
        if error < 0 {
            throw USBError.from(code: error)
        }
        handle = base_handle!
    }

    deinit {
        libusb_close(handle)
    }
}
