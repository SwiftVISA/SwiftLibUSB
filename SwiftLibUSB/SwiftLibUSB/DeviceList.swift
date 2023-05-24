//
//  DeviceList.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

class DeviceList {
    var devices: UnsafeMutablePointer<OpaquePointer?>
    var len: Int
    
    init(context: OpaquePointer) throws {
        var inner_devices: UnsafeMutablePointer<OpaquePointer?>? = nil
        let size = withUnsafeMutablePointer(to: &inner_devices) { (dp) -> Int in libusb_get_device_list(context, dp) }
        if size < 0 {
            throw USBError.from(code: Int32(size))
        }
        devices = inner_devices.unsafelyUnwrapped
        len = size
    }
}
