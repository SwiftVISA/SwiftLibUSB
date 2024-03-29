//
//  Endpoint.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation
import Usb

/// A communication channel with the device.
///
/// Endpoints are unidirectional, so they can either only send data out or only receive data in from the device, determined
/// by the ``Endpoint/direction`` property. The type of data they can transfer is determined by the
/// ``Endpoint/transferType`` property.
///
/// Before sending data on an Endpoint, the ``Configuration``, ``Interface``, and  ``AltSetting`` that contain
/// it must be activated. This is done by calling `config.setActive()`, `interface.claim()`, and
/// `setting.setActive()`
public class Endpoint {
    /// The descriptor of the endpoint is pointed to by this pointer. This is the raw descriptor as given by libUSB, which is hard to use. Getter methods should be used instead of referencing this directly. [It is documented here](https://libusb.sourceforge.io/api-1.0/structlibusb__endpoint__descriptor.html)
    private var descriptor: UnsafePointer<libusb_endpoint_descriptor>
    
    /// Because all endpoints belong to an altsetting, the altsetting the endpoint belongs to is stored by the endpoint
    private var altSetting: AltSettingRef
    
    /// Creates the endpoint itself. This is generally done automatically.
    /// - Parameters:
    ///   - altSetting: the atlernative setting this endpoint refers to
    ///   - index: The index this endpoint refers to
    init(altSetting: AltSettingRef, index: Int) {
        self.altSetting = altSetting
        descriptor = altSetting.endpoint(index: index)
    }
    
    /// The number identifying the endpoint to the device.
    ///
    /// It corresponds to the value bEndpointAddress as defined by libUSB
    public var address: Int {
        get {
            Int(descriptor.pointee.bEndpointAddress)
        }
    }
    
    /// The attributes which apply to the endpoint.
    ///
    /// In general, it is not neccesary to access this directly. Use ``Endpoint/transferType`` to get the transfer type.
    ///
    /// These attributes are stored as the bits of a single byte. A more detailed description can be found at [the libusb documentation for endpoint descriptors](https://libusb.sourceforge.io/api-1.0/structlibusb__endpoint__descriptor.html#a932b84417c46467f9916ecf7b679160b).
    ///
    /// To quote the libUSB documentation:
    /// - Bits 0:1 Determine the transfer type and correspond to libusb_endpoint_transfer_type.
    /// - Bits 2:3 are only used for isochronous endpoints and correspond to libusb_iso_sync_type.
    /// - Bits 4:5 are also only used for isochronous endpoints and correspond to libusb_iso_usage_type.
    /// - Bits 6:7 are reserved.
    public var attributes: Int {
        get {
            Int(descriptor.pointee.bmAttributes)
        }
    }
    
    ///  Endpoints have a physical limit on the amount of data they can send in a single packet.
    ///  Each sent packet must not exceed this size
    public var maxPacketSize: Int {
        get{
            Int(descriptor.pointee.wMaxPacketSize)
        }
    }
    
    ///  The Interval for polling endpoint for data transfers.
    ///  This value is measured in frames and ranges from 1-255 depending on context
    ///  This is irrelevant for bulk and control endpoints.
    ///  Isochronous endpoints will always have an interval of 1 frame
    public var interval: Int {
        get{
            Int(descriptor.pointee.bInterval)
        }
    }
    
    /// Holds the bRefresh value as devined by the [libusb endpoint descriptor](https://libusb.sourceforge.io/api-1.0/structlibusb__endpoint__descriptor.html)
    /// This **only** matters for audio devices, for non audio devices this is meaningless
    /// The rate at which synchronization feedback is provided.
    public var audioRefresh: Int {
        get{
            Int(descriptor.pointee.bRefresh)
        }
    }
    
    /// Holds the bSynchAddress value as devined by the [libusb endpoint descriptor](https://libusb.sourceforge.io/api-1.0/structlibusb__endpoint__descriptor.html)
    /// This **only** matters for audio devices, for non audio devices this is meaningless
    /// The address to which synchronozation is provided
    public var audioSynchAddress: Int {
        get{
            Int(descriptor.pointee.bSynchAddress)
        }
    }

    /// The direction of the data transfer of the endpoint.
    /// This is determined by the last bit of the endpoint address.
    /// - In denotes LIBUSB_ENDPOINT_IN which is the host recieving data from the device.
    /// - Out denotes LIBUSB_ENDPOINT_OUT which is sending data to the device from the host.
    ///
    /// See ``Direction`` for more information on how directions work
    public var direction: Direction {
        get {
            // Shifting a UInt8 by seven bits can only leave 1 or 0, so we can force unwrap.
            Direction(rawValue: descriptor.pointee.bEndpointAddress >> 7)!
        }
    }
    
    /// The type of the data transfer the endpoint can send.
    ///
    /// This is determiend by the bmAttributes value of the endpoint stored in ``Endpoint/attributes``
    ///
    /// For more information on what different transfer types mean, see ``TransferType``
    public var transferType: TransferType {
        get {
            // Bitwise ANDing with 3 always results in a number 0-3, all of which are
            // defined TransferTypes, so we can force unwrap.
            TransferType(rawValue: descriptor.pointee.bmAttributes & 3)!
        }
    }
    
    /// Clear halts or stalls for the endpoint.
    ///
    /// If a device reports an error based on inputs it was sent, it halts the offending endpoint. Before more messages can
    /// proceed the halt to the endpoint must be cleared.
    /// - Throws:
    /// * ``USBError/connectionClosed`` if the device was closed using ``Device/close()``
    /// * ``USBError/noDevice`` if the device was disconnected
    public func clearHalt() throws {
        guard let handle = altSetting.rawHandle else {
            throw USBError.connectionClosed
        }
        let error = libusb_clear_halt(handle, descriptor.pointee.bEndpointAddress)
        if error < 0 {
            throw USBError(rawValue: error) ?? USBError.other
        }
    }
    
    /// Send a message to a bulk out endpoint. This does **not** manipulate the data in any way. It does **not** add any required padding and it does **not** add any header, it simply sends the data as it was given.
    ///
    /// - important: This will only work properly if this endpoint is bulk out (`direction == .out` and `.transferType == .bulk`)
    ///
    /// - returns: the number of bytes sent. All of the bytes being sent does not imply that the message was read or interpreted successfully. This is not always the length of the given data, but it should never be greater
    /// - throws: a ``USBError`` if the transfer fails
    /// * ``USBError/pipe`` if the endpoint halts
    /// * ``USBError/noDevice`` if the device disconnected
    /// * ``USBError/busy`` if libUSB is currently handling events (if you call this from an asynchronous transfer callback, for example)
    /// * ``USBError/invalidParam`` if the transfer size is larger than the OS or device support
    /// * ``USBError/notSupported`` if you are attempting to do a bulk transfer on a non-bulk endpoint or are using the wrong direction. This is not thrown by libUSB but is instead thrown in this method
    /// * ``USBError/connectionClosed`` if the device was closed using ``Device/close()``
    /// - Parameters:
    ///   - data: the raw bytes to send unaltered to the device through this endpoint
    ///   - timeout: The time, in millisecounds, to wait before timeout. This is by default one second
    public func sendBulkTransfer(data: Data, timeout: Int = 1000) throws -> Int {
        // Only work if we are the right kind of endpoint
        if transferType != .bulk || direction != .out {
            throw USBError.notSupported
        }

        // Make sure the device is open
        guard let handle = altSetting.rawHandle else {
            throw USBError.connectionClosed
        }

        // Define the parameters, these will be passed by reference to libUSB
        var sent: Int32 = 0;
        var data = [UInt8](data)
        
        // the length of the data we are sending
        let length: Int32 = Int32(data.count)
        
        // Attempt to perform a bulk out transfer
        let error = libusb_bulk_transfer(
            handle,
            descriptor.pointee.bEndpointAddress,
            &data,
            length,
            &sent,
            UInt32(timeout))
        
        // Throw if the transfer had any errors. Errors are given by sending back a negative value
        if error < 0 {
            throw USBError(rawValue: error) ?? USBError.other
        }
        
        // Return the number of bytes send
        return Int(sent)
    }
    
    /// Receive a message from a bulk in endpoint. This will cutoff any extra bytes sent back by the device, only including up to the length the device intended to send. This does not do any output operations, only recieving data.
    /// - important: This will only work properly if this endpoint is bulk in (`direction == .in` and `.transferType == .bulk`)
    ///
    /// - returns: the number of bytes received
    /// - throws: a ``USBError`` if the transfer fails
    /// * ``USBError/pipe`` if the endpoint halts
    /// * ``USBError/noDevice`` if the device disconnected
    /// * ``USBError/busy`` if libUSB is currently handling events (if you call this from an asynchronous transfer callback, for example)
    /// * ``USBError/invalidParam`` if the transfer size is larger than the OS or device support
    /// * ``USBError/overflow`` if more data was sent than was requested
    /// * ``USBError/other`` if some unspecified error occured
    /// * ``USBError/notSupported`` if you are attempting to do a bulk transfer on a non-bulk endpoint or are using the wrong direction. This is not thrown by libUSB but is instead thrown in this method
    /// * ``USBError/connectionClosed`` if the device was closed using ``Device/close()``
    /// - Parameters:
    ///   - length: The length of the buffer to send to this out endpoint. Measured in bytes, the default is 1024 bytes
    ///   - timeout: The amount of time, in milliseconds to wait before timing out of the message. The default is 1000(1 second)
    public func receiveBulkTransfer(length: Int = 1024, timeout: Int = 1000) throws -> Data {
        // Throw an error if this is the wrong kind of endpoint
        if transferType != .bulk || direction != .in {
            throw USBError.notSupported
        }
        
        // Make sure the device is open
        guard let handle = altSetting.rawHandle else {
            throw USBError.connectionClosed
        }
        
        // Create the buffer and an integer that will be set to the length of the data recieved
        var sent: Int32 = 0;
        var innerData = [UInt8](repeating: 0, count: Int(length))
        
        // Attempt to perform a bulk in transfer
        let error = libusb_bulk_transfer(
            handle,
            descriptor.pointee.bEndpointAddress,
            &innerData,
            Int32(length),
            &sent,
            UInt32(timeout))
        
        // Throw if the transfer had any errors
        if error < 0 {
            throw USBError(rawValue: error) ?? USBError.other
        }
        
        // Turn the returned array into type Data, then return it.
        return Data(innerData[..<Int(sent)]) // We cutoff extra data larger than the amount recieved
    }
}
