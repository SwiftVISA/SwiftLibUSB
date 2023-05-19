//command line main file
#include <libusb-1.0/libusb.h>
#include <stdio.h>
#include <string.h>

#ifdef __linux__
#include <unistd.h>
#endif

#include "argproc.h"

int main(int argc, char** argv)
{
	struct arg_info args;
	int argproc_code = process_args(argc, argv, &args);
	
	if(argproc_code == ARGPROC_ERROR) {return -1; }
	
	printf("Connecting to device with vendor id: %d and product id: %d\n",
		args.vendor_id, args.product_id);
	printf("Command: %s\n", args.message);
	if(args.needs_response)
	{
		printf("Awaiting response.\n");
	}
	
	return 0;
}
