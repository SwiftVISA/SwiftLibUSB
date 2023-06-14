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
// Example code interacting with a Keysight E36103B power supply over USB
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
These classes all conform to protocols described in CoreSwiftVisa. These are high level and are the most user friendly

### USBTMCInstrument

This is the instrument class created by `InstrumentManager.shared.instrumentAt(vendorID:productID:)`.
It can also be created with its own constructors `USBTMCInstrument(vendorID:productID:)` or
`USBTMCInstrument(visaString:)` to parse the VISA string for you. 

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

Wrapper Class Summary
---------------------
These classes are all in the LibUSBWrapper folder. They are low level classes for interacting with the libUSB library. 

### Context

The first step in interacting with a device using libUSB directly is creating a context. It is from the context that you get the device list. This is how one might do this
```
// Create a context and get the devices
do {
    try context = Context()
    let deviceList = context.devices
} catch {
    // The context could not be made
}
```
The device list stores Device objects

### Device

A class representing a device. The best way to get the device instance that corresponds to a specific physical device is to look through the "devices" array given by context until you find the desired the device. Devices are identified by their productId, vendorId and serialNumber. The serial number is only required if there are multiple of the same kind of device connected at a time.
```
// Example of finding a device with a specific vendor ID and product ID
// Once found, it requests the name of the device's manufacturer and prints it
let context = Context()
for device in context.devices {
    if device.productId == productID &&
       device.vendorId == vendorID {
            print(device.manufacturerName)
       }
  }
```
Device objects manage both the device and the device handle. Devices are open upon intilizing, but can be closed or reopened with the corresponding methods. Device makes available the sendControlTransfer method for sending USB control transfers. The more common kind of transfer is USB bulk transfers. These are the kind used to send commands to USBTMC devices and other relevant transfers. These are accomplished in the Endpoint Class

### Configuration
Before a device's endpoints can be used, a configuration containing that endpoint must be made active through setActive(). Each device has configurations. Configurations also describe information like the maximum power the device will draw. Configurations have different interfaces

### Interface
An interface describes a set of endpoints. An interface must be claimed before any of its endpoints can be used. Each interface might have multiple ways it can be interacted with. These are described by the interface's AltSettings

### AltSetting
Each altsetting describes what role the endpoints in the interface play. This is described through their class, subclass and protocol. If you want to know which configuration to make active and which interface to claim, look for which one has an altsetting that fits your needs. Before any of the altsettings endpoints can be used, it must be claimed. Each altsettings store their own endpoints

### Endpoint
The point at which bulk transfers are made is called the endpoint. "Out" direction endpoints send data from the host to the device. "In" direction endpoints recieve data from the device. So long as the altsetting that holds this endpoint has been made active, the interface has been claimed and the configuration containing the interface set active, the endpoint is ready for transfering data. To send data, send the bytes (Including any header or padding bytes) to a bulk out endpoint by calling sendBulkTransfer on the bulk out endpoint with the desired bytes. To recieve data, call receiveBulkTransfer on the bulk in endpoint.
=======
