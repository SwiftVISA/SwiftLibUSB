//
//  Endpoint.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/25/23.
//

import Foundation
import Usb

/// A communication channel with the device. Each device may have many endpoints that allow for communication from the host to the device
/// These endpoints are defined by the specific alternate setting(``AltSetting``) for a specific ``Interface`` in a specific ``Configuration`` for a specific ``Device``.
/// - Note: Before transferring data, libUSB requires that the configuration be active, the interface be claimed and the alternate setting that contains this endpoint be activated. The configuration can be made active by calling ``Configuration/setActive()`` in the ``Configuration`` object used. The interface is claimed by calling ``Interface/claim()`` in the ``Interface`` used.  The altsetting that this endpoint is a part of can be activated by ``AltSetting/setActive()``
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
    
    /// The address of the endpoint.
    /// It corresponds to the value bEndpointAddress as defined by libUSB
    public var address: Int {
        get {
            Int(descriptor.pointee.bEndpointAddress)
        }
    }
    
    /// The attributes which apply to the endpoint. In general, it is not neccesary to access this directly, instead use ``Endpoint/transferType`` to get the transfer type.
    /// These attributes are stored as the bits of a single byte. A more detailed description can be found at [the libusb documentation for endpoint descriptor](https://libusb.sourceforge.io/api-1.0/structlibusb__endpoint__descriptor.html#a932b84417c46467f9916ecf7b679160b)
    ///
    /// To quote the libUSB documentation:
    /// - Bits 0:1 Determine the transfer type and correspond to libusb_endpoint_transfer_type.
    /// - Bits 2:3 are only used for isochronous endpoints and correspond to libusb_iso_sync_type.
    /// - Bits 4:5 are also only used for isochronous endpoints and correspond to libusb_iso_usage_type.
    /// - Bits 6:7 are reserved.
    /// We st
    public var attributes: Int {
        get {
            Int(descriptor.pointee.bmAttributes)
        }
    }
    
    /// The direction of the data transfer of the endpoint. This is determined by the last bit of the endpoint address
    /// - In denotes LIBUSB_ENDPOINT_IN which is the host recieving data from the device.
    /// - Out denotes LIBUSB_ENDPOINT_OUT which is sending data to the device from the host.
    /// See ``Direction`` for more information on how directions work
    public var direction: Direction {
        get {
            switch descriptor.pointee.bEndpointAddress >> 7 {
            case 1: return .In
            case 0: return .Out
            default: return .Out
            }
        }
    }
    
    /// The type of the data transfer the endpoint can send.
    /// This is determiend by the bmAttributes value of the endpoint stored in ``Endpoint/attributes``
    /// For more information on what different transfertypes mean, see ``TransferType``
    public var transferType: TransferType {
        get {
            switch libusb_endpoint_transfer_type(UInt32(descriptor.pointee.bmAttributes & 3)) {
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_BULK: return .bulk
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_ISOCHRONOUS: return .isochronous
            case LIBUSB_ENDPOINT_TRANSFER_TYPE_INTERRUPT: return .interrupt
            default: return .control
            }
        }
    }
    
    /// Clear halts or stalls for the endpoint. If a device does not like the inputs it was sent, it haults. Before more messages can proceed the hault to the endpoint must be cleared. For consistant operation through errors, an endpoint should be cleared of haults before it should be used
    public func clearHalt() {
        libusb_clear_halt(altSetting.raw_handle, descriptor.pointee.bEndpointAddress)
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
    /// - Parameters:
    ///   - data: the raw bytes to send unaltered to the device through this endpoint
    ///   - timeout: The time, in millisecounds, to wait before timeout. This is by default one second
    public func sendBulkTransfer(data: inout Data, timeout: UInt32 = 1000) throws -> Int {
        // Only work if we are the right kind of endpoint
        if transferType != .bulk || direction != .Out {
            throw USBError.notSupported
        }
        // Define the parameters, these will be passed by reference to libUSB
        var sent: Int32 = 0;
        var data = [UInt8](data)
        
        // the length of the data we are sending
        let length: Int32 = Int32(data.count)
        
        // Attempt to perform a bulk out transfer
        let error = libusb_bulk_transfer(altSetting.raw_handle, descriptor.pointee.bEndpointAddress, &data, length, &sent, UInt32(timeout))
        
        // Throw if the transfer had any errors. Errors are given by sending back a negative value
        if error < 0 {
            throw USBError.from(code: error)
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
    /// - Parameters:
    ///   - length: The length of the buffer to send to this out endpoint. Measured in bytes, the default is 1024 bytes
    ///   - timeout: The amount of time, in milliseconds to wait before timing out of the message. The default is 1000(1 second)
    public func receiveBulkTransfer(length: Int = 1024, timeout: UInt32 = 1000) throws -> Data {
        // Throw an error if this is the wrong kind of endpoint
        if transferType != .bulk || direction != .In {
            throw USBError.notSupported
        }
        
        // Create the buffer and an integer that will be set to the length of the data recieved
        var sent: Int32 = 0;
        var innerData = [UInt8](repeating: 0, count: Int(length))
        
        // Attempt to perform a bulk in transfer
        let error = libusb_bulk_transfer(altSetting.raw_handle, descriptor.pointee.bEndpointAddress,
                                         &innerData, Int32(length), &sent, timeout)
        
        // Throw if the transfer had any errors
        if error < 0 {
            throw USBError.from(code: error)
        }
        
        // Turn the returned array into type Data, then return it.
        return Data(innerData[..<Int(sent)]) // We cutoff extra data larger than the amount recieved
    }
}
