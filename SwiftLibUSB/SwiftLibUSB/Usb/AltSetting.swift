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
        for i in 0..<setting.altSetting.pointee.bNumEndpoints {
            endpoints.append(Endpoint(pointer: setting.altSetting.pointee.endpoint[Int(i)], device: setting.interface.config.device))
        }
    }
    
    static func == (lhs: AltSetting, rhs: AltSetting) -> Bool {
        lhs.setting.interface.config.device.device == rhs.setting.interface.config.device.device && lhs.index == rhs.index && lhs.interfaceIndex == rhs.interfaceIndex
    }
    
    var displayName: String {
        get {
            if(setting.altSetting.pointee.iInterface == 0){
                return "(\(index)) unnamed alt setting"
            }
            var size = 256;
            var buffer: [UInt8] = Array(repeating: 0, count: size)
            var returnCode = libusb_get_string_descriptor_ascii(setting.interface.config.device.handle, setting.altSetting.pointee.iInterface, &buffer, Int32(size))
            if(returnCode <= 0){
                return "\(index) error getting name: \(USBError.from(code: returnCode).localizedDescription)"
            }
            return String(bytes: buffer, encoding: .ascii) ?? ("(\(index)) unnamed alt setting")
        }
    }
    
    var interfaceIndex: Int {
        get {
            Int(setting.altSetting.pointee.bInterfaceNumber)
        }
    }
    
    var index: Int {
        get {
            Int(setting.altSetting.pointee.bAlternateSetting)
        }
    }
    
    /// A code describing what kind of communication this setting handles.
    var interfaceClass: ClassCode {
        get {
            ClassCode.from(code: UInt32(setting.altSetting.pointee.bInterfaceClass))
        }
    }
    
    /// If the `interfaceClass` has subtypes, this gives that type.
    var interfaceSubClass: Int {
        get {
            Int(setting.altSetting.pointee.bInterfaceSubClass)
        }
    }
    
    /// If the `interfaceClass` and `interfaceSubClass` has protocols, this gives the protocol
    var interfaceProtocol: Int {
        get {
            Int(setting.altSetting.pointee.bInterfaceProtocol)
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
        let error = libusb_set_interface_alt_setting(setting.interface.config.device.handle, Int32(setting.altSetting.pointee.bInterfaceNumber), Int32(setting.altSetting.pointee.bAlternateSetting))
        if error < 0 {
            throw USBError.from(code: error)
        }
    }
    
    /// A hash representation of the altSetting
    func hash(into hasher: inout Hasher) {
        setting.interface.config.device.device.hash(into: &hasher)
        interfaceIndex.hash(into: &hasher)
        index.hash(into: &hasher)
    }
}

internal class AltSettingRef {
    let interface: InterfaceRef
    let altSetting: UnsafePointer<libusb_interface_descriptor>
    
    init(interface: InterfaceRef, index: Int) {
        self.interface = interface
        altSetting = interface.altsetting + index
    }
    
    deinit {
        // AltSettings don't need to be released
    }
}
