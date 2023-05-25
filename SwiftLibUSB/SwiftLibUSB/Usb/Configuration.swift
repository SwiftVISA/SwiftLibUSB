//
//  Configuration.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/25/23.
//

import Foundation

/// Each device has at least 1 configuration, often more. libUSB keeps track of these with libusb config descriptors.
/// Each instance manages 1 of these descriptors, inclduing managing the getting and freeing of this discriptor
class Configuration: Hashable{
    var descriptor: UnsafeMutablePointer<libusb_config_descriptor>
    var interfaces : [Interface]
    var device: Device
    
    init(_ device: Device, index: UInt8) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_config_descriptor(device.device, index, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        descriptor = desc!
        interfaces = []
        self.device = device
        getInterfaces()
    }
    
    init(_ device: Device) throws {
        var desc: UnsafeMutablePointer<libusb_config_descriptor>? = nil
        let error = libusb_get_active_config_descriptor(device.device, &desc)
        if error < 0 {
            throw USBError.from(code: error)
        }
        descriptor = desc!
        interfaces = []
        self.device = device
        getInterfaces()
    }
    
    func getInterfaces(){
        let size = Int(descriptor.pointee.bNumInterfaces)
        for i in 0..<size {
            if var inf = descriptor.pointee.interface?[i] {
                interfaces.append(Interface(pointer: inf))
            }
        }
    }
    
    var index: Int {
        get {
            Int(descriptor.pointee.iConfiguration)
        }
    }
    
    var value: Int {
        get {
            Int(descriptor.pointee.bConfigurationValue)
        }
    }
    
    var displayName: String {
        get {
            return "value: \(value) Index: \(index)"
        }
    }
    
    deinit {
        libusb_free_config_descriptor(descriptor)
    }
    
    /// Compares configuration by their internal pointer. Two configurations classes that point to the same libUSB config descriptor are considered the same
    static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.descriptor == rhs.descriptor
    }
    
    func setActive() throws{
        let DeviceHandle = device.handle! // This will throw, if the deviceHandle is null(IE: The device was not opened
        libusb_set_configuration(DeviceHandle.handle, // The handle we are configuring ourselves with
                                 Int32(descriptor.pointee.bConfigurationValue)) // our value
    }
    
    /// A hash representation of the configuration
    func hash(into hasher: inout Hasher) {
        descriptor.hash(into: &hasher)
    }
}
