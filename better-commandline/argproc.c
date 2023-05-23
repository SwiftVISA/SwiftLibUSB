#include "argproc.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

bool parse_num(const char *str, unsigned short *value)
{
    *value = 0;

    while (str[0] != 0)
    {
        if ('0' <= str[0] && str[0] <= '9')
        {
            *value *= 10;
            *value += (str[0] - '0');
        }
        else
        {
            return false; 
        }
        str++;
    }
    return true;
}

int process_args(int argc, char** argv, struct arg_info* ret)
{
	ret->do_connect = true; // By default we do a command
	
	//initalize some flags for use later
	bool did_v = false;
	bool did_p = false;
	bool did_m = false;
	bool did_disp = false;
	
	//loop through all args. Step in pairs by 2 (first argument is the 
	//switch and the second is the value)
	for(int i = 1; i < argc; i += 2)
	{
		if(strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "-V") == 0) //vendor id
		{
			did_v = parse_num(argv[i+1], &ret->vendor_id);
			if (!did_v)
			{
				printf("Argument error: vendor id must be a number, not '%s'\n", argv[i+1]);
				return ARGPROC_ERROR;
            }
		}else if(strcmp(argv[i], "-p") == 0 || strcmp(argv[i], "-P") == 0) //product id
		{
			did_p = parse_num(argv[i+1], &ret->product_id);
			if (!did_p)
			{
				printf("Argument error: product id must be a number, not '%s'\n", argv[i+1]);
				return ARGPROC_ERROR;
            }
		}else if(strcmp(argv[i], "-disp") == 0 || strcmp(argv[i], "-DISP") == 0 || strcmp(argv[i], "-Disp") == 0) // display level
		{
			did_disp = parse_num(argv[i+1], &ret->display_level);
			if (!did_disp)
			{
				printf("Argument error: display_level must be a number, not '%s'\n", argv[i+1]);
				return ARGPROC_ERROR;
            }
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

	//validate arguments
	// If you did only display 
	if(did_disp && !did_v && !did_p && !did_m){
		ret->do_connect = false;
		return ARGPROC_SUCCESS;
	}

	// If you are not display or specified atleast one argument
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
	return ARGPROC_SUCCESS;
}