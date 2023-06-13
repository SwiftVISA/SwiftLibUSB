//
//  Context.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation
import Usb

/// An independent session for managing devices
///
/// Contexts allow different users of libusb to manage devices independently.
public class Context {
    
    /// The class that manages the pointer to the context. Extra references to this generally should not be made as they may impede deconstruction
    private var context: ContextRef
    
    /// All devices that were connected to the host when the context was initialized.
    ///
    /// Hotplug support is available in libusb, but has not been added to this class. To get an updated list of devices,
    /// create a new ``Context``.
    public var devices: [Device]
    
    /// Initialize libUSB, and create the device list.
    /// - throws: A ``USBError`` if creating the context fails
    public init() throws {
        // Create the class that holds the reference to the context pointer
        try context = ContextRef()
        
        // Create a pointer that will eventually point to the device list
        var deviceList: UnsafeMutablePointer<OpaquePointer?>? = nil
        
        // Give the pointer to libUSB, so that it can be made to point to the device list
        let size = libusb_get_device_list(context.context, &deviceList)
        
        // The returned value from libUSB is negative if there was a problem connecting
        if size < 0 {
            throw USBError.from(code: Int32(size))
        }
        
        // Fill the devices variables with the information in the device list
        devices = []
        for i in 0..<size {
            // For each device, we attempt to get the pointer to it from the returned deviceList
            if let dev = deviceList?[i] {
                // Create and add the new device
                devices.append(try Device(context: context, pointer: dev))
            }
        }

        libusb_free_device_list(deviceList, 1) // The 1 makes libUSB decrement the reference count on the devices, which is fine because the Device handles keep them alive.
    }
}

/// An internal class for managing the libUSB context
///
/// This ensures the context will not be freed until all devices created from it are freed. It has the responsibility of managing the actual pointer that libUSB understands as the context. This class is internal and should not be used directly. It is designed to be only used by ``Context``.
/// To ensure proper functionality, extra references to the context reference classes should generally not be made, as they must be deconstructed in a particular order.
internal class ContextRef {
    /// This value is the context as libUSB understands it. It must be initialized during construction and deinitialized during deconstruction.
    let context: OpaquePointer
    
    /// Create the internal context reference class
    ///  - Throws: A ``USBError`` if libUSB returns an error code while initializing
    init() throws {
        var context: OpaquePointer? = nil;
        let error = libusb_init(&context)
        if error == 0 {
            self.context = context!
        } else {
            throw USBError.from(code: error)
        }
    }
    
    deinit {
        libusb_exit(context)
    }
}
