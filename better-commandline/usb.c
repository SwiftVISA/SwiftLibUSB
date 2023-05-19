#include "usb.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Constants
#define timeout 10000 // The amount of time to wait before giving up on a message. Measured in milliseconds.
#define writeTo 1 // Code to write to a device
#define readFrom 2 // Code to read from a device

// Private variables //TODO: Integrate into usb.h usb struct.
int callbackReturned; // Has the callback function been executed or the most recent command
unsigned char messageIndex; // The message id, always ranges between 1 and 255
int callbackError; // The error of the most recent callback

// helper methods
void LIBUSB_CALL callback(struct libusb_transfer *info){
	callbackReturned = 1;
    if(info->actual_length == info->length){
        callbackError = 0; // Everything was fine
    }else{
        callbackError = -1; // Not all the bytes were sent, error
    }
}

/* This method does the bulk of the logic for USB communication. 
It takes the desired command, the endpoint to communicate with and the direction of communication as inputs
It adds the neccesary header,newline and padding to correctly send messages 
@Params:
    usb: The usb device used for the connection. Must be connected first
    data: The command to send to the device. Example: "OUTPUT ON"
    endpoint: The address of the endpoint to send to, should be a bulk endpoint
    messageType: The message type to include in the header. 1 is for sending 2 is for recieving
@Returns:
    int: 0 for success, -1 otherwise

*/
int raw_write(struct usb_data *usb, const unsigned char *data,char endpoint,unsigned char messageType){
	struct libusb_device_handle *deviceHandle = usb->handle;
    
    // Generate transfer
    struct libusb_transfer *transfer = libusb_alloc_transfer(0);
    int length = strlen(data);

    // Assign bits
    int size = 13 + strlen(data);
    size = size + ((4 - (size % 4)) % 4);
    unsigned char *message = (unsigned char *) malloc(size * sizeof(char));
    memset(message, 0, size);
    message[0] = messageType;
    message[1] = messageIndex;
    message[2] = ~messageIndex;
    // message[3] is padding
    message[4] = length & 0xFF;
    message[5] = (length >> 8) & 0xFF;
    message[6] = (length >> 16) & 0xFF;
    message[7] = (length >> 24) & 0xFF;
    message[8] = 1; // EOF bit
    // 9, 10, and 11 are padding
    strcpy(message+12,data);
    message[12+length] = '\n';
    
    for(int i = 0; i < size; i++){
        printf("%d ",message[i]);
    }

    libusb_fill_bulk_transfer(transfer,deviceHandle,endpoint,message,size,&callback,0,timeout);
	
	// Send Transfer
	callbackReturned = 0;
	
	//libusb_wait_for_event(NULL,NULL);
	libusb_handle_events_completed(NULL, &callbackReturned);

	// Clear the transfer
	libusb_free_transfer(transfer);
	free(message);
    messageIndex += 1;
    if(messageIndex == 0){
        messageIndex +=1 ;
    }

    return callbackError;
}

// .h methods
int usb_connect(unsigned short vendor_id, unsigned short product_id, struct usb_data *usb) {
    int init_error = libusb_init(NULL);
    if (init_error != 0) {
        printf("Failed to initialize libUSB");
        return -1;
    }
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
            
            libusb_set_auto_detach_kernel_driver(usb->handle, 1);
            
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
            printf("Looking for endpoints: Bulk: %d, Out: %d, In: %d\n", LIBUSB_ENDPOINT_TRANSFER_TYPE_BULK, LIBUSB_ENDPOINT_OUT, LIBUSB_ENDPOINT_IN);
            for (int j = 0; j < config->interface[0].altsetting->bNumEndpoints; j++) {
                printf("DEBUG: endpoint found: attributes: %d, address: %d\n", endpoints[j].bmAttributes, endpoints[j].bEndpointAddress);
                if ((endpoints[j].bmAttributes & 3) == LIBUSB_ENDPOINT_TRANSFER_TYPE_BULK) {
                    printf("DEBUG: found bulk transfer endpoint\n");
                    if ((endpoints[j].bEndpointAddress >> 7) == LIBUSB_ENDPOINT_OUT) {
                        printf("DEBUG: found out endpoint\n");
                        usb->out_endpoint = endpoints[j].bEndpointAddress;
                        has_out = 1;
                    } else {
                        printf("DEBUG: found in endpoint\n");
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
            messageIndex = 1;
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
    return raw_write(usb,message,usb->out_endpoint,writeTo);
}

int usb_read(struct usb_data *usb, char *buffer, unsigned int size) {
    return raw_write(usb,buffer,usb->in_endpoint,2);;
}

int usb_close(struct usb_data *usb) {
    return -1;
}
