//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 5/25/23.
//

import Foundation

class AltSetting {
    var descriptor: libusb_interface_descriptor
    var endpoints: [Endpoint]
    
    init(pointer : libusb_interface_descriptor) {
        descriptor = pointer
        
        endpoints = []
        for i in 0...descriptor.bNumEndpoints {
            endpoints.append(Endpoint(pointer: descriptor.endpoint[Int(i)]))
        }
    }
    
    var interfaceClass: ClassCode {
        get {
            ClassCode.from(code: UInt32(descriptor.bInterfaceClass))
        }
    }
    
    var interfaceSubClass: Int {
        get {
            Int(descriptor.bInterfaceSubClass)
        }
    }
    
    var interfaceProtocol: Int {
        get {
            Int(descriptor.bInterfaceProtocol)
        }
    }
    
    deinit {
        
    }
}
