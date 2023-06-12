//
//  ClassCode.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation
import Usb

/// A description used by ``AltSetting``s to describe the communication method for the interface.
///
/// The individual protocols are documented on the [USB website](https://www.usb.org/documents).
///
/// Lab equipment commonly implements the *Test and Measurement Class* interface, which is identified by the `.application` class
/// and subclass `3`.
public enum ClassCode: UInt8 {
    case perInterface = 0
    case audio = 1
    case communications = 2
    case humanInterfaceDevice = 3
    case physical = 5
    case image = 6
    case printer = 7
    case massStorage = 8
    case hub = 9
    case data = 10
    case smartCard = 11
    case contentSecurity = 13
    case video = 14
    case personalHealthcare = 15
    case diagnosticDevice = 0xdc
    case wireless = 0xe0
    case miscellaneous = 0xef
    case application = 0xfe
    case vendorSpecific = 0xff
    // Unallocated number used for unknown classes
    case other = 16
}
