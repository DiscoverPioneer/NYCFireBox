//
//  AppDelegate.swift
//  NYCFireBox
//
//  Created by Gordana Badarovska on 4/16/18.
//  Copyright © 2018 Pioneer Mobile Applications. All rights reserved.
//

import UIKit
import CoreLocation
import Fabric
import Crashlytics
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var locationManager = CLLocationManager()
    private let constants = Constants()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        locationManager.requestWhenInUseAuthorization()
        setupAnalytics()
        setupPushNotifications(launchOptions: launchOptions)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    private func setupAnalytics() {
        guard let key = constants.googleAnalyticsKey, !key.isEmpty else { return }
        Fabric.with([Crashlytics.self])
        GoogleAnalyticsController.shared.registerApp(key)
    }

    private func setupPushNotifications(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        guard let key = constants.oneSignalKey, !key.isEmpty else { return }
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: key,
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)

        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;

        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
    }
}

