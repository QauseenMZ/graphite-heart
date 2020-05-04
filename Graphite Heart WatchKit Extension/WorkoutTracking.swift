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
    func startObservingHeartRate(delegate: DataDelegate)
    func stopObservingHeartRate()
}

class WorkoutTracking : NSObject, WorkoutTrackingProtocol, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
        static let shared = WorkoutTracking()

    let healthStore = HKHealthStore()
    let workoutConfig = HKWorkoutConfiguration()

    var workoutSession: HKWorkoutSession!
    var heartRateQuery: HKObserverQuery!
    // var stepQuery: HKObserverQuery!

    var connection: NWConnection!
    var connectionReady = false

    var dataDelegate: DataDelegate!

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

    func workoutSession(_ workoutSession: HKWorkoutSession,
    didChangeTo toState: HKWorkoutSessionState,
      from fromState: HKWorkoutSessionState,
      date: Date) {

      DispatchQueue.main.async {
        // based on the change update the UI on the main thread
        print("workout session changed state to \(toState)")
      }
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for sampleType in collectedTypes {
            if let quantityType = sampleType as? HKQuantityType {
                guard let statistic = workoutBuilder.statistics(for: quantityType) else {
                    continue
                }
                guard let quantity = statistic.mostRecentQuantity() else {
                    continue
                }
                DispatchQueue.main.async {
                    // update the UI based on the most recent quantitiy
                    if (sampleType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue) {
                        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                        let heartRate = quantity.doubleValue(for: heartRateUnit)
                        let timestamp = Int(NSDate().timeIntervalSince1970)

                        let text = "fitness.heartRate \(heartRate) \(timestamp)"

                        if (self.connectionReady) {
                            print("preparing to send: \(text)")
                            self.connection.send(content: text.data(using: String.Encoding.utf8), completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
                                if NWError != nil {
                                    print("Failed to send heart rate (\(heartRate)): \(NWError?.localizedDescription ?? "unknown error")")
                                }
                            })))
                        } else {
                            print("not ready to send: \(text)")
                        }

                        self.dataDelegate.heartRate = Float(heartRate)
                        // LocalNotificationHelper.fireHeartRate(heartRate)
                    }
                }
            } else {
                // handle other HKSampleType subclasses
                print("unhandled sample type: \(sampleType)")
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workout session error: \(error.localizedDescription)")
        self.stopObservingHeartRate()
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("workout builder collected: \(workoutBuilder)")
    }

    func startObservingHeartRate(delegate: DataDelegate) {
        print("starting observation of heart rate samples")
        self.dataDelegate = delegate

        if let existingQuery = heartRateQuery {
            healthStore.stop(existingQuery)
        }

        self.connection = NWConnection(host: NWEndpoint.Host(dataDelegate.ipAddress), port: NWEndpoint.Port(dataDelegate.port) ?? 2003, using: .udp)
        connection.stateUpdateHandler = { (newState) in
            switch(newState) {
            case .ready:
                self.connectionReady = true
            case .cancelled:
                print("cancelled :(")
                self.connectionReady = false
            default: break
            }
        }
        connection.start(queue: .global())

        self.workoutConfig.activityType = .other
        self.workoutConfig.locationType = .unknown

        do {
            self.workoutSession = try HKWorkoutSession(healthStore: self.healthStore, configuration: self.workoutConfig)
            self.workoutSession.delegate = self

            let builder = self.workoutSession.associatedWorkoutBuilder()
            builder.delegate = self
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: self.healthStore, workoutConfiguration: self.workoutConfig)

            self.workoutSession.startActivity(with: Date())
            builder.beginCollection(withStart: Date(), completion: { (success, error) in
                if (success) {
                    print("collection started")
                } else {
                    print("failed to begin collection: \(String(describing: error?.localizedDescription))")
                }
            })
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
    }

    func stopObservingHeartRate() {
        if let existingQuery = heartRateQuery {
            healthStore.stop(existingQuery)
            heartRateQuery = nil
        }
        self.connectionReady = false
        if let connection = connection {
            connection.cancel()
            self.connection = nil
        }
        if let session = workoutSession {
            session.end()
            self.workoutSession = nil
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
