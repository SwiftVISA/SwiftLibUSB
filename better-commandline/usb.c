#include <stdio.h>
#include "usb.h"

int usb_connect(unsigned short vendor_id, unsigned short product_id, struct usb_data *usb) {
    libusb_device **devices;
    ssize_t count = libusb_get_device_list(NULL, &devices);
    if (count < 0) {
        printf("Error detecting devices: %d\n", count);
    }

    for (ssize_t i = 0; i < count; i++) {
        struct libusb_device_descriptor desc;
        int desc_code = libusb_get_device_descriptor(devices[i], &desc);
        if (desc_code != 0) {
            printf("Error getting device descriptor: %d\n", desc_code);
        } else if (desc.idVendor == vendor_id && desc.idProduct == product_id) {
            int open_code = libusb_open(devices[i], &usb->handle);
            if (open_code != 0) {
                printf("Error connecting to device: %d\n", desc_code);
                libusb_free_device_list(devices, 1);
                return -1;
            }
#ifdef __linux__
            libusb_det_auto_detach_kernel_driver(usb->handle, 1);
#endif
            int configure_code = libusb_set_configuration(usb->handle, 0);
            if (configure_code != 0 && configure_code != -12) { // -12 means the OS configures the device
                printf("Error configuring device: %d\n", configure_code);
                libusb_close(usb->handle);
                libusb_free_device_list(devices, 1);
                return -1;
            }
            struct libusb_config_descriptor *config;
            int config_desc_code = libusb_get_active_config_descriptor(devices[i], &config);
            if (config_desc_code != 0) {
                printf("Error getting config descriptor: %d\n", config_desc_code);
                libusb_close(usb->handle);
                libusb_free_device_list(devices, 1);
                return -1;
            }
            int claim_error = libusb_claim_interface(usb->handle, 0);
            if (claim_error != 0) {
                printf("Error claiming interface: %d\n", claim_error);
                libusb_free_config_descriptor(config);
                libusb_close(usb->handle);
                libusb_free_device_list(devices, 1);
                return -1;
            }
            int alt_error = libusb_set_interface_alt_setting(usb->handle, 0, 0);
            if (alt_error != 0) {
                printf("Error setting alternative interface: %d\n", alt_error);
                libusb_free_config_descriptor(config);
                libusb_close(usb->handle);
                libusb_free_device_list(devices, 1);
                return -1;
            }
            int has_out = 0;
            int has_in = 0;
            const struct libusb_endpoint_descriptor *endpoints = config->interface[0].altsetting->endpoint;
            for (int j = 0; j < config->interface[0].altsetting->bNumEndpoints; j++) {
                if (endpoints[j].bmAttributes & 3 == LIBUSB_ENDPOINT_TRANSFER_TYPE_BULK) {
                    if (endpoints[j].bEndpointAddress >> 7 == LIBUSB_ENDPOINT_OUT) {
                        usb->out_endpoint = endpoints[j].bEndpointAddress;
                        has_out = 1;
                    } else {
                        usb->in_endpoint = endpoints[j].bEndpointAddress;
                        has_in = 1;
                    }
                }
            }
            if (has_out == 0) {
                printf("Missing out endpoint on device\n");
                libusb_free_config_descriptor(config);
                libusb_close(usb->handle);
                libusb_free_device_list(devices, 1);
                return -1;
            }
            if (has_in == 0) {
                printf("Missing in endpoint on device\n");
                libusb_free_config_descriptor(config);
                libusb_close(usb->handle);
                libusb_free_device_list(devices, 1);
                return -1;
            }
            libusb_free_config_descriptor(config);
            libusb_free_device_list(devices, 1);
            return 0;
        }
    }
    printf("Didn't find matching device\n");
    libusb_free_device_list(devices, 1);
    return -1;
}

int usb_write(struct usb_data *usb, const char *message) {
    return -1;
}

int usb_read(struct usb_data *usb, char *buffer, unsigned int size) {
    return -1;
}

int usb_close(struct usb_data *data) {
    return 0;
}