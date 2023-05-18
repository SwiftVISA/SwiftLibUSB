// Test program for learning how to use libusb
// Compile with `gcc -o main main.c -lusb-1.0` or similar
// If it can't find libusb.h, add `-I C:/path/to/include`
// If it can't find usb-1.0, add `-L C:/path/to/lib`
// Running the code on Windows may also require copying the .dll into this folder.

#include <libusb-1.0/libusb.h>
#include <stdio.h>
#include <string.h>

// Constant variables
static const char *deviceName = "E36103B";
static libusb_device_handle *primaryDeviceHandle;
static libusb_device *primaryDevice;

const char *TRANSFER_TYPES[4] = {
    "Control",
    "Isochronous",
    "Bulk",
    "Interrupt"
};

const char *DIRECTIONS[2] = {
    "Out",
    "In"
};

// Prints the port each device is plugged into
int list_devices()
{
    // This will store the list of devices. It is allocated by libusb
    libusb_device **devices;

    // The first argument could be a context, if we cared about not sharing sessions.
    ssize_t count = libusb_get_device_list(NULL, &devices);

    // Normally, libusb_get_device_list returns a nonnegative number. If it's negative, there was an error.
    if (count < 0)
    {
        printf("Error listing devices: %f\n", count);
        return 1;
    }

    // For each device, print the port number.
    for (ssize_t i = 0; i < count; i++)
    {
        printf("Device connected on port %d\n", libusb_get_port_number(devices[i]));
        struct libusb_device_descriptor desc;
        int desc_code = libusb_get_device_descriptor(devices[i], &desc);
        if (desc_code != 0)
        {
            printf("Error getting device descriptor, error code: %d, error str: %s\n", 
            desc_code, libusb_error_name(desc_code));
        }
        else
        {
            // Print full descriptor (doesn't require communicating with device)
            printf("  Descriptor type: %d\n", desc.bDescriptorType);
            printf("  USB version: %d\n", desc.bcdUSB);
            printf("  Class: %d\n", desc.bDeviceClass);
            printf("  Subclass: %d\n", desc.bDeviceSubClass);
            printf("  Protocol: %d\n", desc.bDeviceProtocol);
            printf("  Max packet size: %d\n", desc.bMaxPacketSize0);
            printf("  Vendor ID: %d\n", desc.idVendor);
            printf("  Product ID: %d\n", desc.idProduct);
            printf("  Device version: %d\n", desc.bcdDevice);
            printf("  Configurations: %d\n", desc.bNumConfigurations);

            // open device and obtain a handle
            struct libusb_device_handle* handle;
            int open_code = libusb_open(devices[i], &handle);
            if (open_code != 0)
            {
                printf("Error opening device, error code: %d, error str: %s\n", 
                       open_code, libusb_error_name(open_code));
            }
            else
            {
                // get descriptor and print string
                unsigned char str[256];
                struct libusb_device_descriptor desc;
                int desc_code = libusb_get_device_descriptor(devices[i], &desc);
                int desc_ascii_code = libusb_get_string_descriptor_ascii(
                                          handle, desc.iProduct, str, 256);
                if(desc_code != 0)
                {
                    printf("Error getting device descriptor string, error code: %d, error str: %s\n", 
                           desc_ascii_code, libusb_error_name(desc_ascii_code));
                    // close device
                    libusb_close(handle);
                }
                else
                {
                    printf("Device Product Descriptor: '%s'\n", str);
                    // strcmp returns zero when the two strings are equal
                    if (strcmp(str, deviceName) == 0)
                    {
                        printf("Desired Device Found\n");
                        primaryDeviceHandle = handle; //save to global variable
                        primaryDevice = devices[i];
                    }
                    else
                    {
                        // close device
                        libusb_close(handle);
                    }
                }
            }
        }
        printf("\n");
    }

    // Deallocate the device list
    // Also unref the devices in the list
    libusb_free_device_list(devices, 1);
    return 0;
}

int printEndpoint(int index, const struct libusb_endpoint_descriptor endpoint){
	printf(" - Endpoint %d: Attributes(%d), Address(%d)\n",
		index, endpoint.bmAttributes, endpoint.bEndpointAddress);
	printf("      Transfer type: %s\n", TRANSFER_TYPES[endpoint.bmAttributes&3]);
	printf("      Direction: %s\n", DIRECTIONS[endpoint.bEndpointAddress >> 7]);
	printf("      Max Packet Size: %d\n", endpoint.wMaxPacketSize);
	printf("      Polling interval: %d\n", endpoint.bInterval);
}
int printAltSetting(int index, const struct libusb_interface_descriptor altSetting){
	printf("Interface Number %d: bLength: %d\n", index, altSetting.bLength);
	printf("                     bDescriptorType: %d\n", altSetting.bDescriptorType);
	printf("                     bInterfaceNumber: %d\n", altSetting.bInterfaceNumber);
	printf("                     bAlternateSetting: %d\n", altSetting.bAlternateSetting);
	printf("                     bNumEndpoints: %d\n", altSetting.bNumEndpoints);
	printf("                     bInterfaceClass: %d\n", altSetting.bInterfaceClass);
	printf("                     bInterfaceSubClass: %d\n", altSetting.bInterfaceSubClass);
	printf("                     bInterfaceProtocol: %d\n", altSetting.bInterfaceProtocol);
	printf("                     iInterface: %d\n", altSetting.iInterface);
	for(int endpointIndex = 0; endpointIndex < altSetting.bNumEndpoints; endpointIndex++){
		printEndpoint(endpointIndex,altSetting.endpoint[endpointIndex]);
	}
}

int printInterface(int index, const struct libusb_interface interface){
	int numAltSettings = interface.num_altsetting;
	printf("%d) Interface with %d altsettings: \n", index, numAltSettings);
    for(int altsettingIndex = 0; altsettingIndex < numAltSettings; altsettingIndex++){
		printAltSetting(altsettingIndex, interface.altsetting[altsettingIndex]);
    }
}
int listInterfaces(const struct libusb_interface* interfaces, int numberInterfaces){
    for (int interfaceIndex = 0; interfaceIndex < numberInterfaces; interfaceIndex++){
        printInterface(interfaceIndex,interfaces[interfaceIndex]);
    }
}

static int callbackReturned;

void LIBUSB_CALL callback(struct libusb_transfer *info){
	printf("callback with status %d, %d/%d bytes sent\n",info->status,info->actual_length,info->length);
	callbackReturned = 1;
}

int operate_primary_device() {
    printf("Operating device %s\n",deviceName);
    if(primaryDeviceHandle == NULL){
        printf("Cannot Transfer, device handler was not initialised\n");
        return -1;
    }
	
    printf("Attempting Configuration\n");
    int returned; 
    // This may not need to happen, or if it does return 0 other behavior might need changing
    // Returning -12 (NOT_SUPPORTED) means the device/OS doesn't support changing the configuration,
    // which would mean we don't have to deal with it.
    returned = libusb_set_configuration(primaryDeviceHandle, 0); 
    printf("Returned value %d\n",returned);

    // Get the list of interfaces on the current configuration
    printf("Getting config_descriptor\n");
    struct libusb_config_descriptor* primaryConfig;
    libusb_get_active_config_descriptor (primaryDevice, &primaryConfig);
    const struct libusb_interface* interfaces = primaryConfig->interface;
    int numInterfaces = primaryConfig->bNumInterfaces;
    printf("%d Interfaces found\n", primaryConfig->bNumInterfaces);
    listInterfaces(interfaces, numInterfaces);
    
    printf("Claim Interface\n");
    returned = libusb_claim_interface(primaryDeviceHandle, 0);
    printf("Returned value %d\n", returned);
    
    // Generate transfer
    struct libusb_transfer *transfer = libusb_alloc_transfer(0);
	int timeout = 3000;
	unsigned char endpoint = 1;
    unsigned char *data = "OUTPUT ON\n";
    int length = strlen(data);
    printf("Attempting Transfer of message '%s' with length %d\n",data,length);
	libusb_fill_bulk_transfer(transfer,primaryDeviceHandle,endpoint,data,length,&callback,0,timeout);
	
	// Send Transfer
	callbackReturned = 0;
	printf("transfer returned %d\n",libusb_submit_transfer(transfer));
	
	//libusb_wait_for_event(NULL,NULL);
	libusb_handle_events_completed(NULL, &callbackReturned);
	printf("Events handled\n");
	libusb_release_interface(primaryDeviceHandle,0);
    libusb_free_config_descriptor(primaryConfig);
    libusb_close(primaryDeviceHandle);
	printf("Closed connection\n");
}

int main() {
    int error = libusb_init(NULL);
    if (error == 0)
    {
        printf("Initialized successfully\n");
        int listerr = list_devices();
        if (listerr != 0)
		{
             return 1;
        }
        // attempt to communicate with device
        int operateerr = operate_primary_device();
        if (operateerr != 0)
        {
            libusb_exit(NULL);
             return 1;
        }
        // else program finished normally
        libusb_exit(NULL);
        return 0;
    }
    else
    {
        printf("Initialization failed with error code %d", error);
        return 1;
    }
}
