//
//  DeviceList.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

/// A device list is a concept in libUSB that manages a list of devices. Each context has one device list which stores all of the connected devices
/// DeviceList automatically creates and frees libUSB's device list as required.
class DeviceList {
    var devices: [Device]
    var pointer: UnsafeMutablePointer<OpaquePointer?>?
    
    init(context: OpaquePointer) throws {
        pointer = nil
        let size = libusb_get_device_list(context, &pointer)
        if size < 0 {
            throw USBError.from(code: Int32(size))
        }
        
        devices = []
        for i in 0..<size {
            if let dev = pointer?[i] {
                devices.append(try Device(pointer: dev))
            }
        }
    }
    
    deinit {
        libusb_free_device_list(pointer, 1) // we pass the pointer to the device we are releasing and a 1 to indicate we are decrementing the reference count of the devices
    }
}
