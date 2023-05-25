//
//  Error.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

enum USBError: Error {
    case success
    case io
    case invalidParam
    case access
    case noDevice
    case notFound
    case busy
    case timeout
    case overflow
    case pipe
    case interrupted
    case noMemory
    case notSupported
    case other
    
}

extension USBError {
    static func from(code: Int32) -> Self {
        switch libusb_error(code) {
        case LIBUSB_SUCCESS: return .success
        case LIBUSB_ERROR_IO: return .io
        case LIBUSB_ERROR_INVALID_PARAM: return .invalidParam
        case LIBUSB_ERROR_ACCESS: return .access
        case LIBUSB_ERROR_NO_DEVICE: return .noDevice
        case LIBUSB_ERROR_NOT_FOUND: return .notFound
        case LIBUSB_ERROR_BUSY: return .busy
        case LIBUSB_ERROR_TIMEOUT: return .timeout
        case LIBUSB_ERROR_OVERFLOW: return .overflow
        case LIBUSB_ERROR_PIPE: return .pipe
        case LIBUSB_ERROR_INTERRUPTED: return .interrupted
        case LIBUSB_ERROR_NO_MEM: return .noMemory
        case LIBUSB_ERROR_NOT_SUPPORTED: return .notSupported
        default: return .other
        }
    }
}
