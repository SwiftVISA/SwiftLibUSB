//command line main file
#include <stdio.h>

#include "argproc.h"
#include "usb.h"

int main(int argc, char** argv)
{
	struct arg_info args;
	int argproc_code = process_args(argc, argv, &args);
	
	if(argproc_code == ARGPROC_ERROR) {return -1; }
	
	printf("Connecting to device with vendor id: %d and product id: %d\n",
		args.vendor_id, args.product_id);
	printf("Command: %s\n", args.message);
	
	//try to connect to device
	struct usb_data device;
	int connection_code = usb_connect(args.vendor_id, args.product_id, 
		&device);
	
	if(connection_code != 0)
	{
		printf("Error connecting to device.\n");
		return -1;
	}
	
	//attempt to send data
	int send_code = usb_write(&device, args.message);
	
	if(send_code != 0)
	{
		printf("Error sending message.\n");
		return -1;
	}
	
	if(args.needs_response)
	{
		printf("Awaiting response.\n");
		char buff[1024];
		int read_code = usb_read(&device, buff, 1024);
		
		if(read_code != 0)
		{
			printf("Error reading response from device.\n");
			return -1;
		}
		
		printf("%s\n", buff);
	}
	
	
	return 0;
}
