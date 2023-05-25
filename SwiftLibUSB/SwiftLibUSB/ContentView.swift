//
//  ContentView.swift
//  SwiftLibUSB
//
//  Created by Carole Bouy (Student) on 5/23/23.
//

import SwiftUI

struct ContentView: View {
    @State var refresh = false
    
    var body: some View {
        if let v = try? ConnectedView() {
            v
        } else {
            VStack {
                Text("Unable to find devices")
                Button("Retry", action: { refresh = !refresh })
            }
            .id(refresh)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
