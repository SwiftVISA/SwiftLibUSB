SwiftLibUSB
===========

SwiftLibUSB allows communicating with VISA-compatible devices over USB. SwiftLibUSB requires
libusb to be installed (`brew install libusb`). It does not require NI-VISA.

Requrements
-----------

(These are the version SwiftLibUSB was built on; previous versions might work, but have not
been tested.)

 * Swift 5.0+
 * macOS 13+
 * libusb 1.0 (`brew install libusb`)

Installation
------------

Installation can be done through the [Swift Package Manager](https://swift.org/package-manager/).
To use SwiftLibUSB in your project, include the following dependency in your Package.swift file:

```
    dependencies: [
        .package(url: "https://github.com/SwiftVISA/SwiftLibUSB.git", .upToNextMinor(from("0.1.0")))
    ]
```

SwiftLibUSB automatically exports [CoreSwiftVISA](https://github.com/SwiftVISA/CoreSwiftVISA), 
so `import SwiftLibUSB` is sufficient for importing CoreSwiftVISA. 

SwiftLibUSB can also be installed using Xcode's built-in support for adding Swift Package
dependencies. See [SwiftVISASwift](https://github.com/SwiftVISA/SwiftVISASwift) for details
of how to use this.

Usage
-----

To create a connection to an instrument over USB, pass the USB details to
`InstrumentManager.shared.instrumentAt(vendorID:productID:)` or
`InstrumentManager.shared.instrumentAt(vendorID:productID:serialNumber:)`.

This will fail if the identified device does not support the USB Test and Measurement Class
device protocol, such as if you try to connect to a hub or mass storage device.

Once connected, the instrument conforms to the MessageBasedInstrument protocol, so messages
can be sent and received using the full functionality of MessageBasedInstruments.

```
// Example code interacting with a Keysight E36103B oscilloscope over USB
do {
    try let instrument = InstrumentManager.shared.instrumentAt(vendorID: 10893, productID: 5634)
    try instrument.write("VOLTAGE 3.3")
    try instrument.query("VOLTAGE?")
    try instrument.write("OUTPUT ON")
} catch {
    // Could not complete conversation
}
```

Class Summary
-------------

### USBTMCInstrument

This is the instrument class created by `InstrumentManager.shared.instrumentAt(vendorID:productID:)`.
It can also be created with its own constructors `USBTMCInstrument(vendorID:productID:)` or
`USBTMCInstrument(visaString:)` to parse the VISA string for you. Parsing a VISA string for
USB instruments has not been added to InstrumentManager yet.

This class is only able to communicate with devices that support the USB Test and Measurement
Class device protocol. Other Instrument classes may be made to communicate with other types
of devices, using USBTMCInstrument as an example.

This class conforms to the Instrument and MessageBasedInstrument protocols. It uses 
`USBSession` as the Session required by the Instrument protocol.

### USBSession

This is a general Session class that manages a connection to a USB device. It is currently
used by `USBInstrument` and `USBTMCInstrument`, and can be used by custom USB Instrument
classes. Its constructor `USBSession(vendorID:productID:serialNumber:)` has the same semantics
as `InstrumentManager.shared.instrumentAt(vendorID:productID:serialNumber:)`: it will look
for a matching device, connect to it, and throw an error if no matching device was found or
if multiple matching devices were found. Instrument classes are responsible for examining the
returned device to see if it supports the intended communication protocol.
