//
//  AppDelegate.swift
//  FullyNoded2
//
//  Created by Peter on 10/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let notificationCenter = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        notificationCenter.delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        switch response.notification.request.identifier {
        case "Refill":
            print("Handling notifications with the Refill Notification Identifier")
        default:
            break
        }

        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            print("Default")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .refillKeypool, object: nil, userInfo: nil)
            }
        case "Delete":
            print("Delete")
        case "Refill":
            print("refill action tapped")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .refillKeypool, object: nil, userInfo: nil)
            }
        default:
            print("Unknown action")
        }

        completionHandler()
    }
    
    func promptForNotificationPermission() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }

    func scheduleNotification(type: String) {
        print("scheduleNotification: \(type)")

        let content = UNMutableNotificationContent()
        let categoryIdentifier = "Delete Notification Type"

        content.title = "Refill Keypool"
        content.body = "Your node will run out of keys soon, tap refill to refill your nodes keypool."
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }

        let refillAction = UNNotificationAction(identifier: "Refill", title: "Refill Account", options: [])
        let category = UNNotificationCategory(identifier: categoryIdentifier,
                                              actions: [refillAction],
                                              intentIdentifiers: [],
                                              options: [])

        notificationCenter.setNotificationCategories([category])

    }

}

