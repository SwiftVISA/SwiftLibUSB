//
//  DeviceList.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

class DeviceList {
    var devices: [Device]
    var pointer: UnsafeMutablePointer<OpaquePointer?>?
    let startIndex: Int = 0
    var endIndex: Int
    
    init(context: OpaquePointer) throws {
        pointer = nil
        let size = libusb_get_device_list(context, &pointer)
        if size < 0 {
            throw USBError.from(code: Int32(size))
        }
        
        devices = []
        for i in 0...size {
            if let dev = pointer?[i] {
                devices.append(try Device(pointer: dev))
            }
        }
        endIndex = size
    }
    
    deinit {
        libusb_free_device_list(pointer, 1)
    }
}
