//
//  ContentView.swift
//  Graphite Heart WatchKit Extension
//
//  Created by Benjamin Reed on 5/1/20.
//  Copyright © 2020 Benjamin Reed. All rights reserved.
//

import SwiftUI

struct BlankView: View {
    var body: some View {
        Text("")
    }
}

struct ContentView: View {
    @State private var isActive: Bool = false
    @State var ipAddress = ""
    @State var port = "2003"

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("IP:")
                TextField("Graphite IP Address", text: $ipAddress)
            }
            HStack {
                Text("Port:")
                TextField("Graphite Port", text: $port)
            }
            Spacer()
            NavigationLink(destination: MainView(ipAddress: ipAddress), isActive: $isActive) {
                Text("Connect")
            }.navigationBarTitle(isActive ? "Configure" : "")
        }
        // Text("Heart rate: \(currentHeartRate != nil ? String(describing: currentHeartRate) : "unknown")")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlankView()
    }
}

