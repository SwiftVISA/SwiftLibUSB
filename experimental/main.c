// Test program for learning how to use libusb
// Compile with `gcc -o main main.c -lusb-1.0` or similar

#include <libusb-1.0/libusb.h>
#include <stdio.h>

int main() {
    int error = libusb_init(NULL);
    if (error == 0) {
        printf("Initialized successfully\n");
        libusb_exit(NULL);
        return 0;
    } else {
        printf("Initialization failed with error code %d", error);
        return 1;
    }
}