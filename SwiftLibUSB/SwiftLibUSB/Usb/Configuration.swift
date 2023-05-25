//
//  Configuration.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/25/23.
//

import Foundation

class Configuration {
    var descriptor: UnsafeMutablePointer<libusb_config_descriptor>
    
    init(_ device: Device, index: UInt8) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_config_descriptor(device.device, index, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        descriptor = desc!
    }
    
    init(_ device: Device) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_active_config_descriptor(device.device, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        descriptor = desc!
    }
    
    deinit {
        libusb_free_config_descriptor(descriptor)
    }
}