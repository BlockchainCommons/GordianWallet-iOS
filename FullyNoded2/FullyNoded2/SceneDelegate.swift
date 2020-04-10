//
//  SceneDelegate.swift
//  FullyNoded2
//
//  Created by Peter on 10/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var startingUp = true
//    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
//
//    func registerBackgroundTask() {
//      backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
//        self?.endBackgroundTask()
//      }
//      assert(backgroundTask != .invalid)
//    }
//
//    func endBackgroundTask() {
//      print("Background task ended.")
//      UIApplication.shared.endBackgroundTask(backgroundTask)
//      backgroundTask = .invalid
//    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        print("did become active")
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        // We start the tor thread automatically here whenever the app enters the foreground.
        let mgr = TorClient.sharedInstance

        if !startingUp && mgr.state != .started && mgr.state != .connected  {

            mgr.start(delegate: nil)

        } else {
            
            startingUp = false
            
        }
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // We force quit the tor thread when the app enters the background as it can not stay alive
        // for extended periods of time in the background. We only do this on non iPhone 11 models
        // as for some reason resigning the Tor thread crashes iPhone 11's.
        let device = UIDevice.modelName
        
        if device != "iPhone 11 pro max" && device != "iPhone XS Max" {
            
            let mgr = TorClient.sharedInstance
            
            if mgr.state != .stopped {
                
                mgr.state = .refreshing
                mgr.resign()
                                                    
            }
            
        }

        // Save changes in the application's managed object context when the application transitions to the background.
        //(UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        CoreDataService.saveContext()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        // This code executes when a btcstandup:// uri or btcrpc:// uri link is clicked
        let urlcontexts = URLContexts.first
        let url = urlcontexts?.url
        addNode(url: "\(url!)")
        
    }
    
    
    func addNode(url: String) {
        
        // MARK: TODO
        // Add an alert letting user know whether the node was added successfully or not.
        
        if let myTabBar = self.window?.rootViewController as? UITabBarController {
                        
            let qc = QuickConnect()
            qc.addNode(vc: myTabBar, url: url) { (success, errorDesc) in
                
                if success {
                    
                    DispatchQueue.main.async {
                        
                        myTabBar.selectedIndex = 0
                        
                    }
                    
                } else {
                    
                    print("error adding quick connect = \(errorDesc ?? "unknown error")")
                    
                }
                
            }
            
        } else {
            
            print("error adding quick connect no access to tabbar")
            
        }
        
    }

}

