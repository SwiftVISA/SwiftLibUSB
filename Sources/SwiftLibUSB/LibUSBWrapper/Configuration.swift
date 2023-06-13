//
//  Configuration.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/25/23.
//

import Foundation
import Usb

/// A top-level setting for how a device communicates.
///
/// Configurations determine the maximum power a device can draw and which interfaces are available.
public class Configuration: Hashable {
    /// The interfaces exposed by this Configuration
    public var interfaces: [Interface]
    /// An internal class to manage the lifetime of the configuration
    private var config: ConfigurationRef
    
    /// Load the configuration with the given index
    ///
    /// - throws: A ``USBError`` if getting the configuration fails
    /// * `.notFound` if the index is invalid.
    init(_ device: DeviceRef, index: UInt8) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_config_descriptor(device.rawDevice, index, &desc)
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
        let error = libusb_get_active_config_descriptor(device.rawDevice, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        config = ConfigurationRef(device: device, descriptor: desc!)
        interfaces = []
        getInterfaces()
    }
    
    /// Get the interfces of the configuration.
    ///
    /// This exists to reduce code duplication between the two constructors.
    private func getInterfaces(){
        let size = Int(config.numInterfaces)
        for i in 0..<size {
            interfaces.append(Interface(config: config, index: i))
        }
    }
    
    /// The index used to get a string descriptor of this configuration
    public var index: Int {
        get {
            Int(config.index)
        }
    }
    
    /// The number used to identify this configuration
    public var value: Int {
        get {
            Int(config.value)
        }
    }
    
    /// The name of the `Configuration` to be displayed.
    ///
    /// This requires the device to be open.
    public var displayName: String {
        get {
            config.getStringDescriptor(index: config.index) ?? ("(\(index)) unnamed configuration")
        }
    }
    
    /// Compare configurations by their internal pointer. Two configuration classes that point to the same `libUSB_config_descriptor` are considered the same
    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.config.descriptor == rhs.config.descriptor
    }
    
    /// Make this configuration active, if possible.
    ///
    /// Activating the configuration should be done before claiming an interface or sending data.
    ///
    /// - throws: A ``USBError`` if activating the configuration fails
    /// * `.busy` if interfaces have already been claimed
    /// * `.noDevice` if the device has been unplugged
    /// * `.connectionClosed` if the device was closed using ``Device/close()``
    public func setActive() throws {
        guard let handle = config.rawHandle else {
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
    
    func getStringDescriptor(index: UInt8) -> String? {
        device.getStringDescriptor(index: index)
    }
    
    var rawHandle: OpaquePointer? {
        get {
            device.rawHandle
        }
    }
    
    var rawDevice: OpaquePointer {
        get {
            device.rawDevice
        }
    }
    
    var numInterfaces: UInt8 {
        get {
            descriptor.pointee.bNumInterfaces
        }
    }
    
    var value: UInt8 {
        get {
            descriptor.pointee.bConfigurationValue
        }
    }
    
    var index: UInt8 {
        get {
            descriptor.pointee.iConfiguration
        }
    }
    
    deinit {
        libusb_free_config_descriptor(descriptor)
    }
}
