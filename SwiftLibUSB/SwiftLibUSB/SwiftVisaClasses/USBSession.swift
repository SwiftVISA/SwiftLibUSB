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
/// - Note: Complies with Session as defined in CoreSwiftVisa
///
class USBSession {
    
    
    /// Stores the product ID. Each vendor assigns each type of device a product ID which is used in identification
    var productID: Int
    
    /// Stores the vendor ID. Each vendor is given an ID used to identify their products. Forms part of the primary key
    var vendorID: Int
    
    /// Stores the serial number, if defined. This must be specified if more than one device has the same vendor and product id
    var SerialNumber: String?
    
    var usbContext: Context
    
    var usbDevice: Device
    
    typealias Error = USBInstrument.Error
    
    /// To initlise a session. Sessions that are initlised should eventually be closed.
    /// Sessions are defined uniquly by a combination of their vendorID, productID and Serial Number
    /// - Note: Serial number can be passed as null. This will only work if there is only one device of the specified product and vendorID given. If there are multiple devices with the same product and vendor ID's, then the SerialNumber must be specified
    /// - Parameters:
    ///   - vendorID: Each device has a device ID. This identifies who makes the device. Part of primary identifying key
    ///   - productID: Help define which product this device is and is more specific than vendorID. Part of primary identifying key
    ///   - SerialNumber: This string value represents the "Serial number" of the device. If there are multiple of the same product attached this is used to identify the product.
    /// - Throws: USBInstrument.Error if there is an error initilising the session. USBError if libUSB encounted an error
    init(vendorID: Int, productID: Int, SerialNumber: String?) throws {
        self.vendorID = vendorID
        self.productID = productID
        self.SerialNumber = SerialNumber
        try usbContext = Self.raw_connect()
        try usbDevice = Self.raw_find_device(vendorID: vendorID, productID: productID, SerialNumber: SerialNumber, context: usbContext)
    }
}

extension USBSession {
    private static func raw_connect() throws -> Context {
        var createdContext = try Context()
        return createdContext
    }
    private static func raw_find_device(
        vendorID: Int,
        productID: Int,
        SerialNumber: String?,
        context: Context
    ) throws -> Device {
        var deviceList = try context.getDeviceList()
        if deviceList.devices.isEmpty {
            throw Error.noDevices
        }
        var didFind = false;
        var foundDevice: Device
        for device in deviceList.devices {
            if(device.productId == productID &&
               device.vendorId == vendorID
            ){
                if(SerialNumber == nil){
                    if(didFind == true){
                        throw Error.identificationNotUnique
                    }
                    didFind = true
                    foundDevice = device
                }else if (SerialNumber! == device.serialCode){
                    if(didFind == true){
                        throw Error.serialCodeNotUnique
                    }
                    didFind = true
                    foundDevice = device
                }
            }
        }
        if(didFind == false){
            throw Error.couldNotFind
        }
        return foundDevice
    }
}

extension USBSession: Session {
    /// Closes the session. The instrument owning this session will no longer be able to read or write data.
    func close() throws {
        
    }
    
    /// Tries to reestablish the session's connection.
    func reconnect(timeout: TimeInterval) throws {
        
    }
}
