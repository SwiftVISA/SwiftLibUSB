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
These classes all conform to protocols described in CoreSwiftVisa. These are high level and are the most user friendly.

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
These classes are all in the LibUSBWrapper folder. They are low level classes for interacting with the [libUSB](https://libusb.sourceforge.io/api-1.0/index.html) library. They are only needed when implementing new instruments or writing very low-level drivers; for communicating with typical lab equipment see the `USBTMCInstrument` class.

The general workflow for using these classes is:
 * Create a `Context`
 * Find the `Device` you want to communicate with
 * Select a `Configuration`
 * Find an `AltSetting` that supports the communication protocol you want,
   then cmail that `Interface` and set the `AltSetting` active.
 * Find the `Endpoint`s you will use to transfer data
 * Send and receive data over the `Endpoint`s.

An example of how this might look is shown below.

```swift
do {
    let context = try Context()

    // Find an appropriate device by vendor ID and product ID
    // vendorId and productId must have been defined previously
    var device: Device? = nil
    for dev in context.devices {
        if dev.vendorId == vendorId && dev.productId == productId {
            device = dev
            break
        }
    }
    guard let device = device else {
        throw USBError.other
    }

    // Find an AltSetting that supports the USBTMC protocol
    var altSetting: AltSetting? = nil
    for config in device.configurations {
        for interface in config.interfaces {
            for setting in interface.altSettings {
                if setting.interfaceClass == .application &&
                  setting.interfaceSubClass == 3 {
                    // Set up the configuration settings so we can use them.
                    try config.setActive()
                    try interface.claim()
                    try setting.setActive()
                    altSetting = setting
                    break
                }
            }
        }
    }
    guard let altSetting = altSetting else {
        // No supported AltSetting was found
        throw USBError.other
    }

    // Find the in and out endpoints
    var inEndpoint: Endpoint? = nil
    var outEndpoint: Endpoint? = nil
    for endpoint in altSetting.endpoints where endpoint.transferType == .bulk {
        if endpoint.direction == .in {
            inEndpoint = endpoint
        } else if endpoint.direction == .out {
            outEndpoint = endpoint
        }
    }
    guard let inEndpoint = inEndpoint, let outEndpoint = outEndpoint else {
        // The required endpoints weren't found
        throw USBError.other
    }

    // Communicate with the device

    // Send the bytes for an "OUTPUT ON" command
    var outputOn = Data([1, 1, 254, 0, 10, 0, 0, 0, 1, 0, 0, 0, 79, 85, 84, 80, 85, 84, 32, 79, 78, 10, 0, 0])
    try outEndpoint.sendBulkTransfer(data: &outputOn)

    // Send the bytes for a "VOLT?" request
    var volt = Data([1, 2, 253, 0, 6, 0, 0, 0, 1, 0, 0, 0, 86, 79, 76, 84, 63, 10, 0, 0])
    try outEndpoint.sendBulkTransfer(data: &volt)

    // Send a request to get the response in a 256 byte buffer
    var responseRequest = Data([2, 3, 252, 0, 0, 1, 0, 0, 0, 0, 0, 0])
    try outEndpoint.sendBulkTransfer(data: &responseRequest)

    // Get the response
    let response = try inEndpoint.receiveBulkTransfer(256)

    // Skip the header when printing the response
    print(String(data: response[12...], encoding: .ascii))

    // No cleanup is necessary
} catch {
    // Some error occured
    print("Couldn't connect to device.")
}
```

### Context

The first step in interacting with a device using libUSB directly is creating a `Context`. The `Context` creates a list of all devices connected to the host when it is created, and these devices can be accessed using the `devices` property.

```
// Create a context and get the devices
do {
    try context = Context()
    let deviceList = context.devices
} catch {
    // The context could not be made
}
```

### Device

The `Context.devices` array contains one `Device` object for each physical device libUSB identifies when the `Context` is created. They can be identified using the `vendorID`, `productID`, and `serialNumber` properties. The `displayName` property can also be useful if the device provides a name.

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

Devices are opened for communication upon creation; they can be closed or reopened using the `close` and `reopen` methods. Before communication can actually happen, a `Configuration` must also be made active, one or more `Interface`s must be claimed, and an `AltSetting` for each `Interface` must be made active.

Control messages can be sent to a device using the `sendControlTransfer` method.
This should only be used for messages defined by device classes, such as the USBTMC GET_CAPABILITIES message. Messages used for getting device descriptors and configuration are handle by libUSB.

### Configuration

Before a device's endpoints can be used, a `Configuration` containing that endpoint must be made active through `setActive()`. Each device lists offered `Configurations` in the `configurations` property. Configurations describe information like the maximum power the device will draw. Configurations contain an array of `Interface`s in the `interfaces` property.

### Interface

An `Interface` describes an independent set of endpoints intended to be used together. An `Interface` must be claimed before any of its endpoints can be used. Each `Interface` might support multiple communication protocols. These are described by the `Interface`'s `AltSetting`s, listed in the `altSettings` property.

### AltSetting

Each `AltSetting` describes what role the endpoints in the `Interface` play. This is described through their `interfaceClass`, `interfaceSubClass` and `interfaceProtocol`. `AltSetting`s contain a list of the `Endpoint`s contained in the interface in the `endpoints` property. `AltSetting`s in the same `Interface` have the same endpoint numbers, but the transfer types may not be the same.

### Endpoint

`Endpoint`s send and receive messages from the device. The two most important properties are `direction` and `transferType`. `out` direction endpoints send data from the host to the device. `in` direction endpoints recieve data from the device. `bulk` endpoints send single, possibly large, chunks of data. `isochronous` endpoints stream data, such as audio, in many small packets. `interrupt` endpoints send small amounts of data for important events. So far, communication has only been implemented in this class for `bulk` `Endpoint`s.

So long as the `AltSetting` that holds this endpoint has been made active, the `Interface` has been claimed and the `Configuration` containing the `Interface` set active, the endpoint is ready for transfering data. The methods `sendBulkTransfer` and `receiveBulkTransfer` can be used to send messages on bulk endpoints. Interrupt and isochronous transfers are not yet supported.

When sending messages, be aware that device classes may require specific formatting or encoding of the data. This class does not make any modifications to the data provided; it is the user's responsibility to ensure the bytes given are formatted correctly for the device.
