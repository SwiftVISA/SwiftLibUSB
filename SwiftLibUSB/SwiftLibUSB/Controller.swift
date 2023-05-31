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
    var dataReceived = ""
    var isConnected = false
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
        
    }
    
    /// Print the currently stored command to the terminal
    func printCommand() {
        print(command)
    }
    
    func sendCommand(){
        
    }
    
    /// Print the currently chosen device to the terminal
    func printDevice() {
        print(chosenDevice.displayName)
    }

    /// connect to the chosen device and save the returned handle
    func connect() {
        do {
            let handle = try chosenDevice.openHandle()
            try chosenConfig.setActive()
            isConnected = true
            print("Connected!")
        } catch {
            print("Error connecting")
        }
    }
    
    /// Attempts to send an "OUTPUT ON" command to the selected device
    /*func sendOutputOn() {
        do {
            try chosenConfig.interfaces[0].claim()
            try chosenConfig.interfaces[0].altSettings[0].setActive()
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
