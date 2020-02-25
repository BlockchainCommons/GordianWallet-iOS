//
//  TorClient.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//  Copyright © 2018 Verge Currency. All rights reserved.
//

import Foundation
import Tor
import UIKit

class TorClient {
    
    static let sharedInstance = TorClient()
    private var config: TorConfiguration = TorConfiguration()
    private var thread: TorThread!
    private var controller: TorController!
    private var authDirPath = ""
    private var torDirPath = ""
    var isRefreshing = false
    var progress = Int()
    
    // Client status?
    private(set) var isOperational: Bool = false
    public var isConnected: Bool {
        return self.controller.isConnected
    }
    
    // The tor url session configuration.
    // Start with default config as fallback.
    private lazy var sessionConfiguration: URLSessionConfiguration = .default

    // The tor client url session including the tor configuration.
    lazy var session = URLSession(configuration: sessionConfiguration)

    // Start the tor client.
    func start(completion: @escaping () -> Void) {
        print("start")
        
        NotificationCenter.default.post(name: .didStartBootstrappingTor, object: nil, userInfo: nil)
        
        let queue = DispatchQueue(label: "com.FullyNoded.torQueue")
        
        queue.async {
            
            // If already operational don't start a new client.
            if self.isOperational || self.turnedOff() {
                print("return completion")
                return completion()
            }
            
            //add V3 auth keys to ClientOnionAuthDir if any exist
            let torDir = self.createTorDirectory()
            self.authDirPath = self.createAuthDirectory()
            
            self.clearAuthKeys {
                
                self.addAuthKeysToAuthDirectory {
                    
                    // Make sure we don't have a thread already.
                    if self.thread == nil {
                        print("thread is nil")
                        
                        self.isOperational = true
                        
                        self.config.options = [
                            
                            "DNSPort": "12346",
                            "AutomapHostsOnResolve": "1",
                            "SocksPort": "29050 OnionTrafficOnly",
                            "AvoidDiskWrites": "1",
                            "ClientOnionAuthDir": "\(self.authDirPath)",
                            "LearnCircuitBuildTimeout": "1",
                            "NumEntryGuards": "8",
                            "SafeSocks": "1",
                            "LongLivedPorts": "80,443",
                            "NumCPUs": "2",
                            "DisableDebuggerAttachment": "1",
                            "SafeLogging": "1",
                            "ExcludeExitNodes": "1",
                            "StrictNodes": "1"
                            
                        ]
                                            
                        self.config.cookieAuthentication = true
                        self.config.dataDirectory = URL(fileURLWithPath: torDir)
                        self.config.controlSocket = self.config.dataDirectory?.appendingPathComponent("cp")
                        self.config.arguments = ["--ignore-missing-torrc"]
                        self.thread = TorThread(configuration: self.config)
                        
                    } else {
                        
                        print("thread is not nil")
                        
                    }
                    
                    // Initiate the controller.
                    self.controller = TorController(socketURL: self.config.controlSocket!)
                    
                    // Start a tor thread.
                    if self.thread.isExecuting == false {
                        
                        self.thread.start()
                        print("tor thread started")
                        
                    } else {
                        
                        print("thread isExecuting true")
                        
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        // Connect Tor controller.
                        self.connectController(completion: completion)
                    }
                    
                }
            
            }
            
        }
        
    }
    
    // Resign the tor client.
    func restart(completion: @escaping () -> Void) {
        print("restart")
        
        resign()
        
        while controller.isConnected {
            print("Disconnecting Tor...")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.start(completion: completion)
        }
        
    }
    
    func resign() {
        print("resign")
        
//        if self.controller != nil {
//            
//            clearAuthKeys {}
//            //isRefreshing = true
//            self.controller.disconnect()
//            self.isOperational = false
//            self.thread = nil
//            self.progress = 0
//            
//        }
        
        clearAuthKeys {}
        isOperational = false
        //controller.disconnect()
        //controller = nil

        // More cleanup
        thread.cancel()
        thread = nil
        
    }
    
    private func connectController(completion: @escaping () -> Void) {
        print("connectController")
        do {
            if !self.controller.isConnected {
                try self.controller?.connect()
                print("tor controller connected")
            }
            
            try self.authenticateController {
                print("authenticateController")
                //TORInstallEventLogging()
                //TORInstallTorLogging()
                //NotificationCenter.default.post(name: .didEstablishTorConnection, object: self)
                completion()
            }
            
        } catch {
            print("error connecting tor controller")
            self.isOperational = false
            completion()
        }
        
    }
    
    private func authenticateController(completion: @escaping () -> Void) throws -> Void {
        print("authenticateController")
        
        let cookie = try Data(
            
            contentsOf: config.dataDirectory!.appendingPathComponent("control_auth_cookie"),
            options: NSData.ReadingOptions(rawValue: 0)
            
        )
        
        print("got cookie")
        
        self.controller?.authenticate(with: cookie) { success, error in
            
            if let error = error {
                
                print("error = \(error.localizedDescription)")
                return
                
            }
            
            
            
//            var progressObs: Any?
//            self.controller.removeObserver(progressObs)
//            progressObs = self.controller.addObserver(forStatusEvents: {
//                (type: String, severity: String, action: String, arguments: [String : String]?) -> Bool in
//
//                print("arguments = \(String(describing: arguments))")
//
//                if arguments != nil {
//
//                    if arguments!["PROGRESS"] != nil {
//
//                        self.progress = Int(arguments!["PROGRESS"]!)!
//                        print("self.progress = \(self.progress)")
//
//                        if self.progress >= 100 {
//                            //self.controller.removeObserver(progressObs)
//                        }
//
//                    }
//
//                    return true
//
//                }
//
//                return false
//
//            })
            
            var observer: Any? = nil
            observer = self.controller?.addObserver(forCircuitEstablished: { established in
                
                if established {
                    
                    print("observer added")
                    self.controller?.getSessionConfiguration() { sessionConfig in
                        
                        self.sessionConfiguration.connectionProxyDictionary = [kCFProxyTypeKey: kCFProxyTypeSOCKS, kCFStreamPropertySOCKSProxyHost: "localhost", kCFStreamPropertySOCKSProxyPort: 29050]
                        self.session = URLSession(configuration: self.sessionConfiguration)
                        self.session.configuration.urlCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
                        self.isOperational = true
                        NotificationCenter.default.post(name: .torConnecting, object: nil, userInfo: nil)
                        completion()
                    }
                    
                    self.controller?.removeObserver(observer)
                   
                    // This is a hack to enable adding more then one observer which allows us to automate the tor circuit reconnection as Tor will not run in the background and cause bad UX. There is a probably a better way to do it, but it works reliably.
                } else if self.isRefreshing {
                    
                    self.controller?.getSessionConfiguration() { sessionConfig in
                        
                        self.sessionConfiguration.connectionProxyDictionary = [kCFProxyTypeKey: kCFProxyTypeSOCKS, kCFStreamPropertySOCKSProxyHost: "localhost", kCFStreamPropertySOCKSProxyPort: 29050]
                        self.session = URLSession(configuration: self.sessionConfiguration)
                        self.session.configuration.urlCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
                        self.isOperational = true
                        NotificationCenter.default.post(name: .torConnecting, object: nil, userInfo: nil)
                        completion()
                    }
                    
                    self.controller?.removeObserver(observer)
                    
                }
                
                
                
            })
            
        }
        
    }
    
    private func createTorDirectory() -> String {
        print("createTorDirectory")
        
        torDirPath = self.getTorPath()
        
        do {
            
            try FileManager.default.createDirectory(atPath: torDirPath, withIntermediateDirectories: true, attributes: [
                FileAttributeKey.posixPermissions: 0o700
                ])
            
        } catch {
            
            print("Directory previously created.")
            
        }
        
        return torDirPath
        
    }
    
    private func getTorPath() -> String {
        print("getTorPath")
        
        var torDirectory = ""
        
        #if targetEnvironment(simulator)
        print("is simulator")
        
        let path = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true).first ?? ""
        torDirectory = "\(path.split(separator: Character("/"))[0..<2].joined(separator: "/"))/.tor_tmp"
        
        #else
        print("is device")
        
        torDirectory = "\(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? "")/tor"
        
        #endif
        
        return torDirectory
        
    }
    
    private func createAuthDirectory() -> String {
        print("createAuthDirectory")
        
        // Create tor v3 auth directory if it does not yet exist
        let authPath = URL(fileURLWithPath: self.torDirPath, isDirectory: true).appendingPathComponent("onion_auth", isDirectory: true).path
        
        do {
            
            try FileManager.default.createDirectory(atPath: authPath, withIntermediateDirectories: true, attributes: [
                FileAttributeKey.posixPermissions: 0o700
                ])
            
        } catch {
            
            print("Auth directory previously created.")
            
        }
        
        return authPath
        
    }
    
    private func addAuthKeysToAuthDirectory(completion: @escaping () -> Void) {
        print("addAuthKeysToAuthDirectory")
        
        let authPath = self.authDirPath
        let cd = CoreDataService()
        let enc = Encryption()
        cd.retrieveEntity(entityName: .nodes) { (entity, errorDescription) in
            
            if entity != nil {
                
                if entity!.count > 0 {
                    
                    let nodesCount = entity!.count
                    
                    for (i, n) in entity!.enumerated() {
                                                                        
                        cd.retrieveEntity(entityName: .auth) { (authKeys, errorDescription) in
                            
                            if errorDescription == nil {
                                
                                if authKeys != nil {
                                    
                                    if authKeys!.count > 0 {
                                        
                                        if let encryptedPrivkey = authKeys![0]["privkey"] as? Data {
                                            
                                            enc.decryptData(dataToDecrypt: encryptedPrivkey) { (decryptedPrivkey) in
                                                
                                                if decryptedPrivkey != nil {
                                                    
                                                    let authorizedKey = String(bytes: decryptedPrivkey!, encoding: .utf8)!
                                                    let encryptedOnionAddress = n["onionAddress"] as! Data
                                                    
                                                    enc.decryptData(dataToDecrypt: encryptedOnionAddress) { (decryptedOnion) in
                                                        
                                                        if decryptedOnion != nil {
                                                            
                                                            let onionAddress = String(bytes: decryptedOnion!, encoding: .utf8)!
                                                            let onionAddressArray = onionAddress.components(separatedBy: ".onion:")
                                                            let authString = onionAddressArray[0] + ":descriptor:x25519:" + authorizedKey
                                                            let file = URL(fileURLWithPath: authPath, isDirectory: true).appendingPathComponent("\(randomString(length: 10)).auth_private")
                                                            
                                                            do {
                                                                
                                                                try authString.write(to: file, atomically: true, encoding: .utf8)
                                                                print("successfully wrote authkey to file")
                                                                
                                                                do {
                                                                    
                                                                    try (file as NSURL).setResourceValue(URLFileProtection.complete, forKey: .fileProtectionKey)
                                                                    print("success setting file protection")
                                                                    
                                                                } catch {
                                                                    
                                                                   print("error setting file protection")
                                                                    
                                                                }
                                                                
                                                                if i + 1 == nodesCount {
                                                                    
                                                                    completion()
                                                                    
                                                                }
                                                                
                                                            } catch {
                                                                
                                                                print("failed writing auth key")
                                                                completion()
                                                            }
                                                            
                                                        } else {
                                                            
                                                            print("failed decrypting onion address")
                                                            completion()
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                } else {
                                                    
                                                    print("failed decrypting private key")
                                                    completion()
                                                    
                                                }
                                                
                                            }
                                            
                                        } else {
                                            
                                            print("failed writing auth key")
                                            completion()
                                            
                                        }
                                        
                                    } else {
                                        
                                        print("no authkeys")
                                        completion()
                                    }
                                    
                                } else {
                                    
                                    print("error getting auth keys")
                                    completion()
                                    
                                }
                                
                            } else {
                                
                                print("error getting authkeys")
                                completion()
                                
                            }
                            
                        }
                        
                    }
                    
                }  else {
                    
                    print("no nodes")
                    completion()
                    
                }
                
            } else {
                
                print("no nodes")
                completion()
                
            }
            
        }
        
    }
    
    private func clearAuthKeys(completion: @escaping () -> Void) {
        
        //removes all authkeys
        let fileManager = FileManager.default
        let authPath = self.authDirPath
        
        do {
            
            let filePaths = try fileManager.contentsOfDirectory(atPath: authPath)
            
            for filePath in filePaths {
                
                let url = URL(fileURLWithPath: authPath + "/" + filePath)
                try fileManager.removeItem(at: url)
                print("deleted key")
                
            }
            
            completion()
            
        } catch {
            
            print("error deleting existing keys")
            completion()
            
        }
        
    }
    
    func turnedOff() -> Bool {
        return false
    }
}
