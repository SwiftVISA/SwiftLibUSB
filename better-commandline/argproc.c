#include "argproc.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

int process_args(int argc, char** argv, struct arg_info* ret)
{
	if (argc != 7)
	{
		printf("Arguemnt Error: Invalid number of arguments: 6 expected\n");
		return ARGPROC_ERROR;
	}
	
	bool did_v = false;
	bool did_p = false;
	bool did_m = false;
	
	for(int i = 1; i <= 5; i += 2)
	{
		if(strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "-V") == 0) //vendor id
		{
			ret->vendor_id = atoi(argv[i+1]);
			did_v = true;
		}else if(strcmp(argv[i], "-p") == 0 || strcmp(argv[i], "-P") == 0) //product id
		{
			ret->product_id = atoi(argv[i+1]);
			did_p = true;
		}else if(strcmp(argv[i], "-c") == 0 || strcmp(argv[i], "-C") == 0) //command
		{
			ret->needs_response = false;
			ret->message = argv[i+1];
			did_m = true;
		}else if(strcmp(argv[i], "-q") == 0 || strcmp(argv[i], "-Q") == 0) //query
		{
			ret->needs_response = true;
			ret->message = argv[i+1];
			did_m = true;
		}else
		{
			printf("Argument Error: Unknown argument %s\n", argv[i]);
			return ARGPROC_ERROR;
		}
	}
	
	if(!did_v)
	{
		printf("Argument Error: no vendor id specified\n");
		return ARGPROC_ERROR;
	}
	
	if(!did_p)
	{
		printf("Argument Error: no product id specified\n");
		return ARGPROC_ERROR;
	}
	
	if(!did_m)
	{
		printf("Argument Error: no command or query given\n");
		return ARGPROC_ERROR;
	}
	
	return ARGPROC_SUCESS;
}
