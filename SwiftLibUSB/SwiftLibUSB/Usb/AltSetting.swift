//
//  AltSetting.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation

class AltSetting {
    var descriptor: UnsafeMutablePointer<libusb_interface_descriptor>
    
    init(pointer : UnsafeMutablePointer<libusb_interface_descriptor>) {
       descriptor = pointer
    }
    
    deinit {
        
    }
}
