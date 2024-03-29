//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation
import Usb

/// A group of endpoints intended to be used together. An ``AltSetting`` determines what functions these endpoints have.
///
/// An `Interface` should be claimed before using an `AltSetting` within it. Each `Interface` is independent, so
/// multiple `Interface`s can be claimed simultaneously.
public class Interface: Hashable {
    public static func == (lhs: Interface, rhs: Interface) -> Bool {
        return lhs.interface.rawDevice == rhs.interface.rawDevice && lhs.interface.index == rhs.interface.index
    }
    
    /// The alternate settings offered for how to use these endpoints.
    public var altSettings: [AltSetting]
    private var interface: InterfaceRef
    
    init(config: ConfigurationRef, index: Int) {
        interface = InterfaceRef(config: config, index: Int32(index))
        altSettings = []
        for i in 0..<Int(interface.numAltsetting) {
            altSettings.append(AltSetting(interface: interface, index: i))
        }
    }
    
    /// The number identifying this interface for ``Interface/claim()`` and similar functions.
    public var index: Int {
        get {
            Int(interface.index)
        }
    }
    
    /// Inform the operating system that this interface will be used.
    ///
    /// The parent configuration should be made active before calling this, and this must be called before activating
    /// an alternate setting.
    ///
    /// - throws: a ``USBError`` if claiming fails
    /// * `.busy` if another program has claimed the interface
    /// * `.noDevice` if the device has been disconnected
    public func claim() throws {
        try interface.claim()
    }
    
    /// A hash representation of the interface
    public func hash(into hasher: inout Hasher) {
        interface.rawDevice.hash(into: &hasher)
        interface.index.hash(into: &hasher)
    }
}

/// An internal class for managing lifetimes.
///
/// This exists to make sure the libUSB device and context outlive any interfaces even if the Device and Context are freed.
internal class InterfaceRef {
    let config: ConfigurationRef
    let descriptor: UnsafePointer<libusb_interface>
    let index: Int32
    var claimed: Bool
    
    var numAltsetting: Int32 {
        get {
            descriptor.pointee.num_altsetting
        }
    }
    
    var altsetting: UnsafePointer<libusb_interface_descriptor> {
        get {
            descriptor.pointee.altsetting
        }
    }
    
    var rawDevice: OpaquePointer {
        get {
            config.rawDevice
        }
    }
    
    var rawHandle: OpaquePointer? {
        get {
            config.rawHandle
        }
    }
    
    init(config: ConfigurationRef, index: Int32) {
        self.config = config
        self.index = index
        descriptor = config.descriptor.pointee.interface + Int(index)
        claimed = false
    }
    
    func claim() throws {
        guard let handle = config.rawHandle else {
            throw USBError.connectionClosed
        }
        let error = libusb_claim_interface(handle, Int32(index))
        if error < 0 {
            throw USBError(rawValue: error) ?? USBError.other
        }
        claimed = true
    }
    
    func getStringDescriptor(index: UInt8) -> String? {
        config.getStringDescriptor(index: index)
    }
    
    deinit {
        if claimed && config.rawHandle != nil {
            libusb_release_interface(config.rawHandle, index)
        }
    }
}
