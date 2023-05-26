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
class Interface {
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
            libusb_release_interface(device.handle?.handle, Int32(index))
        }
    }
    
    /// Informs the operating system that this interface will be used.
    ///
    /// The parent configuration should be made active before calling this, and this must be called before activating
    /// an alternate setting.
    func claim(){
        libusb_claim_interface(device.handle?.handle, Int32(index))
        claimed = true
    }
}
