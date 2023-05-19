#ifndef USB_H
#define USB_H

#include <libusb-1.0/libusb.h>

struct usb_data {
    struct libusb_device_handle *handle;
    unsigned char out_endpoint;
    unsigned char in_endpoint;
};

int usb_connect(unsigned short vendor_id, unsigned short product_id, struct usb_data *usb);

int usb_write(struct usb_data *usb, const char *message);

int usb_read(struct usb_data *usb, char *buffer, unsigned int size);

int usb_close(struct usb_data *usb);

#endif // USB_H
