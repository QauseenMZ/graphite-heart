//
//  MainView.swift
//  Graphite Heart WatchKit Extension
//
//  Created by Benjamin Reed on 5/1/20.
//  Copyright © 2020 Benjamin Reed. All rights reserved.
//

import SwiftUI

struct MainView: View {
    var ipAddress = ""
    @State var heartRate:Float?;
    @State var started = false;
    @State var heartPump = true;

    var body: some View {
        VStack {
            Spacer()
            Text("♥️ \(heartRate == nil ? "n/a" : String(format: "%0.2f", heartRate!))").foregroundColor(Color.red).font(.title)
            Spacer()
            Button(action: {
                if (self.started) {
                    WorkoutTracking.shared.stopObservingHeartRate()
                } else {
                    WorkoutTracking.shared.startObservingHeartRate(view: self)
                }
                self.started.toggle()
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
