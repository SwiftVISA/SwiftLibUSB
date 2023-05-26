//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 5/25/23.
//

import Foundation

/// A setting that controls how endpoints behave. This must be activated using `setActive` before sending or receiving data.
class AltSetting {
    var descriptor: libusb_interface_descriptor
    var endpoints: [Endpoint]
    var device: Device
    
    init(pointer : libusb_interface_descriptor, device: Device) {
        descriptor = pointer
        self.device = device
        
        endpoints = []
        for i in 0..<descriptor.bNumEndpoints {
            endpoints.append(Endpoint(pointer: descriptor.endpoint[Int(i)], device: device))
        }
    }
    
    /// A code describing what kind of communication this setting handles.
    var interfaceClass: ClassCode {
        get {
            ClassCode.from(code: UInt32(descriptor.bInterfaceClass))
        }
    }
    
    /// If the `interfaceClass` has subtypes, this gives that type.
    var interfaceSubClass: Int {
        get {
            Int(descriptor.bInterfaceSubClass)
        }
    }
    
    /// If the `interfaceClass` and `interfaceSubClass` has protocols, this gives the protocol
    var interfaceProtocol: Int {
        get {
            Int(descriptor.bInterfaceProtocol)
        }
    }
    
    deinit {
        
    }
    
    /// Makes the setting active.
    ///
    /// This must be done before sending data through the endpoints. The parent configuration and interface should have been activated and claimed first.
    ///
    /// - throws: a USBError if activating the setting fails
    /// * `.notFound` if the interface was not claimed
    /// * `.noDevice` if the device was disconnected
    func setActive() throws {
        let error = libusb_set_interface_alt_setting(device.handle?.handle, Int32(descriptor.bInterfaceNumber), Int32(descriptor.bAlternateSetting))
        if error < 0 {
            throw USBError.from(code: error)
        }
    }
}
