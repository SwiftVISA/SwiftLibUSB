//command line main file
#include <stdio.h>


#include "argproc.h"
#include "usb.h"

int printDevice(struct libusb_device *device, short verbosity){
	int portNumber = libusb_get_port_number(device);
	struct libusb_device_descriptor desc;
    int desc_code = libusb_get_device_descriptor(device, &desc);
	if(desc_code != 0){
		// If there is an error loading more information
		printf("Port %d: %s\n",
			portNumber // Include the port
		); 
		libusb_error_name(desc_code); // Describe the error
	}else{
		// If we get information
		uint16_t  vendorID = desc.idVendor;
		uint16_t  productID = desc.idProduct;
		uint8_t  serialID = desc.iSerialNumber;	

		printf("Port %d: Vendor Id(%d), Product ID(%d), Serial ID(%d)\n", 
			portNumber, // Include the port
			vendorID,
			productID,
			serialID
		);
	}
}

int do_connect(struct arg_info *args)
{
	printf("Connecting to device with vendor id: %d and product id: %d\n",
			args->vendor_id, args->product_id);
	printf("Command: %s\n", args->message);
		
	//try to connect to device
	struct usb_data device;
	int connection_code = usb_connect(args->vendor_id, args->product_id, 
		&device);
	
	if(connection_code != 0)
	{
		printf("Error connecting to device.\n");
		return -1;
	}

		printf("Connected to device\n");
	
	//attempt to send data
	int send_code = usb_write(&device, args->message);
	
	if(send_code != 0)
	{
		printf("Error sending message.\n");
		return -1;
	}

		printf("Command sent\n");
	
	if(args->needs_response)
	{
		printf("Awaiting response.\n");
		char buff[1024];
		int read_code = usb_read(&device, buff, 1024);
		
		if(read_code != 0)
		{
			printf("Error reading response from device.\n");
			return -1;
		}
		
		//pass in the buffer after the end of the header
		printf("%s\n", &buff[12]);
	}
	
	usb_close(&device);
}

int displayDevices(struct arg_info *commandArguments){
	short verbosity = commandArguments->display_level;
	
	// Setup

	libusb_device **devices; // Store the list of devices. Allocated by libusb

    ssize_t count = libusb_get_device_list(NULL, &devices); // The first argument could be a context, if we cared about not sharing sessions.
    
	printf(" - Device List (%d) - \n",count);

	// Normally, libusb_get_device_list returns a nonnegative number. If it's negative, there was an error.
    if (count < 0)
    {
        printf("No Devices Found: %s\n",libusb_error_name(count));
        return 1;
    }

	// For each device, print device
    for (ssize_t i = 0; i < count; i++)
    {
		printDevice(devices[i],verbosity);
	}
	// Cleanup
 	libusb_free_device_list(devices, 1); // free devices
}

int main(int argc, char** argv)
{	
	// Initilise libUSB
	int init_error = libusb_init(NULL);
    if (init_error != 0) {
        printf("Failed to initialize libUSB");
        return -1;
    }

	struct arg_info args;
	int argproc_code = process_args(argc, argv, &args);
	
	if(argproc_code == ARGPROC_ERROR) {return -1; }
	
	// List all devices if flagged to
	if(args.display_level > 0){
		displayDevices(&args);
	}
	
	// If the user wants to connect to a device
	if(args.do_connect){
		do_connect(&args);
	}
	return 0;
}

