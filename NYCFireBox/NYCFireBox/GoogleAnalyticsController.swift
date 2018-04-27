//
//  GoogleAnalyticsController.swift
//
//  Created by Phil Scarfi on 4/27/18.
//  Copyright © 2018 Pioneer Mobile Applications. All rights reserved.
//

/*SETUP
 pod init
 pod 'GoogleAnalytics'
 pod install
 Add bridging header
 #import <GoogleAnalytics/GAI.h>
 #import <GoogleAnalytics/GAIDictionaryBuilder.h>
 #import <GoogleAnalytics/GAIFields.h>
 */

import Foundation

public class GoogleAnalyticsController {
    static let shared = GoogleAnalyticsController()
    
    func registerApp(_ trackingID: String) {
        guard let gai = GAI.sharedInstance() else {
//            assert(false, "Google Analytics not configured correctly")
            return
        }
        gai.tracker(withTrackingId: trackingID)
        // Optional: automatically report uncaught exceptions.
        gai.trackUncaughtExceptions = true
        // Optional: set Logger to VERBOSE for debug information.
        // Remove before app release.
        gai.logger.logLevel = .verbose;
    }
    
    func trackScreen(name: String) {
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: name)
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
}
