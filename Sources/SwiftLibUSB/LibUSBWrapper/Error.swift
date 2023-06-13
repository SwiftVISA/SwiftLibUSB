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
public enum USBError: Int32, Error {
    /// The libUSB method returned with no issues
    ///
    /// Equivalent to `LIBUSB_SUCCESS`
    case success = 0
    /// Input/output error
    ///
    /// Equivalent to `LIBUSB_ERROR_IO`
    case io = -1
    /// One or more of the given parameters is not valid for the given method
    ///
    /// Equivalent to `LIBUSB_ERROR_INVALID_PARAM`
    case invalidParam = -2
    /// User lacks permissions to perform the operation
    ///
    /// Equivalent to `LIBUSB_ERROR_ACCESS`
    case access = -3
    /// The device is missing, usually because it has been disconnected
    ///
    /// Equivalent to `LIBUSB_ERROR_NO_DEVICE`
    case noDevice = -4
    /// An object referenced by a parameter does not exist
    ///
    /// Equivalent to `LIBUSB_ERROR_NOT_FOUND`
    case notFound = -5
    /// A required resource is busy
    ///
    /// Equivalent to `LIBUSB_ERROR_BUSY`
    case busy = -6
    /// The timeout period elapsed without a response
    ///
    /// Equivalent to `LIBUSB_ERROR_TIMEOUT`
    case timeout = -7
    /// More data is available than space was provided
    ///
    /// Equivalent to `LIBUSB_ERROR_OVERFLOW`
    case overflow = -8
    /// The connection was interrupted, ususally due to an endpoint halt
    ///
    /// Equivalent to `LIBUSB_ERROR_PIPE`
    case pipe = -9
    /// A system call was interrupted
    ///
    /// Equivalent to `LIBUSB_ERROR_INTERRUPTED`
    case interrupted = -10
    /// Allocation on a libUSB object failed
    ///
    /// Equivalent to `LIBUSB_ERROR_NO_MEM`
    case noMemory = -11
    /// The operation is not supported on this platform. This can happen if an OS does not let user-space programs set configurations
    ///
    /// Equivalent to `LIBUSB_ERROR_NOT_SUPPORTED`
    case notSupported = -12
    /// Another unspecified error occurred
    ///
    /// Equivalent to `LIBUSB_ERROR_OTHER`
    case other = -99
    /// The device was closed
    ///
    /// This does not correspond to a libUSB error code.
    case connectionClosed
}
