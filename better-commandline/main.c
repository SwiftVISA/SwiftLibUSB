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
	struct arg_info args = process_args(argc, argv);
	return 0;
}
