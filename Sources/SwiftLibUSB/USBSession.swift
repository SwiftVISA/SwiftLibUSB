//
//  USBSession.swift
//  SwiftLibUSB
//
//  Created by Bryce Hawken (Student) on 6/1/23.
//

import Foundation
import CoreSwiftVISA

/// A wrapper around the connection to a USB device.
///
/// This manages most of the details of finding and connecting to a device. Instrument classes such as
/// ``USBTMCInstrument`` are responsible for verifying support for the intended protocol and communicating with the device.
public class USBSession {
    /// A number uniquely identifying the manufacturer of a device.
    ///
    /// As an example, devices made by Keysight Technologies have the vendor ID 10893.
    ///
    /// This appears as the second field (after `USB`) in a VISA identification string.
    public private(set) var vendorID: Int
    
    /// A number uniquely identifying the kind of device, qualified by the vendor ID.
    ///
    /// As an example, Keysight E36103B oscilloscopes have the product ID 5634. This is unique among Keysight devices,
    /// but not among all USB devices.
    ///
    /// This appears as the third field in a VISA identification string.
    public private(set) var productID: Int
    
    /// A string uniquely identifying a single device.
    ///
    /// This appears as the fourth field in a VISA identification string.
    public private(set) var serialNumber: String?
    
    /// Stores the internal ``Context`` used by the wrapper classes for libUSB
    public private(set) var usbContext: Context
    
    ///stores the internal ``Device`` used by the wrapper classes for libUSB
    public private(set) var usbDevice: Device
    
    typealias Error = USBInstrument.Error
    
    /// Attempt to establish a connection to a device.
    ///
    /// - Parameters:
    ///   - vendorID: Number identifying the manufacturer of the device.
    ///   - productID: Number identifying the product of the device.
    ///   - serialNumber: If provided, this will only connect to a device with the provided serial number.
    /// - Throws: ``USBInstrument/Error`` if there is an error initalizing the session. ``USBError`` if libUSB encounted an error
    ///   * ``USBInstrument/Error/noDevices`` if no connected devices were found
    ///   * ``USBInstrument/Error/couldNotFind`` if no matching device was found
    ///   * ``USBInstrument/Error/identificationNotUnique`` if multiple devices matching the vendor ID and product ID were found and no serial number was provided
    ///   * ``USBInstrument/Error/serialCodeNotUnique`` if multiple matching devices with the given serial number were found (this indicates buggy devices)
    public init(vendorID: Int, productID: Int, serialNumber: String?) throws {
        self.vendorID = vendorID
        self.productID = productID
        self.serialNumber = serialNumber
        try usbContext = Context()
        try usbDevice = Self.rawFindDevice(
            vendorID: vendorID,
            productID: productID,
            serialNumber: serialNumber,
            context: usbContext)
    }
}

private extension USBSession {
    /// Find the ``Device`` specified given a vendor id, product id, and serial number
    /// There should never be a situation where the ids and serial number is not unique, but it is acconted for anyway
    /// - Parameters:
    ///   - vendorID: The vendor id of the device
    ///   - productID: The product id of the device
    ///   - serialNumber: The serial number of the device
    ///   - context: The internal ``Context``
    /// - Returns: The ``Device`` specified
    /// - Throws: ``USBInstrument/Error`` if no devices are connected, the specified device could not be found, or the given information was not unique
    private static func rawFindDevice(
        vendorID: Int,
        productID: Int,
        serialNumber: String?,
        context: Context
    ) throws -> Device {
        if context.devices.isEmpty {
            throw Error.noDevices
        }
        var foundDevice: Device?
        for device in context.devices {
            if device.productId == productID &&
               device.vendorId == vendorID {
                
                if serialNumber == nil {
                    if foundDevice != nil {
                        throw Error.identificationNotUnique
                    }
                    foundDevice = device
                } else if serialNumber! == device.serialNumber {
                    if foundDevice != nil {
                        throw Error.serialNumberNotUnique
                    }
                    foundDevice = device
                }
            }
        }
        if foundDevice == nil {
            throw Error.couldNotFind
        }
        return foundDevice!
    }
}

extension USBSession: Session {
    /// Closes the session. The instrument owning this session will no longer be able to read or write data.
    public func close() {
        usbDevice.close()
    }
    
    /// Tries to reestablish the session's connection.
    /// - Parameters:
    ///  - timeout: The amount of time in milliseconds to attempt to reconnect. A timeout of 0 will try forever
    /// - Throws: ``USBInstrument/Error`` if the session cannot be reconnected
    public func reconnect(timeout: TimeInterval) throws {
        try usbDevice.reopen()
    }
}
