//
//  Context.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

///Description
///All libUSB calls exist in some "context". While many of these methods allow for using
///a null context, using a context is prefered. This class handles both the initilisation and closing of contexts automatically.
/// - Throws: USBError on initilisation if libUSB cannot initlise the context

class Context {
    var libContext: OpaquePointer // The actual context as libUSB understands it
    
    init() throws {
        var context: OpaquePointer? = nil;
        let error = libusb_init(&context)
        if (error == 0) {
            libContext = context!
        } else {
            throw USBError.from(code: error)
        }
    }
    
    deinit {
        libusb_exit(libContext)
    }
    
    
    /// This is a getter for the DeviceList of the libUSB context. This step gets all visibile USB devices so that they can be connected to
    /// - Throws: libUSB error if creating the devicelist for this context results in an error
    /// - Returns: a DeviceList that stores the devices accessable in this context
    func getDeviceList() throws -> DeviceList {
        return try DeviceList(context: libContext)
    }
}
