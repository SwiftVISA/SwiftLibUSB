//
//  ContentView.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var control = Controller()
    @State var update = false
    
    var body: some View {
        VStack {
            TextField("Command", text: $control.command)
            Button("Print Command", action: control.printCommand)
            Button("Initialize", action: control.initialize)
            Button("Get Devices", action: { () in
                control.getDeviceList()
                update = true
            })
            Group {
                if control.devices.count != 0 {
                    Picker("Device:", selection: $control.chosenDevice) {
                        ForEach($control.devices, id: \.self) { item in
                            Text(verbatim: item.wrappedValue.displayName)
                        }
                    }
                    
                    Button("Print Device", action: control.printDevice)
                }
            }
            .id(update)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
