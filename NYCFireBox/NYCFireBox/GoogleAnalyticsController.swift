//
//  GoogleAnalyticsController.swift
//
//  Created by Phil Scarfi on 4/27/18.
//  Copyright © 2018 Pioneer Mobile Applications. All rights reserved.
//

import Foundation

public class GoogleAnalyticsController {
    static let shared = GoogleAnalyticsController()
    
    func registerApp(_ trackingID: String) {
        // Classic Google Analytics for iOS was removed with the CocoaPods migration.
    }
    
    func trackScreen(name: String) {
        print("Screen: \(name)")
    }
    
    func trackEvent(category: String, action: String, label: String, value: NSNumber) {
        print("Event: \(category), action: \(action), label: \(label), value: \(value)")
    }
}
