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
    @State var ipAddress = ""

    var body: some View {
        VStack(alignment: .leading) {
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
        BlankView()
    }
}

