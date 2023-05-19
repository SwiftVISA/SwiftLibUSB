#include "usb.h"

int usb_connect(unsigned short vendor_id, unsigned short product_id, struct usb_data *usb) {
    return -1;
}

int usb_write(struct usb_data *usb, const char *message) {
    return -1;
}

int usb_read(struct usb_data *usb, char *buffer, unsigned int size) {
    return -1;
}