SwiftLibUSB
===========

This is an example Xcode project that communicates with USB devices.

The important classes are in the SwiftVisaClasses and Usb groups.

SwiftVisaClasses
----------------

### USBTMCInstrument

This represents a device connected over USB that uses the USBTMC interface
(most VISA-compatible lab equipment should do this). It conforms to
MessageBasedInstrument from coreSwiftVISA, so it can be used to send and
receive messages just like any other instrument.

To create a USBTMC instrument, you will need to provide the vendor ID, product
ID, and optionally serial number. In a VISA identifier string, these appear in
order:

    USB::<vendor ID>::<product ID>::<serial number>::...

The vendor ID and product ID are shared across the same type of device, so the
serial number is required if multiple of the same type of device are connected.
If a matching device is not found, or if multiple matching devices are found,
the constructor will throw an appropriate error.

### USBInstrument

This represents a generic USB device. It defines common errors for USB devices
and contains code to connect to a device using the vendor ID, product ID, and
serial number, but does not provide any methods for communicating with the
device. Using a subclass of USBInstrument such as USBTMCinstrument is required
to format the messages so the device will understand. 

### USBSession

This is the session type used by USBInstrument and USBTMCInstrument. It
internally manages the Context and Device representing the connection. 

USB Wrapper Classes
-------------------

These classes are in the Usb group within the project. They form a tree, and
the entire depth of the tree must be traversed in order to communicate with a
device. Any object will keep the internal libUSB structs it depends on alive as
long as the object is kept, so objects higher in the tree do not need to be kept
once they are no longer needed.

### Usage summary

 * Create a Context
 * Loop through `context.devices` until you find the device you want
 * Select a configuration from `device.configurations` and activate it using
   `config.setActive()`
 * Loop through `config.interfaces` and check `interface.altSettings` for one
   that understands the protocol you want.
 * Claim the interface using `interface.claim()` and activate the altSetting
   using `setting.setActive()`
 * Look through `setting.endpoints` for endpoints that match your purposes
 * Use the endpoints to send and receive data from the device

All libUSB resources will be freed in the proper order once all references to
them are released.

### Context

A Context manages all connections to USB devices. It exposes an array of Devices
through the `devices` property that can be searched to find the one you want.

It is safe to have multiple Contexts simultaneously, but they will expose
identical Devices. Attempting to use the same device from Devices created from
different Contexts will probably not work.

### Device

A Device represents a connected USB device. It exposes an array of
Configurations through the `configurations` property, one of which must be
selected before communication can happen.

### Configuration

A Configuration represents a possible way in which the device could be set up
to interact with the host. This mostly only determines the maximum power draw.
In most cases, selecting the first configuration will be what is wanted.

Before using a Configuration, it must be made active using the `setActive`
method. Only one Configuration can be active at a time.

A Configuration exposes an array of Interfaces through the `interfaces`
property.

### Interface

An Interface represents a set of endpoints on the device that can be used
together. An Interface must be claimed before the endpoints can be used.
Multiple Interfaces can be claimed independently.

Each Interface includes a list of AltSettings in the `altSettings` property.

### AltSetting

An AltSetting determines how the endpoints within an interface are used. The
`interfaceClass`, `interfaceSubClass`, and `interfaceProtocol` properties have
values specified in USB standards, and can be used to identify the communication
protocol. USBTMC AltSettings have `interfaceClass == .application`, 
`interfaceSubClass == 3`, and
`interfaceProtocol == 0 || interfaceProtocol == 1`.

An AltSetting needs to be set so that the device will interpret the messages
properly. The first AltSetting is probably set by default, but they can be set
manually by calling the `setActive` method.

Each AltSetting has a list of Endpoints that are used for actual communication.

### Endpoint

An Endpoint is a channel for data transfer with the device. Before using it,
the enclosing Configuration must be made active, the Interface must be claimed,
and the AltSetting must be set.

Endpoints come in six types determined by two properties: `direction` and
`transferType`. `direction` can be either `.in` or `.out`, referring to whether
the data flows in from the device to the host or out from the host to the
device.

Bulk transfers are used for sending single messages that must be received
without transmission errors, such as SCPI commands. To send a bulk transfer, use
the `sendBulkTransfer` method passing in the raw bytes to send. To receive a
bulk transfer from the device, use the `receiveBulkTransfer` method passing in
the maximum size of data to receive.

Interrupt transfers are used for sudden messages from the device. These should
be able to be implemented in a very similar way as bulk transfers.

Isochronous transfers are used for streaming data such as audio. These cannot
be implemented in the same way as bulk transfers, as they require using libUSB's
asynchronous transfer API.

### Internal classes

Since the wrapper classes have strong references to their children, the tree
created is freed from top to bottom, or Context to Endpoint. LibUSB requires
its components to be freed in the opposite order, bottom to top. To accomplish
this, most classes have an associated `*Ref` class (e.g. `ContextRef`) that
is responsible for freeing the libUSB object. These classes hold strong
references to their parent object, ensuring that the parent object remains alive
until the child object is freed. They also expose some properties from the
wrapped libUSB object to make the public classes slightly cleaner.
