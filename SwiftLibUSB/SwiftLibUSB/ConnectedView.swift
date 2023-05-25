//
//  ConnectedView.swift
//  SwiftLibUSB
//
//  Created by John Hiatt (Student) on 5/25/23.
//

import SwiftUI

struct ConnectedView: View {
    @State var control: Controller
    
    init() throws {
        try control = Controller()
    }
    
    var body: some View {
        VStack {
            TextField("Command", text: $control.command)
            Button("Print Command", action: control.printCommand)
            Picker("Device:", selection: $control.chosenDevice) {
                ForEach($control.deviceList.devices, id: \.self) { item in
                    Text(verbatim: item.wrappedValue.displayName).tag(item.wrappedValue)
                }
            }

            Text(verbatim: $control.chosenDevice.wrappedValue.displayName)

            Button("Print Device", action: control.printDevice)

            Button("Connect to Device", action: control.connect)
        }
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
