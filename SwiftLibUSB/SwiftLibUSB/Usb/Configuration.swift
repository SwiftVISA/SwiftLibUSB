//
//  Configuration.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/25/23.
//

import Foundation

/// Each device has at least 1 configuration, often more. libUSB keeps track of these with libusb config descriptors.
/// Each instance manages 1 of these descriptors, inclduing managing the getting and freeing of this descriptor
class Configuration: Hashable{
    var interfaces : [Interface]
    var config: ConfigurationRef
    
    /// Loads the configuration with the given index
    ///
    /// - throws: a USBError if getting the configuration fails
    /// * `.notFound` if the index is invalid
    init(_ device: DeviceRef, index: UInt8) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_config_descriptor(device.device, index, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        config = ConfigurationRef(device: device, descriptor: desc!)
        interfaces = []
        getInterfaces()
    }
    
    /// Gets the descriptor of the active configuration.
    ///
    /// - throws: a USBError if getting the configuration fails
    /// * `.notFound` if the device is not configured
    init(_ device: DeviceRef) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_active_config_descriptor(device.device, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        config = ConfigurationRef(device: device, descriptor: desc!)
        interfaces = []
        getInterfaces()
    }
    
    func getInterfaces(){
        let size = Int(config.descriptor.pointee.bNumInterfaces)
        for i in 0..<size {
            if let inf = config.descriptor.pointee.interface?[i] {
                interfaces.append(Interface(pointer: inf, device: config.device, index: i))
            }
        }
    }
    
    /// The index used to get a string descriptor of this configuration
    var index: Int {
        get {
            Int(config.descriptor.pointee.iConfiguration)
        }
    }
    
    /// The number used to identify this configuration
    var value: Int {
        get {
            Int(config.descriptor.pointee.bConfigurationValue)
        }
    }
    
    var displayName: String {
        get {
            return "value: \(value) Index: \(index)"
        }
    }
    
    /// Compares configuration by their internal pointer. Two configurations classes that point to the same libUSB config descriptor are considered the same
    static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.config.descriptor == rhs.config.descriptor
    }
    
    /// Makes this configuration active, if possible
    ///
    /// The device should have been opened with `device.open` first.
    ///
    /// Activating the configuration should be done before claiming an interface or sending data.
    ///
    /// - throws: A USBError if activating the configuration fails
    /// * `.busy` if interfaces have already been claimed
    /// * `.noDevice` if the device has been unplugged
    func setActive() throws {
        libusb_set_configuration(config.device.handle, // The handle we are configuring ourselves with
                                 Int32(config.descriptor.pointee.bConfigurationValue)) // our value
    }
    
    /// A hash representation of the configuration
    func hash(into hasher: inout Hasher) {
        config.descriptor.hash(into: &hasher)
    }
}

internal class ConfigurationRef {
    var device: DeviceRef
    var descriptor: UnsafeMutablePointer<libusb_config_descriptor>
    
    init(device: DeviceRef, descriptor: UnsafeMutablePointer<libusb_config_descriptor>) {
        self.device = device
        self.descriptor = descriptor
    }
    
    deinit {
        libusb_free_config_descriptor(descriptor)
    }
}
