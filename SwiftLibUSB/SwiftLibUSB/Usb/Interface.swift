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
    
    init(pointer : libusb_interface, device: Device) {
        descriptor = pointer
        self.device = device
        
        altSettings = []
        for i in 0..<descriptor.num_altsetting {
            altSettings.append(AltSetting(pointer: descriptor.altsetting[Int(i)], device: device))
        }
    }
    
    deinit {
        
    }
    
    func claim(){
       
    }
}
