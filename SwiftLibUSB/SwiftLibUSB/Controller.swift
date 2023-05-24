//
//  Controller.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import Foundation

class Controller: ObservableObject {
    var command = ""
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
}
