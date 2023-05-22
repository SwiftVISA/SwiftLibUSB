#ifndef ARGPROC_H
#define ARGPROC_H

#include <stdint.h>
#include <stdbool.h>

#define ARGPROC_SUCCESS 0
#define ARGPROC_ERROR -1


struct arg_info
{
	uint16_t vendor_id;
	uint16_t product_id;
	bool	 needs_response;
	bool	 do_connect;
	unsigned short	display_level;
	char*    message;
};

//process arguments and return results in arg_info struct
//returns 0 on success and -1 on failure 
int process_args(int argc, char** argv, struct arg_info* ret);

#endif //ARGPROC_H
