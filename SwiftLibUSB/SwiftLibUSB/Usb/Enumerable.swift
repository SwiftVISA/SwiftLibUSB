//
//  Enumerable.swift
//  SwiftLibUSB
//
//  Created by Bryce Hawken (Student) on 6/7/23.
//

import Foundation


/// Describes the direction of data transfer on an endpoint.
///
/// `In` endpoints can only transfer data from the device to the program, while
/// `Out` endpoints only transfer data from the program to the device.
enum Direction {
    case In
    case Out
    var val: UInt8 {
        get {
            switch self {
            case .In:
                return 1
            case .Out:
                return 0
            }
        }
    }
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


enum LibUSBControlType{
    case Standard
    case Class
    case Vendor
    case Reserved
    var val: UInt8 {
        get {
            switch self {
            case .Standard:
                return 0
            case .Class:
                return 1
            case .Vendor:
                return 2
            case .Reserved:
                return 3
            }
        }
    }
}

enum LibUSBRecipient{
    case Device
    case Interface
    case Endpoint
    case Other
    var val: UInt8 {
        get {
            switch self {
            case .Device:
                return 0
            case .Interface:
                return 1
            case .Endpoint:
                return 2
            case .Other:
                return 3
            }
        }
    }
}