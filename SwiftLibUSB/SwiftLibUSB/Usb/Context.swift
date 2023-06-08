//
//  Context.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

///Description
///All libUSB calls exist in some "context". While many of these methods allow for using
///a null context, using a context is preferred. This class handles both the initialization and closing of contexts automatically.
/// - Throws: USBError on initialization if libUSB cannot initialize the context

public class Context {
    var context: ContextRef
    var devices: [Device]
    
    /// Initializes libUSB
    /// - throws: A USBError if creating the context fails
    init() throws {
        try context = ContextRef()
        var deviceList: UnsafeMutablePointer<OpaquePointer?>? = nil
        let size = libusb_get_device_list(context.context, &deviceList)
        if size < 0 {
            throw USBError.from(code: Int32(size))
        }
        
        devices = []
        for i in 0..<size {
            if let dev = deviceList?[i] {
                devices.append(try Device(context: context, pointer: dev))
            }
        }

        libusb_free_device_list(deviceList, 1) // The 1 makes libUSB decrement the reference count on the devices,
                                               // which is fine because the Device handles keep them alive.
    }
}

/// Internal class for managing the LibUSB context
///
/// This ensures the context won't be freed until all devices created from it are freed
internal class ContextRef {
    let context: OpaquePointer
    
    init() throws {
        var context: OpaquePointer? = nil;
        let error = libusb_init(&context)
        if (error == 0) {
            self.context = context!
        } else {
            throw USBError.from(code: error)
        }
    }
    
    deinit {
        libusb_exit(context)
    }
}
