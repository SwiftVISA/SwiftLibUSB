//
//  Controller.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import Foundation

class Controller: ObservableObject {
    var command = ""
    @Published var chosenDevice: Device
    var context: Context
    var deviceList: DeviceList
    
    init() throws {
        try context = Context()
        try deviceList = context.getDeviceList()
        if deviceList.devices.isEmpty {
            throw USBError.other
        }
        chosenDevice = deviceList.devices[0]
    }
    
    func printCommand() {
        print(command)
    }

    func printDevice() {
        print(chosenDevice.displayName)
    }

    func connect() {
        do {
            let handle = try chosenDevice.openHandle()
            print("Connected!")
        } catch {
            print("Error connecting")
        }
    }
}
