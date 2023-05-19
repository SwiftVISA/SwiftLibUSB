#include "usb.h"

// Constants
#define timeout 10000 // The amount of time to wait before giving up on a message. Measured in milliseconds.

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
    int size = 12 + strlen(data);
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
    // 9, 10, 11 are padding
    strcpy(message+12,data);
    
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
    return raw_write(usb,message,usb->out_endpoint,1);
}

int usb_read(struct usb_data *usb, char *buffer, unsigned int size) {
    return raw_write(usb,buffer,usb->in_endpoint,2);;
}

int usb_close(struct usb_data *usb) {
    return -1;
}