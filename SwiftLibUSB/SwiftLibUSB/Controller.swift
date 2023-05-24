//
//  Controller.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import Foundation

class Controller: ObservableObject {
    var command = ""
    var deviceOptions = ["Device 1","Device 2","Device 3","Device 4"]
    var chosenDevice: Device?
    var context: Context?
    var deviceList: DeviceList?
    var devices: [Device] = []
    
    func printCommand() {
        print(command)
    }
    
    func initialize() {
        do {
            try context = Context()
            print("Initialization succeeded")
        } catch {
            print("Initialization failed")
        }
    }
    
    func getDeviceList() {
        do {
            deviceList = try context?.getDeviceList()
            devices = deviceList?.devices ?? devices
            print("Got devives!")
        } catch {
            print("Error getting devices")
        }
    }
    
    func printDevice() {
        print(deviceList?.devices[0].displayName ?? "Error")
        print(chosenDevice?.displayName ?? "Error")
    }
}
