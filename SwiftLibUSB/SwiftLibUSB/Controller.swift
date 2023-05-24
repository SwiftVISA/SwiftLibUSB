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
    var chosenDevice = ""
    var context: Context?
    
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
            try context?.getDeviceList()
            print("Got devives!")
        } catch {
            print("Error getting devices")
        }
    }
    
    func printDevice() {
        print(chosenDevice)
    }
}
