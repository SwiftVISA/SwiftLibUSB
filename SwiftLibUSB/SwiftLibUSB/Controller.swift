//
//  Controller.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import Foundation

/// The primary class for holding the logic of the demonstration UI.
class Controller: ObservableObject {
    var command = ""
    @Published var dataReceived = ""
    @Published var isConnected = false
    @Published var chosenDevice: Device {
        didSet {
            chosenConfig = chosenDevice.configurations[0]
        }
    }
    @Published var chosenConfig: Configuration {
        didSet {
            chosenInterface = chosenConfig.interfaces[0]
        }
    }
    @Published var chosenInterface: Interface {
        didSet {
            chosenAltSetting = chosenInterface.altSettings[0]
        }
    }
    
    @Published var chosenAltSetting: AltSetting
    
    var context: Context
    var deviceList: DeviceList
    var messageIndex: UInt8
    
    init() throws {
        try context = Context()
        try deviceList = context.getDeviceList()
        if deviceList.devices.isEmpty {
            throw USBError.other
        }
        chosenDevice = deviceList.devices[0]
        chosenConfig = deviceList.devices[0].configurations[0]
        chosenInterface = deviceList.devices[0].configurations[0].interfaces[0]
        chosenAltSetting = deviceList.devices[0].configurations[0].interfaces[0].altSettings[0]
        messageIndex = 1
    }
    
    /// Print the currently stored command to the terminal
    func printCommand() {
        print(command)
    }
    
    func nextMessage() {
        messageIndex = (messageIndex % 255) + 1
    }
    /*
    func sendCommand() {
        do {
            var message = Data([1, messageIndex, 255-messageIndex, 0])
            withUnsafeBytes(of: Int32(command.count + 1).littleEndian) {
                message.append(Data(Array($0)))
            }
            message.append(Data([1, 0, 0, 0]))
            command.withUTF8 {
                message.append($0)
            }
            message.append(10)
            message.append(Data(Array(repeating: 0, count: (4 - message.count % 4) % 4)))
            print([UInt8](message))
            for endpoint in chosenAltSetting.endpoints {
                if endpoint.direction == .Out && endpoint.transferType == .bulk {
                    let num = try endpoint.sendBulkTransfer(data: &message)
                    print("Sent \(num) bytes")
                }
            }
            nextMessage()
            print("Sent message")
        } catch {
            print("Error sending message")
        }
    }
    */
    func sendCommand() {
        do {
            // Part 1 of header: Write Out (constant 1), message index, inverse of message index, padding
            var message = Data([1, messageIndex, 255-messageIndex, 0])
            // Part 2 of header: Little Endian length of the message (with added newline)
            withUnsafeBytes(of: Int32(command.count + 1).littleEndian) { lengthBytes in
                message.append(Data(Array(lengthBytes)))
            }
            // Part 3 of header: End of Message (constant 1), three bytes of padding
            message.append(Data([1, 0, 0, 0]))
            // Add the message as bytes
            command.withUTF8 { commandBytes in
                message.append(commandBytes)
            }
            // Add a newline
            message.append(10)
            // Pad to 4 byte boundary
            message.append(Data(Array(repeating: 0, count: (4 - message.count % 4) % 4)))
            
            print([UInt8](message))
            
            // Send the command message to a bulk out endpoint
            for endpoint in chosenAltSetting.endpoints {
                if endpoint.direction == .Out && endpoint.transferType == .bulk {
                    endpoint.clearHalt()
                    let num = try endpoint.sendBulkTransfer(data: &message)
                    print("Sent \(num) bytes")
                }
            }
            nextMessage()
            print("Sent command message")
            
            // Send read request to out endpoint
            var readBufferSize = 1024
            // Part 1 of header: Read In (constant 2), message index, inverse of message index, padding
            message = Data([2, messageIndex, 255-messageIndex, 0])
            // Part 2 of header: Little Endian length of the buffer
            withUnsafeBytes(of: Int32(readBufferSize).littleEndian) { lengthBytes in
                message.append(Data(Array(lengthBytes)))
            }
            // Part 3 of header: Optional terminator byte (not used here), three bytes of padding
            message.append(Data([0,0,0,0]))
            
            for endpoint in chosenAltSetting.endpoints {
                if endpoint.direction == .In && endpoint.transferType == .bulk {
                    endpoint.clearHalt()
                }
            }
            for endpoint in chosenAltSetting.endpoints {
                if endpoint.direction == .Out && endpoint.transferType == .bulk {
                    let num = try endpoint.sendBulkTransfer(data: &message)
                    print("Sent \(num) bytes")
                }
            }
            print ("Sent request message")
            
            for endpoint in chosenAltSetting.endpoints {
                if endpoint.direction == .In && endpoint.transferType == .bulk {
                    let data = try endpoint.receiveBulkTransfer()
                    print([UInt8](data))
                    dataReceived += String(decoding: data[12...], as: UTF8.self)
                }
            }
            nextMessage()
            
        } catch {
            print("Error sending message")
        }
    }
    /// Print the currently chosen device to the terminal
    func printDevice() {
        print(chosenDevice.displayName)
    }

    /// connect to the chosen device and save the returned handle
    func connect() {
        do {
            try chosenConfig.setActive()
            try chosenInterface.claim()
            try chosenAltSetting.setActive()
            isConnected = true

            print("Connected!")
        } catch {
            print("Error connecting")
            dataReceived.append("Error connecting\n")
        }
    }
    
    /// Attempts to send an "OUTPUT ON" command to the selected device
    /*func sendOutputOn() {
        do {
            var message = Data([1, 1, 254, 0, 10, 0, 0, 0, 1, 0, 0, 0, 79, 85, 84, 80, 85, 84, 32, 79, 78, 10, 0, 0]) // Raw bytes of OUTPUT ON message
            for endpoint in chosenConfig.interfaces[0].altSettings[0].endpoints {
                if endpoint.direction == .Out && endpoint.transferType == .bulk {
                    let num = try endpoint.sendBulkTransfer(data: &message)
                    print("Sent \(num) bytes")
                }
            }
        } catch {
            print("Error sending bytes")
        }
    }*/
}
