//
//  Endpoint.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation

/// A communication channel with the device
///
/// Before transferring data, you should activate the configuration, claim the interface, and activate the alternate setting
/// that contain this endpoint.
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

/// Describes the direction of data transfer on an endpoint.
///
/// `In` endpoints can only transfer data from the device to the program, while
/// `Out` endpoints only transfer data from the program to the device.
enum Direction {
    case In
    case Out
}

/// Describes the type of data transfer an endpoint can send
///
/// `bulk` endpoints transfer individual blocks of data.
/// `isochronous` endpoints transfer streams, such as audio or video, that need to be received quickly, but that can be dropped occasionally without problems.
/// `interrupt` endpoints transfer incidental messages from the device
/// `control` endpoints send status messages, such as the ones used to select an alternate setting. These are not exposed in an `AltSetting`
enum TransferType {
    case bulk
    case isochronous
    case interrupt
    case control
}
