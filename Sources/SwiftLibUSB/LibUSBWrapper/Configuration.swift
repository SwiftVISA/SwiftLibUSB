//
//  Configuration.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/25/23.
//

import Foundation
import Usb

/// Each device has at least one configuration, often more. LibUSB keeps track of these with `libusb_config_descriptor`s.
/// Each instance manages one of these descriptors, including managing the getting and freeing of this descriptor.
public class Configuration: Hashable {
    /// An array of Interfaces
    public var interfaces: [Interface]
    /// An internal class to manage the lifetime of the configuration
    private var config: ConfigurationRef
    
    /// Load the configuration with the given index
    ///
    /// - throws: A ``USBError`` if getting the configuration fails
    /// * `.notFound` if the index is invalid.
    init(_ device: DeviceRef, index: UInt8) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_config_descriptor(device.raw_device, index, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        config = ConfigurationRef(device: device, descriptor: desc!)
        interfaces = []
        getInterfaces()
    }
    
    /// Get the descriptor of the active configuration.
    ///
    /// - throws: A ``USBError`` if getting the configuration fails
    /// * `.notFound` if the device is not configured
    init(_ device: DeviceRef) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_active_config_descriptor(device.raw_device, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        config = ConfigurationRef(device: device, descriptor: desc!)
        interfaces = []
        getInterfaces()
    }
    
    /// Get the interfces of the configuration.
    public func getInterfaces(){
        let size = Int(config.numInterfaces)
        for i in 0..<size {
            interfaces.append(Interface(config: config, index: i))
        }
    }
    
    /// The index used to get a string descriptor of this configuration
    public var index: Int {
        get {
            config.index
        }
    }
    
    /// The number used to identify this configuration
    public var value: Int {
        get {
            config.value
        }
    }
    
    /// The name of the `Configuration` to be displayed.
    ///
    /// This requires the device to be open.
    public var displayName: String {
        get {
            // If the index is 0 this is an unnamed configuration
            if config.index == 0 {
                return "(\(index)) unnamed configuration"
            }
            
            // Return a default value if the device is closed
            guard let handle = config.raw_handle else {
                return "\(index) configuration on closed device"
            }

            // Make a buffer for the name of the configuration
            let size = 256;
            var buffer: [UInt8] = Array(repeating: 0, count: size)
            let returnCode = libusb_get_string_descriptor_ascii(
                handle,
                UInt8(config.index),
                &buffer,
                Int32(size))
            
            // Check if there is an error when filling the buffer with the name
            if returnCode <= 0 {
                return "(\(index)) unknown configuration"
            }
            
            return String(bytes: buffer, encoding: .ascii) ?? ("(\(index)) unnamed configuration")
        }
    }
    
    /// Compare configurations by their internal pointer. Two configuration classes that point to the same `libUSB_config_descriptor` are considered the same
    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.config.descriptor == rhs.config.descriptor
    }
    
    /// Make this configuration active, if possible.
    ///
    /// The device should have been opened with `device.open` first.
    ///
    /// Activating the configuration should be done before claiming an interface or sending data.
    ///
    /// - throws: A ``USBError`` if activating the configuration fails
    /// * `.busy` if interfaces have already been claimed
    /// * `.noDevice` if the device has been unplugged
    /// * `.connectionClosed` if the device was closed using ``Device/close()``
    public func setActive() throws {
        guard let handle = config.raw_handle else {
            throw USBError.connectionClosed
        }
        libusb_set_configuration(handle, // The handle we are configuring ourselves with
                                 Int32(value)) // our value
    }
    
    /// A hash representation of the configuration
    public func hash(into hasher: inout Hasher) {
        config.descriptor.hash(into: &hasher)
    }
}

/// An internal class for managing lifetimes
///
/// This exists to ensure the libUSB device and context outlive any child objects.
internal class ConfigurationRef {
    var device: DeviceRef
    var descriptor: UnsafeMutablePointer<libusb_config_descriptor>
    
    init(device: DeviceRef, descriptor: UnsafeMutablePointer<libusb_config_descriptor>) {
        self.device = device
        self.descriptor = descriptor
    }
    
    var raw_handle: OpaquePointer? {
        get {
            device.raw_handle
        }
    }
    
    var raw_device: OpaquePointer {
        get {
            device.raw_device
        }
    }
    
    var numInterfaces: Int {
        get {
            Int(descriptor.pointee.bNumInterfaces)
        }
    }
    
    var value: Int {
        get {
            Int(descriptor.pointee.bConfigurationValue)
        }
    }
    
    var index: Int {
        get {
            Int(descriptor.pointee.iConfiguration)
        }
    }
    
    deinit {
        libusb_free_config_descriptor(descriptor)
    }
}
