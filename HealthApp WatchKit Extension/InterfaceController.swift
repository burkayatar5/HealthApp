//
//  InterfaceController.swift
//  HealthApp WatchKit Extension
//
//  Created by Burkay Atar on 10.05.2021.
//

import WatchKit
import Foundation
import HealthKit
import WatchConnectivity

public let healthStore = HKHealthStore()

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, WCSessionDelegate {
    
    
    @IBOutlet weak var bpmLabel: WKInterfaceLabel!
    @IBOutlet weak var heartImage: WKInterfaceImage!
    @IBOutlet weak var startStopButton: WKInterfaceButton!
    
    //Workout Session
    var session: HKWorkoutSession!
    //Live Workout Builder
    var builder: HKLiveWorkoutBuilder!
    //Tracking our workout state
    var workingOut = false
    //Access point for all data managed by HealthKit
    let healthStore = HKHealthStore()
    
    @IBAction func startButtonTapped(){
        if !workingOut{
            startWorkout()
            workingOut = true
            startStopButton!.setTitle("Stop")
        } else {
            stopWorkout()
            workingOut = false
            bpmLabel!.setText("---")
            startStopButton!.setTitle("Start")
            
            let session = WCSession.default
            if session.activationState == .activated {
                let data = ["stopButtonTappedFromWatch" : "---"]
                session.transferUserInfo(data)
            }
        }
    }

    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func animateHeart(){
        self.animate(withDuration: 0.5) {
            self.heartImage.setWidth(75)
            self.heartImage.setHeight(73)
        }
        
        let when = DispatchTime.now() + Double(Int64(0.5 * double_t(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.asyncAfter(deadline: when){
                self.animate(withDuration: 0.5, animations: {
                    self.heartImage.setWidth(65)
                    self.heartImage.setHeight(63)
                })
            }
        }
    }
    
    override func didAppear() {
        //The quantity type to write to the health store
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        //The quantity types to read from the health store
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        
        //Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) {(succ, error) in
            if !succ {
                fatalError("Error requesting authorization from health store.")
            }
        }
    }
    
    func initWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .unknown
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session.associatedWorkoutBuilder()
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        //Setup session and builder
        session.delegate = self
        builder.delegate = self
        
        //Set the workout builder's data source.
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
    }
    
    func startWorkout() {
        //initialize our workout
        initWorkout()
        
        //Start the workout session and begin data collection
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { (succ, error) in
            if !succ {
                fatalError("Error beginning collection from builder.")
            }
        }
        
    }
    
    func stopWorkout() {
        //Stop current workout.
        session.end()
        builder.endCollection(withEnd: Date()) { (success, error) in
            self.builder.finishWorkout { (workout, error) in
                DispatchQueue.main.async() {
                    self.session = nil
                    self.builder = nil
                }
            }
        }
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return
            }
            switch quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let statistics = workoutBuilder.statistics(for: quantityType)
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = statistics!.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                let stringValue = String(Int(Double(round(1 * value!) / 1)))
                bpmLabel.setText(stringValue)
                print("[workoutBuilder] Heart Rate: \(stringValue)")
                self.animateHeart()
                
                //For sending heart rate data to iphone app.
                let session = WCSession.default
                if session.activationState == .activated {
                    let data = ["heartRate" : "\(stringValue)" as Any]
                    session.transferUserInfo(data)
                }
                //For moderate-intensity physical activity HRmax = 220 - age
                //This if statement is only correct for 25 years old person
                if(value! >= Double(195)){
                    let highHeartRate = WKAlertAction.init(title: "OK", style: .default){
                        print("default action")
                    }
                    presentAlert(withTitle: "Heart Rate Alert", message: "High Heart Rate Detected.", preferredStyle: .actionSheet, actions: [highHeartRate])
                }
            default:
                return
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        //Retreive the workout event.
        guard let workoutEventType = workoutBuilder.workoutEvents.last?.type else { return }
        print("[workoutBuilderDidCollectEvent] Workout Builder Changed Event : \(workoutEventType.rawValue)")
    }
    
    //to catch the changes in workout.
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("[workoutSession] Changed State : \(toState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("[workoutSession] Encountered an error : \(error)")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        
        DispatchQueue.main.async {
            if let text = userInfo["startWorkout"] as? String {
                print("\(text)")
                self.startButtonTapped()
            }
            if let text = userInfo["stopWorkout"] as? String {
                print("\(text)")
                self.startButtonTapped()
            }
        }
    }
}
