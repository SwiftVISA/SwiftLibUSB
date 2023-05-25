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
    @Published var chosenDevice: Device
    @Published var config: Configuration
    var context: Context
    var deviceList: DeviceList
    
    init() throws {
        try context = Context()
        try deviceList = context.getDeviceList()
        if deviceList.devices.isEmpty {
            throw USBError.other
        }
        chosenDevice = deviceList.devices[0]
        config = deviceList.devices[0].configurations[0]
    }
    
    /// Print the currently stored command to the terminal
    func printCommand() {
        print(command)
    }

    /// Print the currently chosen device to the terminal
    func printDevice() {
        print(chosenDevice.displayName)
    }
    
    

    /// connect to the chosen device and save the returned handle
    func connect() {
        do {
            let handle = try chosenDevice.openHandle()
            print("Connected!")
        } catch {
            print("Error connecting")
        }
    }
}
