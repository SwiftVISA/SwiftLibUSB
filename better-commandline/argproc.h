#ifndef ARGPROC_H
#define ARGPROC_H

#include <stdint.h>
#include <stdbool.h>

#define ARGPROC_SUCESS 0
#define ARGPROC_ERROR -1


struct arg_info
{
	uint16_t vendor_id;
	uint16_t product_id;
	bool	 needs_response;
	char*    message;
};

int process_args(int argc, char** argv, struct arg_info* ret);

#endif
