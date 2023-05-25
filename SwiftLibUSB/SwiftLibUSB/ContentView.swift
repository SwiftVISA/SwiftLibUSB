//
//  ContentView.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var control = Controller()
    
    var body: some View {
        VStack {
            TextField("Command", text: $control.command)
            Button("Print Command", action: control.printCommand)
            Button("Initialize", action: control.initialize)
            Button("Get Devices", action: { () in
                control.getDeviceList()
            })
            Group {
                if control.devices.count != 0 {
                    Picker("Device:", selection: $control.chosenDevice) {
                        ForEach($control.devices, id: \.self) { item in
                            Text(verbatim: item.wrappedValue.displayName).tag(item.wrappedValue)
                        }
                    }

                    Text(verbatim: $control.chosenDevice.wrappedValue.displayName)

                    Button("Print Device", action: control.printDevice)

                    Button("Connect to Device", action: control.connect)
                }
            }
            .id(control.devices)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
