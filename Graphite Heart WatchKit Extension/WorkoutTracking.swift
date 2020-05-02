//
//  WorkoutTracking.swift
//  ElecDemo
//
//  Created by NhatHM on 8/12/19.
//  Copyright © 2019 GST.PID. All rights reserved.
//

import HealthKit
import Network
import SwiftUI

protocol WorkoutTrackingProtocol {
    func authorizeHealthKit()
    func startObservingHeartRate(view: MainView)
    func stopObservingHeartRate()
}

class WorkoutTracking {
    static let shared = WorkoutTracking()
    let healthStore = HKHealthStore()
    // var stepQuery: HKObserverQuery!
    var heartRateQuery: HKObserverQuery!
    var connection: NWConnection!

    init() {
    }
}

extension WorkoutTracking: WorkoutTrackingProtocol {
    func authorizeHealthKit() {
        if HKHealthStore.isHealthDataAvailable() {
            let infoToRead = Set([
                // HKSampleType.quantityType(forIdentifier: .stepCount)!,
                HKSampleType.quantityType(forIdentifier: .heartRate)!,
                HKSampleType.workoutType()
                ])
            
            let infoToShare = Set([
                // HKSampleType.quantityType(forIdentifier: .stepCount)!,
                HKSampleType.quantityType(forIdentifier: .heartRate)!,
                HKSampleType.workoutType()
                ])
            
            healthStore.requestAuthorization(toShare: infoToShare, read: infoToRead) { (success, error) in
                if success {
                    print("Authorization healthkit success")
                } else if let error = error {
                    print(error)
                }
            }
        } else {
            print("HealthKit not avaiable")
        }
    }

    func startObservingHeartRate(view: MainView) {
        print("starting observation of heart rate samples")

        guard let heartRateSampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
        }

        if let existingQuery = heartRateQuery {
            healthStore.stop(existingQuery)
        }
        
        self.connection = NWConnection(host: NWEndpoint.Host(view.ipAddress), port: 2003, using: .udp)
        var ready = false
        connection.stateUpdateHandler = { (newState) in
            switch(newState) {
            case .ready:
                ready = true
            case .cancelled:
                print("cancelled :(")
                ready = false
            default: break
            }
        }
        connection.start(queue: .global())

        heartRateQuery = HKObserverQuery(sampleType: heartRateSampleType, predicate: nil) { [unowned self] (_, _, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            self.fetchLatestHeartRateSample { (sample) in
                print("fetching latest heart rate sample")

                guard let sample = sample else {
                    return
                }
                
                DispatchQueue.main.async {
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
                    let timestamp = Int(NSDate().timeIntervalSince1970)

                    view.heartRate = Float(heartRate)

                    if (ready) {
                        let text = "fitness.heartRate \(heartRate) \(timestamp)"
                        print("preparing to send: \(text)")
                        self.connection.send(content: text.data(using: String.Encoding.utf8), completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
                            if NWError != nil {
                                print("Failed to send heart rate (\(heartRate)): \(NWError?.localizedDescription ?? "unknown error")")
                            }
                        })))
                    } else {
                        print("not ready yet")
                    }

                    LocalNotificationHelper.fireHeartRate(heartRate)
                }
            }
        }
        
        healthStore.execute(heartRateQuery)
    }

    func stopObservingHeartRate() {
        if let existingQuery = heartRateQuery {
            healthStore.stop(existingQuery)
            heartRateQuery = nil
        }
        if let existingConnection = connection {
            existingConnection.cancel()
            connection = nil
        }
    }

}

extension WorkoutTracking {
    private func fetchLatestHeartRateSample(completionHandler: @escaping (_ sample: HKQuantitySample?) -> Void) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            completionHandler(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType,
                                  predicate: predicate,
                                  limit: Int(HKObjectQueryNoLimit),
                                  sortDescriptors: [sortDescriptor]) { (_, results, error) in
                                    if let error = error {
                                        print("Error: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    completionHandler(results?[0] as? HKQuantitySample)
        }
        
        healthStore.execute(query)
    }

    /*
    private func fetchLatestStepSample(completionHandler: @escaping (_ sample: HKQuantitySample?) -> Void) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            completionHandler(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType,
                                  predicate: predicate,
                                  limit: Int(HKObjectQueryNoLimit),
                                  sortDescriptors: [sortDescriptor]) { (_, results, error) in
                                    if let error = error {
                                        print("Error: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    completionHandler(results?[0] as? HKQuantitySample)
        }
        
        healthStore.execute(query)
    }
    */
}
