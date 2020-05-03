//
//  Settings.swift
//  Graphite Heart WatchKit Extension
//
//  Created by Benjamin Reed on 5/2/20.
//  Copyright © 2020 Benjamin Reed. All rights reserved.
//

import Shallows

struct Settings : Codable {
    let ipAddress: String
}

class Storage {
    let diskStorage = DiskStorage.main
        .folder("settings", in: .applicationSupportDirectory)
        .mapString(withEncoding: .utf8)
        .makeSyncStorage()

    init() {
    }

    func ipAddress(newAddress: String? = nil) -> String? {
        if (newAddress != nil) {
            do {
                try diskStorage.set(newAddress!, forKey: "ipAddress")
            } catch let error {
                print("Failed to save IP address \(String(describing: newAddress)): \(error.localizedDescription)")
            }
        }
        do {
            return try diskStorage.retrieve(forKey: "ipAddress")
        } catch let error {
            print("Failed to retrieve IP address: \(error.localizedDescription)")
        }
        return nil
    }

    func port(newPort: String? = nil) -> String? {
        if (newPort != nil) {
            do {
                try diskStorage.set(newPort!, forKey: "port")
            } catch let error {
                print("Failed to save port \(String(describing: newPort)): \(error.localizedDescription)")
            }
        }
        do {
            return try diskStorage.retrieve(forKey: "port")
        } catch let error {
            print("Failed to retrieve IP address: \(error.localizedDescription)")
        }
        return nil
    }
}
