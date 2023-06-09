//
//  Endpoint.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation
import Usb

/// A communication channel with the device
///
/// Before transferring data, you should activate the configuration, claim the interface, and activate the alternate setting
/// that contain this endpoint.
public class Endpoint {
    var descriptor: UnsafePointer<libusb_endpoint_descriptor>
    var altSetting: AltSettingRef
    
    init(altSetting: AltSettingRef, index: Int) {
        self.altSetting = altSetting
        descriptor = altSetting.endpoint(index: index)
    }
    
    deinit {
        
    }
    
    /// Address of the endpoint
    var address: Int {
        get {
            Int(descriptor.pointee.bEndpointAddress)
        }
    }
    
    /// Attributes which apply to the endpoint
    var attributes: Int {
        get {
            Int(descriptor.pointee.bmAttributes)
        }
    }
    
    /// Direction of the data transfer of the endpoint
    var direction: Direction {
        get {
            switch descriptor.pointee.bEndpointAddress >> 7 {
            case 1: return .In
            case 0: return .Out
            default: return .Out
            }
        }
    }
    
    /// The type of the data transfer the endpoint can send
    var transferType: TransferType {
        get {
            switch libusb_endpoint_transfer_type(UInt32(descriptor.pointee.bmAttributes & 3)) {
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_BULK: return .bulk
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_ISOCHRONOUS: return .isochronous
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_INTERRUPT: return .interrupt
            default: return .control
            }
        }
    }
    
    /// Clear halts or stalls for the endpoint
    func clearHalt(){
        libusb_clear_halt(altSetting.raw_handle, descriptor.pointee.bEndpointAddress)
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
        let error = libusb_bulk_transfer(altSetting.raw_handle, descriptor.pointee.bEndpointAddress, &data, length, &sent, 1000)
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
    func receiveBulkTransfer(length: Int32 = 1024) throws -> Data {
        //clearHalt()
        var sent: Int32 = 0;
        var innerData = [UInt8](repeating: 0, count: Int(length))
        let error = libusb_bulk_transfer(altSetting.raw_handle, descriptor.pointee.bEndpointAddress,
                                         &innerData, length, &sent, 1000)
        if error < 0 {
            throw USBError.from(code: error)
        }
        if(sent <= 12){
            throw USBError.other
        }
        return Data(innerData[..<Int(sent)])
    }
}
