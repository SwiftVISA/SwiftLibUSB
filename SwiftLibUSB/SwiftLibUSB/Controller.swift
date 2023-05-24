//
//  Controller.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import Foundation

class Controller: ObservableObject {
    var command = ""
    @Published var chosenDevice: Device = Device()
    var context: Context?
    var deviceList: DeviceList?
    @Published var devices: [Device] = []
    
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
                devices = devList.devices
            }
            print("Got devices!")
        } catch {
            print("Error getting devices")
        }
    }
    
    func printDevice() {
        print(chosenDevice.displayName)
    }
}
