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
        return lhs.device == rhs.device && lhs.index == rhs.index
    }
    
    var descriptor: libusb_interface
    var claimed = false
    var altSettings: [AltSetting]
    var device: Device
    var index: Int
    
    init(pointer : libusb_interface, device: Device, index: Int) {
        descriptor = pointer
        self.device = device
        self.index = index
        
        altSettings = []
        for i in 0..<descriptor.num_altsetting {
            altSettings.append(AltSetting(pointer: descriptor.altsetting[Int(i)], device: device))
        }
    }
    
    deinit {
        if claimed {
            libusb_release_interface(device.handle, Int32(index))
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
        let error = libusb_claim_interface(device.handle, Int32(index))
        if error < 0 {
            throw USBError.from(code: error)
        }
        claimed = true
    }
    
    /// A hash representation of the interface
    func hash(into hasher: inout Hasher) {
        device.hash(into: &hasher)
        index.hash(into: &hasher)
    }
}
