//
//  DeviceList.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

class DeviceList {
    var devices: UnsafeMutablePointer<OpaquePointer?>
    let startIndex: Int = 0
    var endIndex: Int
    
    init(context: OpaquePointer) throws {
        var inner_devices: UnsafeMutablePointer<OpaquePointer?>? = nil
        let size = withUnsafeMutablePointer(to: &inner_devices) { (dp) -> Int in libusb_get_device_list(context, dp) }
        if size < 0 {
            throw USBError.from(code: Int32(size))
        }
        
        devices = inner_devices.unsafelyUnwrapped
        endIndex = size
    }
    
    deinit {
        libusb_free_device_list(devices, 1)
    }
}

extension DeviceList: Collection {
    func index(after i: Int) -> Int {
        i + 1
    }
    
    subscript(position: Int) -> Device? {
        if let dev_pt = devices[position] {
            do {
                return try Device(pointer: dev_pt)
            } catch {
                print("Error in getting device")
                return nil
            }
        }
        return nil
    }
}
