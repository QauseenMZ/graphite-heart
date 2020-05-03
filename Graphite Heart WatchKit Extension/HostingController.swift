//
//  HostingController.swift
//  Graphite Heart WatchKit Extension
//
//  Created by Benjamin Reed on 5/1/20.
//  Copyright © 2020 Benjamin Reed. All rights reserved.
//

import os
import WatchKit
import HealthKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<ContentView> {
    let storage = Storage()

    override var body: ContentView {
        return ContentView(ipAddress: storage.ipAddress() ?? "192.168.211.228")
    }


}
