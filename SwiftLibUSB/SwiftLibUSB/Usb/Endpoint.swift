//
//  Endpoint.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation

class Endpoint {
    var descriptor: libusb_endpoint_descriptor
    
    init(pointer : libusb_endpoint_descriptor) {
       descriptor = pointer
    }
    
    deinit {
        
    }
}
