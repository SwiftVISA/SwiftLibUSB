//
//  Error.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/24/23.
//

import Foundation

/// USB Error is a return code given by many libUSB methods. A value of zero indicates the method returned with no errors thrown
/// Negative values indicate an error with different values indicating type
///
///     (0) Success: The libUSB method returned with no issues
///
///     (-1) IO: Input/Output Error
///
///     (-2) invalidParam: One or more of the given parameters is not valid for the given method
///
///     (-3) access: Access was denied, permissions were not sufficient to call the function
///
///     (-4) noDevice: The named device could not be found. This tends to be because of disconnection
///
///     (-5) notFound: Some entity named as a parameter could not be found
///
///     (-6) busy: A required resource is busy
///
///     (-7) timeout: The timeout period elapsed without a response
///
///     (-8) overflow: An overflow error occured
///
///     (-9) pipe: A pipe error occured
///
///     (-10) interupted: A system call was interupted. This can be because of the interrupt
///     signal
///
///     (-11) noMemory: There is not enough memory
///
///     (-12) notSupported: Operation not supported. For example, setting a configuration when the OS determines configuration
///
///     (-99) other: An unspecified error occured
///
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
