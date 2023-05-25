//
//  Endpoint.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation

class Endpoint {
    var descriptor: libusb_endpoint_descriptor
    var device: Device
    
    init(pointer : libusb_endpoint_descriptor, device: Device) {
        descriptor = pointer
        self.device = device
    }
    
    deinit {
        
    }
    
    var address: Int {
        get {
            Int(descriptor.bEndpointAddress)
        }
    }
    
    var attributes: Int {
        get {
            Int(descriptor.bmAttributes)
        }
    }
    
    var direction: Direction {
        get {
            switch descriptor.bEndpointAddress >> 7 {
            case 1: return .In
            case 0: return .Out
            default: return .Out
            }
        }
    }
    
    var transferType: TransferType {
        get {
            switch libusb_endpoint_transfer_type(UInt32(descriptor.bmAttributes & 3)) {
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_BULK: return .bulk
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_ISOCHRONOUS: return .isochronous
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_INTERRUPT: return .interrupt
            default: return .control
            }
        }
    }
}

enum Direction {
    case In
    case Out
}

enum TransferType {
    case bulk
    case isochronous
    case interrupt
    case control
}
