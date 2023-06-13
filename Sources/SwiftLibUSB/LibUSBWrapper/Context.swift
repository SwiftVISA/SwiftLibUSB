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
/// Creating a `Context` should be the first thing a user of this library does. A `Context` manages the list of ``Device``s,
/// which can then be searched to find the one you want to communicate with.
///
/// Once an appropriate ``Device`` has been found, it is safe to drop the reference to the `Context`. The ``Device``
/// will that resources are cleaned up properly. (This is true of all classes in the hierarchy; they don't need to be kept beyond
/// where they are used.)
///
/// A Context stores the list of devices connected to the host at the time it was created. Hotplug detection is not yet supported.
/// Multiple Contexts can be created, and they will each have their own copy of the ``Device`` object for each physical device.
/// Communicating with a device that is already being used by a ``Device`` from another Context is likely to cause issues.
public class Context {
    
    /// The class that manages the pointer to the context. Extra references to this generally should not be made as they may impede deconstruction
    private var context: ContextRef
    
    /// All devices that were connected to the host when the context was initialized.
    ///
    /// Hotplug support is available in libusb, but has not been added to this class. To get an updated list of devices,
    /// create a new ``Context``.
    public var devices: [Device]
    
    /// Creates a Context and builds the list of ``devices``.
    ///
    /// This list contains the devices that are connected at the time it is created.
    /// - throws: A ``USBError`` if creating the context fails of if opening any device fails.
    public init() throws {
        // Create the class that holds the reference to the context pointer
        try context = ContextRef()
        
        // Create a pointer that will eventually point to the device list
        var deviceList: UnsafeMutablePointer<OpaquePointer?>? = nil
        
        // Give the pointer to libUSB, so that it can be made to point to the device list
        let size = libusb_get_device_list(context.context, &deviceList)
        
        // The returned value from libUSB is negative if there was a problem connecting
        if size < 0 {
            throw USBError(rawValue: Int32(size)) ?? USBError.other
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
            throw USBError(rawValue: error) ?? USBError.other
        }
    }
    
    deinit {
        libusb_exit(context)
    }
}
