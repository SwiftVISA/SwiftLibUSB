// Test program for learning how to use libusb
// Compile with `gcc -o main main.c -lusb-1.0` or similar

#include <libusb-1.0/libusb.h>
#include <stdio.h>

// Prints the port each device is plugged into
int list_devices() {
    // This will store the list of devices. It is allovated by libusb
    libusb_device **devices;

    // The first argument could be a context, if we cared about not sharing sessions.
    ssize_t count = libusb_get_device_list(NULL, &devices);

    // Normally, libusb_get_device_list returns a nonnegative number. If it's negative, there was an error.
    if (count < 0) {
        printf("Error listing devices: %f\n", count);
        return 1;
    }

    // For each device, print the port number.
    for (ssize_t i = 0; i < count; i++) {
        printf("Device connected on port %d\n", libusb_get_port_number(devices[i]));
    }

    // Deallocate the device list
    // Also unref the devices in the list
    libusb_free_device_list(devices, 1);
    return 0;
}

int main() {
    int error = libusb_init(NULL);
    if (error == 0) {
        printf("Initialized successfully\n");
        list_devices();
        libusb_exit(NULL);
        return 0;
    } else {
        printf("Initialization failed with error code %d", error);
        return 1;
    }
}
