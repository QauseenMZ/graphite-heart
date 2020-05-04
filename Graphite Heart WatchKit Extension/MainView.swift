//
//  MainView.swift
//  Graphite Heart WatchKit Extension
//
//  Created by Benjamin Reed on 5/1/20.
//  Copyright © 2020 Benjamin Reed. All rights reserved.
//

import SwiftUI

protocol DataDelegate {
    var ipAddress:String { get set }
    var port:String { get set }
    var heartRate:Float? { get set }
}

struct MainView: View, DataDelegate {
    let storage = Storage()

    @State var ipAddress:String = ""
    @State var port:String = ""
    @State var heartRate:Float?
    @State var started = false

    var body: some View {
        VStack {
            Spacer()
            Text("♥️ \(heartRate == nil ? "n/a" : String(format: "%0.1f", heartRate!))").foregroundColor(Color.red).font(.title)
            Spacer()
            Button(action: {
                if (self.started) {
                    self.started.toggle()
                    WorkoutTracking.shared.stopObservingHeartRate()
                } else {
                    self.started.toggle()
                    self.storage.ipAddress(newAddress: self.ipAddress)
                    self.storage.port(newPort: self.port)
                    WorkoutTracking.shared.startObservingHeartRate(delegate: self)
                }
            }) {
                if (self.started) {
                    Text("Stop")
                } else {
                    Text("Start")
                }
            }
            Text(ipAddress)
        }
    }

}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
