//
//  Enumerable.swift
//  SwiftLibUSB
//
//  Created by Bryce Hawken (Student) on 6/7/23.
//

import Foundation


/// Direction of data transfer on an ``Endpoint``.
public enum Direction: UInt8 {
    /// Data transfers from the host out to the device
    case out = 0
    /// Data transfers from the device in to the host
    case `in` = 1
}

/// Describes the type of data transfer an ``Endpoint`` can send.
public enum TransferType: UInt8 {
    /// Used for status messages and similar.
    ///
    /// These endpoints are not typically exposed in ``AltSetting``s, so seeing an ``Endpoint`` with this transfer type
    /// typically indicates a communication error.
    case control = 0
    /// Used for streaming data such as audio, where many packets must be sent and received quickly
    case isochronous = 1
    /// Used for transferring blocks of data that must be received without transmission errors
    case bulk = 2
    /// Used for sending unrequested, incidental messages
    case interrupt = 3
}

/// Source that describing a control message
public enum ControlType: UInt8 {
    /// Message defined as part of the core USB specification
    case standard = 0
    /// Message defined by the device class (e.g. USBTMC)
    case `class` = 1
    /// Message defined by the device manufacturuer
    case vendor = 2
    /// Should not be used.
    case reserved = 3
}

/// The destination of a control message.
public enum Recipient: UInt8 {
    case device = 0
    case interface = 1
    case endpoint = 2
    case other = 3
}
