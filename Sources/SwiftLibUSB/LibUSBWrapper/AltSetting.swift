//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 5/25/23.
//

import Foundation
import Usb

/// A setting that controls how the endpoints in an ``Interface`` behave.
///
/// This must be activated using ``AltSetting/setActive()`` before sending or receiving data through any of
/// the ``Endpoint`` objects it contains.
///
/// The endpoints in an ``AltSetting`` each have the same address numbers as the other ``AltSettings``
/// in the ``Interface``, but the ``AltSetting/interfaceClass`` and ``Endpoint/transferType``
/// can be different. Making the setting active determines how the device will communicate.
public class AltSetting: Hashable {
    /// The endpoints defined by this alternate setting
    public var endpoints: [Endpoint]
    /// An internal class to manage the lifetime of the AltSetting
    private var setting: AltSettingRef
    
    /// Construct an AltSetting from an Interface and an index.
    init(interface: InterfaceRef, index: Int) {
        setting = AltSettingRef(interface: interface, index: index)
        
        // Fill the endpoint array with each endpoint defined
        endpoints = []
        for i in 0..<setting.numEndpoints {
            endpoints.append(Endpoint(altSetting: setting, index: Int(i)))
        }
    }
    
    public static func == (lhs: AltSetting, rhs: AltSetting) -> Bool {
        lhs.setting.rawDevice == rhs.setting.rawDevice &&
          lhs.index == rhs.index &&
          lhs.interfaceIndex == rhs.interfaceIndex
    }
    
    /// The name of the AltSetting to be displayed
    ///
    /// This gets the name from the device, which requires the device to be open. Not all devices provide names for alternate
    /// settings.
    public var displayName: String {
        setting.getStringDescriptor(index: setting.interfaceName) ?? "(\(index)) unnamed alt setting"
    }
    
    /// The number of this interface
    public var interfaceIndex: Int {
        get {
            Int(setting.interfaceNumber)
        }
    }
    
    /// The value used to select this alternate setting for this interface
    public var index: Int {
        get {
            Int(setting.index)
        }
    }
    
    /// A code describing what kind of communication this setting handles
    public var interfaceClass: ClassCode {
        get {
            setting.interfaceClass
        }
    }
    
    /// If the `interfaceClass` has subtypes, this gives that type.
    public var interfaceSubClass: Int {
        get {
            Int(setting.interfaceSubClass)
        }
    }
    
    /// If the `interfaceClass` and `interfaceSubClass` have protocols, this gives the protocol
    public var interfaceProtocol: Int {
        get {
            Int(setting.interfaceProtocol)
        }
    }
    
    /// Make the setting active.
    ///
    /// This must be done before sending data through the endpoints. The parent configuration and interface should have been activated and claimed first.
    ///
    /// - throws: A ``USBError`` if activating the setting fails
    /// * `.notFound` if the interface was not claimed
    /// * `.noDevice` if the device was disconnected
    /// * `.connectionClosed` if the connection was closed using ``Device/close()``.
    public func setActive() throws {
        guard let handle = setting.rawHandle else {
            throw USBError.connectionClosed
        }
        let error = libusb_set_interface_alt_setting(
            handle,
            Int32(setting.interfaceNumber),
            Int32(setting.index))
        if error < 0 {
            throw USBError(rawValue: error) ?? USBError.other
        }
    }
    
    /// A hash representation of the altSetting
    public func hash(into hasher: inout Hasher) {
        setting.rawDevice.hash(into: &hasher)
        interfaceIndex.hash(into: &hasher)
        index.hash(into: &hasher)
    }
}

/// An internal class for managing lifetimes.
///
/// This exists to make sure the device and context live longer than any Endpoints that are in use.
internal class AltSettingRef {
    let interface: InterfaceRef
    let altSetting: UnsafePointer<libusb_interface_descriptor>
    
    init(interface: InterfaceRef, index: Int) {
        self.interface = interface
        altSetting = interface.altsetting + index
    }
    
    func getStringDescriptor(index: UInt8) -> String? {
        interface.getStringDescriptor(index: index)
    }
    
    var rawDevice: OpaquePointer {
        get {
            interface.rawDevice
        }
    }
    
    var rawHandle: OpaquePointer? {
        get {
            interface.rawHandle
        }
    }
    
    var index: UInt8 {
        get {
            altSetting.pointee.bAlternateSetting
        }
    }
    
    var interfaceNumber: UInt8 {
        get {
            altSetting.pointee.bInterfaceNumber
        }
    }
    
    var interfaceProtocol: UInt8 {
        get {
            altSetting.pointee.bInterfaceProtocol
        }
    }
    
    var interfaceSubClass: Int {
        get {
            Int(altSetting.pointee.bInterfaceSubClass)
        }
    }
    
    var interfaceClass: ClassCode {
        get {
            ClassCode(rawValue: altSetting.pointee.bInterfaceClass) ?? ClassCode.other
        }
    }
    
    var interfaceName: UInt8 {
        get {
            altSetting.pointee.iInterface
        }
    }
    
    var bInterfaceProtocol: UInt8 {
        get {
            altSetting.pointee.bInterfaceProtocol
        }
    }
    
    var numEndpoints: UInt8 {
        get {
            altSetting.pointee.bNumEndpoints
        }
    }
    
    func endpoint(index: Int) -> UnsafePointer<libusb_endpoint_descriptor> {
        altSetting.pointee.endpoint + index
    }
    
    deinit {
        // AltSettings don't have any data to be released
    }
}
