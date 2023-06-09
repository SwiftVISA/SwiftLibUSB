//
//  Error.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation
import Usb

/// USB Error is a return code given by many libUSB methods. A value of zero indicates the method returned with no errors thrown
/// Negative values indicate an error with different values indicating type
public enum USBError: Error {
    /// The libUSB method returned with no issues
    ///
    /// Integer value: `0`
    case success
    /// Input/output error
    ///
    /// Integer value: `-1`
    case io
    /// One or more of the given parameters is not valid for the given method
    ///
    /// Integer value: `-2`
    case invalidParam
    /// User lacks permissions to perform the operation
    ///
    /// Integer value: `-3`
    case access
    /// The device is missing, usually because it has been disconnected
    ///
    /// Integer value: `-4`
    case noDevice
    /// An object referenced by a parameter does not exist
    ///
    /// Integer value: `-5`
    case notFound
    /// A required resource is busy
    ///
    /// Integer value: `-6`
    case busy
    /// The timeout period elapsed without a response
    ///
    /// Integer value: `-7`
    case timeout
    /// More data is available than space was provided
    ///
    /// Integer value: `-8`
    case overflow
    /// The connection was interrupted, ususally due to an endpoint halt
    ///
    /// Integer value: `-9`
    case pipe
    /// A system call was interrupted
    ///
    /// Integer value: `-10`
    case interrupted
    /// Allocation on a libUSB object failed
    ///
    /// Integer value: `-11`
    case noMemory
    /// The operation is not supported on this platform. This can happen if an OS does not let user-space programs set configurations
    ///
    /// Integer value: `-12`
    case notSupported
    /// Another unspecified error occurred
    ///
    /// Integer value: `-99`
    case other
}

public extension USBError {
    /// Converts a libUSB error value into a USBError
    /// - parameters: the libUSB error value as an Int32
    /// - returns: a USBError representing the same error
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
