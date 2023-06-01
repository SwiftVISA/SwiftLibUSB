//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 5/25/23.
//

import Foundation

/// A setting that controls how endpoints behave. This must be activated using `setActive` before sending or receiving data.
class AltSetting : Hashable{
    var endpoints: [Endpoint]
    var setting: AltSettingRef
    
    init(interface: InterfaceRef, index: Int) {
        setting = AltSettingRef(interface: interface, index: index)
        
        endpoints = []
        for i in 0..<Int(setting.altSetting.pointee.bNumEndpoints) {
            endpoints.append(Endpoint(altSetting: setting, index: i))
        }
    }
    
    static func == (lhs: AltSetting, rhs: AltSetting) -> Bool {
        lhs.setting.device.device == rhs.setting.device.device && lhs.index == rhs.index && lhs.interfaceIndex == rhs.interfaceIndex
    }
    
    var displayName: String {
        get {
            if(setting.altSetting.pointee.iInterface == 0){
                return "(\(index)) unnamed alt setting"
            }
            var size = 256;
            var buffer: [UInt8] = Array(repeating: 0, count: size)
            var returnCode = libusb_get_string_descriptor_ascii(setting.device.handle, UInt8(setting.interfaceName), &buffer, Int32(size))
            if(returnCode <= 0){
                return "\(index) error getting name: \(USBError.from(code: returnCode).localizedDescription)"
            }
            return String(bytes: buffer, encoding: .ascii) ?? ("(\(index)) unnamed alt setting")
        }
    }
    
    var interfaceIndex: Int {
        get {
            setting.interfaceNumber
        }
    }
    
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
    func setActive() throws {
        let error = libusb_set_interface_alt_setting(setting.device.handle, Int32(setting.interfaceNumber), Int32(setting.index))
        if error < 0 {
            throw USBError.from(code: error)
        }
    }
    
    /// A hash representation of the altSetting
    func hash(into hasher: inout Hasher) {
        setting.device.device.hash(into: &hasher)
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
    
    var device: DeviceRef {
        get {
            interface.device
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
    
    deinit {
        // AltSettings don't have any data to be released
    }
}
