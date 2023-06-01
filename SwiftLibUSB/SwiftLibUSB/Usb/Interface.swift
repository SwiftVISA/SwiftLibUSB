//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation

/// A group of endpoints
///
/// An `AltSetting` determines what functions these endpoints have.
class Interface : Hashable {
    static func == (lhs: Interface, rhs: Interface) -> Bool {
        return lhs.interface.config.device.device == rhs.interface.config.device.device && lhs.interface.index == rhs.interface.index
    }
    
    var altSettings: [AltSetting]
    var interface: InterfaceRef
    
    init(config: ConfigurationRef, index: Int) {
        interface = InterfaceRef(config: config, index: Int32(index))
        
        altSettings = []
        for i in 0..<Int(interface.numAltsetting) {
            altSettings.append(AltSetting(interface: interface, index: i))
        }
    }
    
    var index: Int {
        get {
            Int(interface.index)
        }
    }
    
    /// Informs the operating system that this interface will be used.
    ///
    /// The parent configuration should be made active before calling this, and this must be called before activating
    /// an alternate setting.
    ///
    /// - throws: a USBError is claiming fails
    /// * `.busy` if another program has claimed the interface
    /// * `.noDevice` if the device has been disconnected
    func claim() throws {
        try interface.claim()
    }
    
    /// A hash representation of the interface
    func hash(into hasher: inout Hasher) {
        interface.config.device.device.hash(into: &hasher)
        interface.index.hash(into: &hasher)
    }
}

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
    
    init(config: ConfigurationRef, index: Int32) {
        self.config = config
        self.index = index
        descriptor = config.descriptor.pointee.interface + Int(index)
        claimed = false
    }
    
    func claim() throws {
        let error = libusb_claim_interface(config.device.handle, Int32(index))
        if error < 0 {
            throw USBError.from(code: error)
        }
        claimed = true
    }
    
    deinit {
        if claimed {
            libusb_release_interface(config.device.handle, index)
        }
    }
}
