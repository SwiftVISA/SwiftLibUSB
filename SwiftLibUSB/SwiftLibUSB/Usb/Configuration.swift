//
//  Configuration.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/25/23.
//

import Foundation

/// Each device has at least 1 configuration, often more. libUSB keeps track of these with libusb config descriptors.
/// Each instance manages 1 of these descriptors, inclduing managing the getting and freeing of this discriptor
class Configuration {
    var descriptor: UnsafeMutablePointer<libusb_config_descriptor>
    var interfaces : [Interface]
    
    init(_ device: Device, index: UInt8) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_config_descriptor(device.device, index, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        descriptor = desc!
        interfaces = []
        
        getInterfaces()
    }
    
    init(_ device: Device) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_active_config_descriptor(device.device, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        descriptor = desc!
        interfaces = []
        
        getInterfaces()
    }
    
    func getInterfaces(){
        let size = Int(descriptor.pointee.bNumInterfaces)
        for i in 0...size {
            if var inf = descriptor.pointee.interface?[i] {
                interfaces.append(Interface(pointer: &inf))
            }
        }
    }
    
    deinit {
        libusb_free_config_descriptor(descriptor)
    }
}
