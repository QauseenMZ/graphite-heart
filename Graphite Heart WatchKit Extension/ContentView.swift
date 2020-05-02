//
//  ContentView.swift
//  Graphite Heart WatchKit Extension
//
//  Created by Benjamin Reed on 5/1/20.
//  Copyright © 2020 Benjamin Reed. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var ipAddress = "192.168.211.228"

    var body: some View {
        VStack {
            Text("Minion IP:")
            TextField("Minion IP Address", text: $ipAddress)
            Spacer()
            NavigationLink(destination: MainView(ipAddress: ipAddress)) {
                Text("Connect")
            }
        }
        // Text("Heart rate: \(currentHeartRate != nil ? String(describing: currentHeartRate) : "unknown")")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

