//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation

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
    
    func claim(){
        libusb_claim_interface(device.handle?.handle, Int32(index))
        claimed = true
    }
}
