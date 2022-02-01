//
//  ViewController.swift
//  HealthApp
//
//  Created by Burkay Atar on 10.05.2021.
//

import UIKit
import HealthKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {
    
    let healthStore = HKHealthStore()
    
    @IBOutlet weak var receivedHeartRate: UILabel!
    
    @IBOutlet weak var startStopButton: UIButton!
    
    @IBAction func startButtonTapped(_ sender: Any) {
        if startStopButton.titleLabel?.text == "Start"{
            let session = WCSession.default
            if session.activationState == .activated {
                let data = ["startWorkout" : "Start workout."]
                session.transferUserInfo(data)
            }
            startStopButton.setTitle("Stop", for: .normal)
        } else {
            let session = WCSession.default
            if session.activationState == .activated {
                let data = ["stopWorkout" : "Stop workout."]
                session.transferUserInfo(data)
            }
            startStopButton.setTitle("Start", for: .normal)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authorizeHealthKit()
        
        startStopButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 27, bottom: 0, right: 0)
        
        if WCSession.isSupported() {
            
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        }
    func authorizeHealthKit(){
        //The quantity types to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        //The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        //Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (succ, error) in
            if !succ {
                fatalError("Error requesting authorization from health store.")
            }
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        DispatchQueue.main.async {
            
            if activationState == .activated {
                
                if session.isWatchAppInstalled {
                    
                    self.receivedHeartRate.text = "watch app is installed."
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        //to support multiple apple watches.
        WCSession.default.activate()
    }
    //Receiving heart rate data from apple watch.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        
        DispatchQueue.main.async {
            
            if let text = userInfo["heartRate"] as? String {
                self.receivedHeartRate.text = text
                self.startStopButton.setTitle("Stop", for: .normal)
            }
            if let text = userInfo["stopButtonTappedFromWatch"] as? String {
                self.receivedHeartRate.text = text
                self.startStopButton.setTitle("Start", for: .normal)
            }
        }
    }
}
