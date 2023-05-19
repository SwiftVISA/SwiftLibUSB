#ifndef ARGPROC_H
#define ARGPROC_H

#include <stdint.h>
#include <stdbool.h>

struct arg_info
{
	uint16_t vendor_id;
	uint16_t product_id;
	bool	 needs_response;
	char*    message;
};

struct arg_info process_args(int argc, char** argv);

#endif
