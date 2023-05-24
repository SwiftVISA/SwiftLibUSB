//
//  Context.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

class Context {
    var libContext: OpaquePointer
    
    init() throws {
        var context: OpaquePointer? = nil;
        let error = withUnsafeMutablePointer(to: &context, libusb_init)
        if (error == 0) {
            libContext = context.unsafelyUnwrapped
        } else {
            throw USBError.from(code: error)
        }
    }
    
    deinit {
        libusb_exit(libContext)
    }
    
    func getDeviceList() throws -> DeviceList {
        return try DeviceList(context: libContext)
    }
}
