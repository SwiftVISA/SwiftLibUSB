#include "usb.h"

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
    message[8] = 1;
    // 9, 10, and 11 are padding
    strcpy(message+12,data);
    message[12+length] = '\n';
    
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
    messageIndex = 0;
    return -1;
}

int usb_write(struct usb_data *usb, const char *message) {
    return raw_write(usb,message,usb->out_endpoint,writeTo);
}

int usb_read(struct usb_data *usb, char *buffer, unsigned int size) {
    return -1;
}

int usb_close(struct usb_data *usb) {
    return -1;
}