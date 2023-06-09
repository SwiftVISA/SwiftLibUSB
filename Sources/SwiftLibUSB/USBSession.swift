//
//  USBSession.swift
//  SwiftLibUSB
//
//  Created by Bryce Hawken (Student) on 6/1/23.
//

import Foundation
import CoreSwiftVISA

/// USBSessions represent a connection made over USB to a USB device.
/// Designed to be held by USBInstrument class.
/// - Note: Complies with ``Session`` as defined in CoreSwiftVisa
public class USBSession {
    /// Stores the product ID. Each vendor assigns each type of device a product ID which is used in identification
    public private(set) var productID: Int
    
    /// Stores the vendor ID. Each vendor is given an ID used to identify their products. Forms part of the primary key
    public private(set) var vendorID: Int
    
    /// Stores the serial number, if defined. This must be specified if more than one device has the same vendor and product id
    public private(set) var serialNumber: String?
    
    ///stores the internal ``Context`` used by the wrapper classes for libUSB
    public private(set) var usbContext: Context
    
    ///stores the internal ``Device`` used by the wrapper classes for libUSB
    public private(set) var usbDevice: Device
    
    typealias Error = USBInstrument.Error
    
    /// To initalize a session. Sessions that are initalized should eventually be closed.
    /// Sessions are defined uniquly by a combination of their vendorID, productID and Serial Number
    /// - Note: Serial number can be passed as null. This will only work if there is only one device of the specified product and vendorID given. If there are multiple devices with the same product and vendor ID's, then the SerialNumber must be specified
    /// - Parameters:
    ///   - vendorID: Each device has a device ID. This identifies who makes the device. Part of primary identifying key
    ///   - productID: Help define which product this device is and is more specific than vendorID. Part of primary identifying key
    ///   - SerialNumber: This string value represents the "Serial number" of the device. If there are multiple of the same product attached this is used to identify the product.
    /// - Throws: ``USBInstrument/Error`` if there is an error initalizing the session. ``USBError`` if libUSB encounted an error
    public init(vendorID: Int, productID: Int, serialNumber: String?) throws {
        self.vendorID = vendorID
        self.productID = productID
        self.serialNumber = serialNumber
        try usbContext = Self.raw_connect()
        try usbDevice = Self.raw_find_device(vendorID: vendorID, productID: productID, serialNumber: serialNumber, context: usbContext)
    }
}

private extension USBSession {
    /// connect to the device via libUSB
    /// - Returns: The interal ``Context`` that communicates with libusb
    /// - Throws: ``USBError`` on initialization if libUSB cannot initialize the ``Context``
    private static func raw_connect() throws -> Context {
        let createdContext = try Context()
        return createdContext
    }
    
    
    /// Find the ``Device`` specified given a vendor id, product id, and serial number
    /// There should never be a situation where the ids and serial number is not unique, but it is acconted for anyway
    /// - Parameters:
    ///   - vendorID: The vendor id of the device
    ///   - productID: The product id of the device
    ///   - serialNumber: The serial number of the device
    ///   - context: The internal ``Context``
    /// - Returns: The ``Device`` specified
    /// - Throws: ``USBInstrument/Error`` if no devices are connected, the specified device could not be found, or the given information was not unique
    private static func raw_find_device(
        vendorID: Int,
        productID: Int,
        serialNumber: String?,
        context: Context
    ) throws -> Device {
        if context.devices.isEmpty {
            throw Error.noDevices
        }
        var didFind = false;
        var foundDevice: Device?
        for device in context.devices {
            if device.productId == productID &&
               device.vendorId == vendorID {
                
                if serialNumber == nil {
                    if didFind == true {
                        throw Error.identificationNotUnique
                    }
                    didFind = true
                    foundDevice = device
                }else if (serialNumber!) == device.serialCode {
                    if didFind == true {
                        throw Error.serialCodeNotUnique
                    }
                    didFind = true
                    foundDevice = device
                }
            }
        }
        if didFind == false {
            throw Error.couldNotFind
        }
        return foundDevice!
    }
}

extension USBSession: Session {
    /// Closes the session. The instrument owning this session will no longer be able to read or write data.
    /// - Throws: ``USBInstrument.Error`` if the session cannot be closed
    public func close() throws {
        throw Error.notSupported
    }
    
    /// Tries to reestablish the session's connection.
    /// - Parameters:
    ///  - timeout: The amount of time in milliseconds to attempt to reconnect. A timeout of 0 will try forever
    /// - Throws: ``USBInstrument.Error`` if the session cannot be reconnected
    public func reconnect(timeout: TimeInterval) throws {
        throw Error.notSupported
    }
}
