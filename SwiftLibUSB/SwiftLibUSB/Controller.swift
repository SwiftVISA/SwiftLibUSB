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
    var chosenDevice: Device = Device()
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
            if let devList = deviceList {
                for dev in devList.devices {
                    devices.append(dev)
                    chosenDevice = dev
                }
            }
            print("Got devices!")
        } catch {
            print("Error getting devices")
        }
    }
    
    func printDevice() {
        print(devices[0].displayName)
        print(chosenDevice.displayName)
    }
}
