//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 5/25/23.
//

import Foundation

/// A setting that controls how endpoints behave. This must be activated using `setActive` before sending or receiving data.
class AltSetting : Hashable{
    var descriptor: libusb_interface_descriptor
    var endpoints: [Endpoint]
    var device: Device
    
    init(pointer : libusb_interface_descriptor, device: Device) {
        descriptor = pointer
        self.device = device
        
        endpoints = []
        for i in 0..<descriptor.bNumEndpoints {
            endpoints.append(Endpoint(pointer: descriptor.endpoint[Int(i)], device: device))
        }
    }
    
    static func == (lhs: AltSetting, rhs: AltSetting) -> Bool {
        lhs.device == rhs.device && lhs.index == rhs.index && lhs.interfaceIndex == rhs.interfaceIndex
    }
    
    var displayName: String {
        get {
            // If the index is 0 this is an unnamed alt setting
            if(descriptor.iInterface == 0){
                return "(\(index)) unnamed alt setting"
            }
            
            // Make a buffer for the name of the alt setting
            var size = 256;
            var buffer: [UInt8] = Array(repeating: 0, count: size)
            var returnCode = libusb_get_string_descriptor_ascii(device.handle, descriptor.iInterface, &buffer, Int32(size))
            
            // Check if there is an error when filling the buffer with the name
            if(returnCode <= 0){
                return "\(index) error getting name: \(USBError.from(code: returnCode).localizedDescription)"
            }
            
            return String(bytes: buffer, encoding: .ascii) ?? ("(\(index)) unnamed alt setting")
        }
    }
    
    var interfaceIndex: Int {
        get {
            Int(descriptor.bInterfaceNumber)
        }
    }
    
    var index: Int {
        get {
            Int(descriptor.bAlternateSetting)
        }
    }
    
    /// A code describing what kind of communication this setting handles.
    var interfaceClass: ClassCode {
        get {
            ClassCode.from(code: UInt32(descriptor.bInterfaceClass))
        }
    }
    
    /// If the `interfaceClass` has subtypes, this gives that type.
    var interfaceSubClass: Int {
        get {
            Int(descriptor.bInterfaceSubClass)
        }
    }
    
    /// If the `interfaceClass` and `interfaceSubClass` has protocols, this gives the protocol
    var interfaceProtocol: Int {
        get {
            Int(descriptor.bInterfaceProtocol)
        }
    }
    
    deinit {
        
    }
    
    /// Makes the setting active.
    ///
    /// This must be done before sending data through the endpoints. The parent configuration and interface should have been activated and claimed first.
    ///
    /// - throws: a USBError if activating the setting fails
    /// * `.notFound` if the interface was not claimed
    /// * `.noDevice` if the device was disconnected
    func setActive() throws {
        let error = libusb_set_interface_alt_setting(device.handle, Int32(descriptor.bInterfaceNumber), Int32(descriptor.bAlternateSetting))
        if error < 0 {
            throw USBError.from(code: error)
        }
    }
    
    /// A hash representation of the altSetting
    func hash(into hasher: inout Hasher) {
        device.hash(into: &hasher)
        interfaceIndex.hash(into: &hasher)
        index.hash(into: &hasher)
    }
    
}
