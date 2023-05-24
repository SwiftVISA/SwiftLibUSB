//
//  ContentView.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import SwiftUI

struct ContentView: View {
    @State var control = Controller()
    
    var body: some View {
        VStack {
            TextField("Command", text: $control.command)
            Button("Print Command", action: control.printCommand)
            Button("Initialize", action: control.initialize)
            Button("Get Devices", action: control.getDeviceList)
            Picker("Device:", selection: $control.chosenDevice) {
                ForEach($control.devices, id: \.self) { item in
                    Text(verbatim: item.wrappedValue.displayName)
                }
            }
            
            
            Button("Print Device", action: control.printDevice)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
