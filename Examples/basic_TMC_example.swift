/*
 
 This is a basic example showing how to communicate using the USBTMCInstrument class
 USBTMCInstruments should be used for communicating with USB Test and Measurement Class Devices
 To get it to work, you need to know either the VISA string of the device, or enough information to identify the device
 This identification takes the form of the vendorID, productID and the Serial Code
 This example will likely not work directly, as it assumes you have specific hardware plugged in
 This test was written for a Keysight E36103B USB-controlled power supply
 */

import Foundation

public class TMCExample(){
    
    main() throws {
        // First, we must initilize the device. We can do this with the VISA string first
        let myVisaString = "USB0::10893::5634::MY59001442::0::INSTR"
        var myInstrument : USBTMCInstrument = try USBTMCInstrument(visaString: myVisaString)
        
        // Now we can write to our instrument
        let myCommand = "SOURCE:VOLTAGE MINIMUM"
        try myInstrument.write(myCommand, appending: "\n", encoding: .ascii)
        
        // If we know the bytes, we can write with that instead
        let myBytes : [UInt8] = [83,79,85,82,67,69,58,86,79,76,84,65,71,69,32,77,73,78,73,77,85,77,13]
        try myInstrument.writeBytes(Data(myBytes), appending: Data([10]))
        
        // Reading is also possible. We should ask the device for some information first
        let myReadCommand = "*IDN?"
        try myInstrument.write(myReadCommand)
        
        // Lets ask it for the responce. We are giving it a buffer of 1024 bytes each time, for a total of 4096
        // It will not need this entire buffer, the large size is just for example
        let deviceResponse : Data = try myInstrument.readBytes(length: 4096, chunkSize: 1024)
        print([UInt8](deviceResponse))
    }
}
