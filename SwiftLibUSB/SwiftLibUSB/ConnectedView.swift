//
//  ConnectedView.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/25/23.
//

import SwiftUI

/// This view displays when libUSB is initialised and devies were found. It shows each device and lets the user pick a device to interact with.
struct ConnectedView: View {
    @StateObject var control: Controller
    
    init() throws {
        let cont = try Controller()
        _control = StateObject(wrappedValue: cont)
    }
    
    var body: some View {
        VStack {
            Picker("Device:", selection: $control.chosenDevice) {
                ForEach($control.deviceList.devices, id: \.self) { item in
                    Text(verbatim: item.wrappedValue.displayName).tag(item.wrappedValue)
                }
            }

            //Text(verbatim: $control.chosenDevice.wrappedValue.displayName)

            Picker("Configuration:", selection: $control.chosenConfig) {
                ForEach($control.chosenDevice.configurations, id: \.self) { item in
                    Text(verbatim: item.wrappedValue.displayName).tag(item.wrappedValue)
                }
            }
            
            Picker("Interface:", selection: $control.chosenInterface) {
                ForEach($control.chosenConfig.interfaces, id: \.self) { item in
                    Text(verbatim: String(item.wrappedValue.index)).tag(item.wrappedValue)
                }
            }
            
            Picker("Alt Setting:", selection: $control.chosenAltSetting) {
                ForEach($control.chosenInterface.altSettings, id: \.self) { item in
                    Text(verbatim: String(item.wrappedValue.displayName)).tag(item.wrappedValue)
                }
            }
            
            Button("Print Device", action: control.printDevice)

            Button("Connect to Device", action: control.connect)
            
            TextField("Command", text: $control.command)
            Button("Print Command", action: control.printCommand)
            Button("Send Command", action: control.sendCommand)
            Button("Send OUTPUT ON", action: control.sendOutputOn)
            
        }
        .padding(.horizontal)
    }
}

struct ConnectedView_Previews: PreviewProvider {
    static var previews: some View {
        if let v = try? ConnectedView() {
            v
        } else {
            Text("Unable to get devices")
        }
    }
}
