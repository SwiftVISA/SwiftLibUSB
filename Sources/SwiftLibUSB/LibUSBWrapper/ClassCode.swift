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
public enum ClassCode {
    case perInterface
    case audio
    case communications
    case humanInterfaceDevice
    case physical
    case image
    case printer
    case massStorage
    case hub
    case data
    case smartCard
    case contentSecurity
    case video
    case personalHealthcare
    case diagnosticDevice
    case wireless
    case miscellaneous
    case application
    case vendorSpecific
    case other
}

public extension ClassCode {
    static func from(code: UInt32) -> Self {
        switch libusb_class_code(code) {
        case LIBUSB_CLASS_PER_INTERFACE: return .perInterface
        case LIBUSB_CLASS_AUDIO: return .audio
        case LIBUSB_CLASS_COMM: return .communications
        case LIBUSB_CLASS_HID: return .humanInterfaceDevice
        case LIBUSB_CLASS_PHYSICAL: return .physical
        case LIBUSB_CLASS_IMAGE: return .image
        case LIBUSB_CLASS_PRINTER: return .printer
        case LIBUSB_CLASS_MASS_STORAGE: return .massStorage
        case LIBUSB_CLASS_HUB: return .hub
        case LIBUSB_CLASS_DATA: return .data
        case LIBUSB_CLASS_SMART_CARD: return .smartCard
        case LIBUSB_CLASS_CONTENT_SECURITY: return .contentSecurity
        case LIBUSB_CLASS_VIDEO: return .video
        case LIBUSB_CLASS_PERSONAL_HEALTHCARE: return .personalHealthcare
        case LIBUSB_CLASS_DIAGNOSTIC_DEVICE: return .diagnosticDevice
        case LIBUSB_CLASS_WIRELESS: return .wireless
        case LIBUSB_CLASS_MISCELLANEOUS: return .miscellaneous
        case LIBUSB_CLASS_APPLICATION: return .application
        case LIBUSB_CLASS_VENDOR_SPEC: return .vendorSpecific
        default: return .other
        }
    }
}
