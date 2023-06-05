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
/// This does nothing on its own; use USBTMCInstrument or another subclass to communicate with a device.
class USBInstrument {
    var _session: USBSession
    
    init(vendorID: Int, productID: Int, SerialNumber: String?) throws {
        _session = try USBSession(vendorID: vendorID, productID: productID, SerialNumber: SerialNumber)
    }
    
}

extension USBInstrument {
    /// An error associated with a  USB Instrument.
    /// 
    public enum Error: Swift.Error {
        /// Could not find a device with the specified vendorID and productID and Serial Number(If not null).
        case couldNotFind
        
        /// Found multiple devices with the same vendor and product ID, but Serial Number was not specified. Serial number **must** be specified if there can be multiple devices with the same product ID and vendor ID
        case identificationNotUnique
        
        /// Found no devices when searching
        case noDevices
        
        /// Found multiple devices with the same product id, vendor id and serial number.
        case serialCodeNotUnique
        
        /// When attempting to encode a user given string with a user given encoding, an error occurs
        case cannotEncode
        
        /// When looking for USB endpoints to send messages through, no alternative setting could be found that has compliant endpoints
        /// Or an altsetting claims to have endpoints it doesn't have
        case couldNotFindEndpoint
    }
}

extension USBInstrument.Error {
    public var localizedDescription: String {
        switch self {
        case .couldNotFind:
            return "Could not find device with given IDs"
        case .identificationNotUnique:
            return "Identification of USB device was not unique"
        case .noDevices:
            return "No devices were found"
        case .serialCodeNotUnique:
            return "Identification of USB devices with serial number was not unique"
        case .cannotEncode:
            return "Could not encode given string with given encoding"
        case .couldNotFindEndpoint:
            return "Could not find at least 1 required endpoint that satisfies requirements"
        }
    }
}

extension USBInstrument : Instrument {
    var session: CoreSwiftVISA.Session {
        get{
            return _session
        }
    }
}
