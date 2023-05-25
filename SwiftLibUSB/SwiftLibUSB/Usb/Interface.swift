//
//  Interface.swift
//  SwiftLibUSB
//
//  Created by Thomas Applegate (Student) on 5/25/23.
//

import Foundation

class Interface {
    var descriptor: UnsafeMutablePointer<libusb_interface>
    var claimed = false
    
    init(pointer : UnsafeMutablePointer<libusb_interface>) {
       descriptor = pointer
    }
    
    func claim(){
      
    }
    
    deinit {
        
    }
}
