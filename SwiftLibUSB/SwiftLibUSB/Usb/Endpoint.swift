//
//  Endpoint.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation

/// A communication channel with the device
///
/// Before transferring data, you should activate the configuration, claim the interface, and activate the alternate setting
/// that contain this endpoint.
class Endpoint {
    var descriptor: libusb_endpoint_descriptor
    var device: Device
    
    init(pointer : libusb_endpoint_descriptor, device: Device) {
        descriptor = pointer
        self.device = device
    }
    
    deinit {
        
    }
    
    var address: Int {
        get {
            Int(descriptor.bEndpointAddress)
        }
    }
    
    var attributes: Int {
        get {
            Int(descriptor.bmAttributes)
        }
    }
    
    var direction: Direction {
        get {
            switch descriptor.bEndpointAddress >> 7 {
            case 1: return .In
            case 0: return .Out
            default: return .Out
            }
        }
    }
    
    var transferType: TransferType {
        get {
            switch libusb_endpoint_transfer_type(UInt32(descriptor.bmAttributes & 3)) {
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_BULK: return .bulk
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_ISOCHRONOUS: return .isochronous
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_INTERRUPT: return .interrupt
            default: return .control
            }
        }
    }
    
    func clearHalt(){
        libusb_clear_halt(device.handle?.handle, descriptor.bEndpointAddress)
    }
    
    /// Sends a message to a bulk out endpoint
    ///
    /// This will only work properly if this endpoint is bulk out (`direction == .out` and `.transferType == .bulk`)
    ///
    /// - returns: the number of bytes sent
    /// - throws: a USBError if the transfer fails
    /// * `.pipe` if the endpoint halts
    /// * `.noDevice` if the device disconnected
    /// * `.busy` if libUSB is currently handling events (if you call this from an asynchronous transfer callback, for example)
    /// * `.invalidParam` if the transfer size is larger than the OS or device support
    func sendBulkTransfer(data: inout Data) throws -> Int {
        var sent: Int32 = 0;
        var data = [UInt8](data)
        let length: Int32 = Int32(data.count)
        let error = libusb_bulk_transfer(device.handle?.handle, descriptor.bEndpointAddress, &data, length, &sent, 1000)
        if error < 0 {
            throw USBError.from(code: error)
        }
        return Int(sent)
    }
    
    /// Receives a message from a bulk in endpoint
    ///
    /// This will only work properly if this endpoint is bulk in (`direction == .in` and `.transferType == .bulk`)
    ///
    /// - returns: the number of bytes received
    /// - throws: a USBError if the transfer fails
    /// * `.pipe` if the endpoint halts
    /// * `.noDevice` if the device disconnected
    /// * `.busy` if libUSB is currently handling events (if you call this from an asynchronous transfer callback, for example)
    /// * `.invalidParam` if the transfer size is larger than the OS or device support
    /// * `.overflow` if more data was sent than was requested
    func receiveBulkTransfer() throws -> Data {
        //clearHalt()
        var sent: Int32 = 0;
        var innerData = [UInt8](repeating: 0, count: 1024)
        let length: Int32 = 1024
        let error = libusb_bulk_transfer(device.handle?.handle, descriptor.bEndpointAddress, &innerData, length, &sent, 1000)
        print("Amount sent: \(sent), with error \(error)")
        if error < 0 {
            throw USBError.from(code: error)
        }
        return Data(innerData)
    }
}

/// Describes the direction of data transfer on an endpoint.
///
/// `In` endpoints can only transfer data from the device to the program, while
/// `Out` endpoints only transfer data from the program to the device.
enum Direction {
    case In
    case Out
}

/// Describes the type of data transfer an endpoint can send
///
/// `bulk` endpoints transfer individual blocks of data.
/// `isochronous` endpoints transfer streams, such as audio or video, that need to be received quickly, but that can be dropped occasionally without problems.
/// `interrupt` endpoints transfer incidental messages from the device
/// `control` endpoints send status messages, such as the ones used to select an alternate setting. These are not exposed in an `AltSetting`
enum TransferType {
    case bulk
    case isochronous
    case interrupt
    case control
}
