//
//  USBInstrument.swift
//  SwiftLibUSB
//
//  Created by Bryce Hawken (Student) on 6/1/23.
//

import Foundation
import CoreSwiftVISA

/// A base class for instruments connected over USB.
///
/// This does nothing on its own; use ``USBTMCInstrument`` or another subclass to communicate with a device.
public class USBInstrument {
    /// We use an internal property so we can use USBSession-specific methods. This is exposed
    /// publicly as a Session through the Instrument.session property.
    public private(set) var _session: USBSession
    
    /// Attempts to establish a connection to a USB instrument.
    ///
    /// - Parameters:
    ///   - vendorID: The vendor ID of the device
    ///   - productID: The product ID of the device
    ///   - serialNumber: The serial number of the device
    /// - Throws: ``Error`` if there is an error initalizing the session. ``USBError`` if libUSB encounted an error
    ///   * ``Error/couldNotFind`` if no matching device was found
    ///   * ``Error/noDevices`` if no devices were found at all
    ///   * ``Error/identificationNotUnique`` if multiple devices with the given vendor ID and product ID were found and serialNumber was not given
    ///   * ``Error/serialCodeNotUnique`` if multiple devices were found with the given vendor ID, product ID, and serial number (this indicates buggy devices that share a serial number)
    public init(vendorID: Int, productID: Int, serialNumber: String?) throws {
        _session = try USBSession(
            vendorID: vendorID,
            productID: productID,
            serialNumber: serialNumber)
    }
    
}

public extension USBInstrument {
    /// An error associated with a USB Instrument.
    enum Error: Swift.Error {
        /// Unknown error occured resulting in failed operation.
        case operationFailed
        
        /// Could not find a device with the specified vendor ID, product ID and serial number (if provided).
        case couldNotFind
        
        /// Found multiple devices with the same vendor and product ID, but serial number was not specified. Serial number **must** be specified if there can be multiple devices with the same product ID and vendor ID.
        case identificationNotUnique
        
        /// Found no devices when searching.
        case noDevices
        
        /// Found multiple devices with the same product id, vendor id and serial number.
        case serialNumberNotUnique
        
        /// The requested operation is not supported by the device.
        case notSupported
    }
}

public extension USBInstrument.Error {
    /// A more descriptive explanation of what each error associated with a USB Instrument is.
    var localizedDescription: String {
        switch self {
        case .operationFailed:
            return "An unknown error occured causing the operation to fail"
        case .couldNotFind:
            return "Could not find device with given IDs"
        case .identificationNotUnique:
            return "Identification of USB device was not unique"
        case .noDevices:
            return "No devices were found"
        case .serialNumberNotUnique:
            return "Identification of USB devices with serial number was not unique"
        case .notSupported:
            return "The device does not support this operation"
        }
    }
}

extension USBInstrument: Instrument {
    public var session: CoreSwiftVISA.Session {
        get {
            return _session
        }
    }
}
