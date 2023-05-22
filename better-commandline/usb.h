#ifndef USB_H
#define USB_H

#include <libusb-1.0/libusb.h>

// This struct hold the information for a single USB device
struct usb_data {
    struct libusb_device_handle *handle;
    unsigned char out_endpoint;
    unsigned char in_endpoint; 
};

/*
Neccesary initiliser for usb devices. Will open a connection to the device with the desired device and product id's
@Params:
    unsigned short vendor_id: The vendor id to find, used in combination with product id to form a primary key
    unsigned short product_id: The product id to find
    struct usb_data *usb: The usb to connect with 
@Returns
    0 if successful
    -1 otherwise
*/
int usb_connect(unsigned short vendor_id, unsigned short product_id, struct usb_data *usb);

/*
Send some command over USB. The message does not include any headers, padding or terminating newlines.
The usb should be connected first before commands are sent
@Params:
    struct usb_data *usb: The usb to send the write command with
    cost char *message: The message to send 
@Returns
    0 if successful
    -1 otherwise
*/
int usb_write(struct usb_data *usb, const char *message);

/*
Read data over USB.
The usb should be connected first before commands are sent
@Params:
    struct usb_data *usb: The usb to read the data from
    cost char *buffer: the array for data to be loaded to
    int size: the size of the buffer
@Returns
    0 if successful
    -1 otherwise
*/
int usb_read(struct usb_data *usb, char *buffer, unsigned int size);

/*
    Closes the handle of the given USB
@Params:
    struct usb_data *usb: The usb to read the data from
@Returns
    0 if successful
    -1 otherwise
*/
int usb_close(struct usb_data *usb);

#endif // USB_H
