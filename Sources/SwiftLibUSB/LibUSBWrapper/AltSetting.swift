//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 5/25/23.
//

import Foundation

/// A setting that controls how endpoints behave. This must be activated using `setActive` before sending or receiving data.
public class AltSetting : Hashable{
    var endpoints: [Endpoint]
    var setting: AltSettingRef
    
    init(interface: InterfaceRef, index: Int) {
        setting = AltSettingRef(interface: interface, index: index)
        
        endpoints = []
        for i in 0..<setting.numEndpoints {
            endpoints.append(Endpoint(altSetting: setting, index: i))
        }
    }
    
    public static func == (lhs: AltSetting, rhs: AltSetting) -> Bool {
        lhs.setting.raw_device == rhs.setting.raw_device && lhs.index == rhs.index && lhs.interfaceIndex == rhs.interfaceIndex
    }
    
    /// The name of the `AltSetting` to be displayed.
    var displayName: String {
        get {
            // If the index is 0 this is an unnamed alt setting
            if(setting.interfaceName == 0){
                return "(\(index)) unnamed alt setting"
            }
            // Make a buffer for the name of the alt setting
            let size = 256;
            var buffer: [UInt8] = Array(repeating: 0, count: size)
            let returnCode = libusb_get_string_descriptor_ascii(setting.raw_handle, UInt8(setting.interfaceName), &buffer, Int32(size))
            
            // Check if there is an error when filling the buffer with the name
            if(returnCode <= 0){
                return "\(index) error getting name: \(USBError.from(code: returnCode).localizedDescription)"
            }
            
            return String(bytes: buffer, encoding: .ascii) ?? ("(\(index)) unnamed alt setting")
        }
    }
    
    /// The number of this interface
    var interfaceIndex: Int {
        get {
            setting.interfaceNumber
        }
    }
    
    /// The value used to select this alternate setting for this interface
    var index: Int {
        get {
            setting.index
        }
    }
    
    /// A code describing what kind of communication this setting handles.
    var interfaceClass: ClassCode {
        get {
            setting.interfaceClass
        }
    }
    
    /// If the `interfaceClass` has subtypes, this gives that type.
    var interfaceSubClass: Int {
        get {
            setting.interfaceSubClass
        }
    }
    
    /// If the `interfaceClass` and `interfaceSubClass` has protocols, this gives the protocol
    var interfaceProtocol: Int {
        get {
            setting.interfaceProtocol
        }
    }
    
    /// Makes the setting active.
    ///
    /// This must be done before sending data through the endpoints. The parent configuration and interface should have been activated and claimed first.
    ///
    /// - throws: a USBError if activating the setting fails
    /// * `.notFound` if the interface was not claimed
    /// * `.noDevice` if the device was disconnected
    public func setActive() throws {
        let error = libusb_set_interface_alt_setting(setting.raw_handle, Int32(setting.interfaceNumber), Int32(setting.index))
        if error < 0 {
            throw USBError.from(code: error)
        }
    }
    
    /// A hash representation of the altSetting
    public func hash(into hasher: inout Hasher) {
        setting.raw_device.hash(into: &hasher)
        interfaceIndex.hash(into: &hasher)
        index.hash(into: &hasher)
    }
}

/// Internal class for managing lifetimes.
///
/// This exists to make sure the device and context live longer than any Endpoints that are in use.
internal class AltSettingRef {
    let interface: InterfaceRef
    let altSetting: UnsafePointer<libusb_interface_descriptor>
    
    init(interface: InterfaceRef, index: Int) {
        self.interface = interface
        altSetting = interface.altsetting + index
    }
    
    var raw_device: OpaquePointer {
        get {
            interface.raw_device
        }
    }
    
    var raw_handle: OpaquePointer {
        get {
            interface.raw_handle
        }
    }
    
    var index: Int {
        get {
            Int(altSetting.pointee.bAlternateSetting)
        }
    }
    
    var interfaceNumber: Int {
        get {
            Int(altSetting.pointee.bInterfaceNumber)
        }
    }
    
    var interfaceProtocol: Int {
        get {
            Int(altSetting.pointee.bInterfaceProtocol)
        }
    }
    
    var interfaceSubClass: Int {
        get {
            Int(altSetting.pointee.bInterfaceSubClass)
        }
    }
    
    var interfaceClass: ClassCode {
        get {
            ClassCode.from(code: UInt32(altSetting.pointee.bInterfaceClass))
        }
    }
    
    var interfaceName: Int {
        get {
            Int(altSetting.pointee.iInterface)
        }
    }
    
    var bInterfaceProtocol: Int {
        get {
            Int(altSetting.pointee.bInterfaceProtocol)
        }
    }
    
    var numEndpoints: Int {
        get {
            Int(altSetting.pointee.bNumEndpoints)
        }
    }
    
    func endpoint(index: Int) -> UnsafePointer<libusb_endpoint_descriptor> {
        altSetting.pointee.endpoint + index
    }
    
    deinit {
        // AltSettings don't have any data to be released
    }
}
