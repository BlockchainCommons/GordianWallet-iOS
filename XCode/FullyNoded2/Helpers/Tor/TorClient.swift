//
//  TorClient.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//
//

import Foundation
import Tor

protocol OnionManagerDelegate: class {

    func torConnProgress(_ progress: Int)

    func torConnFinished()

    func torConnDifficulties()
}

class TorClient {
    
    enum TorState {
        case none
        case started
        case connected
        case stopped
        case refreshing
    }
    
    static let sharedInstance = TorClient()
    public var state = TorState.none
    private var config: TorConfiguration = TorConfiguration()
    private var thread: TorThread?
    private var controller: TorController?
    private var authDirPath = ""
    private var torDirPath = ""
    
    // The tor url session configuration.
    // Start with default config as fallback.
    private lazy var sessionConfiguration: URLSessionConfiguration = .default

    // The tor client url session including the tor configuration.
    lazy var session = URLSession(configuration: sessionConfiguration)
    
    private init() {
        
        let torDir = createTorDirectory()
        authDirPath = createAuthDirectory()
        
        // For some reason tor.framework is not incredibly reliable at setting the session config, so we do it manually for stability.
        sessionConfiguration.connectionProxyDictionary = [kCFProxyTypeKey: kCFProxyTypeSOCKS, kCFStreamPropertySOCKSProxyHost: "localhost", kCFStreamPropertySOCKSProxyPort: 29050]
        session = URLSession(configuration: sessionConfiguration)
        session.configuration.urlCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        
        clearAuthKeys { [unowned vc = self] in
            
            vc.addAuthKeysToAuthDirectory { [unowned vc = self] in
                
                vc.config.options = [
                    
                    "DNSPort": "12346",
                    "AutomapHostsOnResolve": "1",
                    "SocksPort": "29050 OnionTrafficOnly",
                    "AvoidDiskWrites": "1",
                    "ClientOnionAuthDir": "\(vc.authDirPath)",
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
                
                vc.config.cookieAuthentication = true
                vc.config.dataDirectory = URL(fileURLWithPath: torDir)
                vc.config.controlSocket = vc.config.dataDirectory?.appendingPathComponent("cp")
                vc.config.arguments = ["--ignore-missing-torrc"]
                
            }
            
        }
        
    }

    // Start the tor client.
    func start(delegate: OnionManagerDelegate?) {
        print("start")
        
        weak var weakDelegate = delegate
        state = .started
        
        // Initiate the controller.
        if controller == nil {
            controller = TorController(socketURL: config.controlSocket!)
        }
        
        if thread == nil {
            thread = TorThread(configuration: config)
            thread?.start()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [unowned vc = self] in
            // Connect Tor controller.
            do {
                if !(vc.controller?.isConnected ?? false) {
                    do {
                        try vc.controller?.connect()
                        
                    } catch {
                        print("error=\(error)")
                        
                    }
                }
                
                let cookie = try Data(
                    contentsOf: vc.config.dataDirectory!.appendingPathComponent("control_auth_cookie"),
                    options: NSData.ReadingOptions(rawValue: 0)
                    
                )
                
                vc.controller?.authenticate(with: cookie) { [unowned vc = self] (success, error) in
                    if let error = error {
                        print("error = \(error.localizedDescription)")
                        return
                        
                    }
                    
                    var progressObs: Any?
                    progressObs = vc.controller?.addObserver(forStatusEvents: {
                        (type: String, severity: String, action: String, arguments: [String : String]?) -> Bool in
                        #if DEBUG
                        print("args = \(String(describing: arguments))")
                        #endif
                        
                        if type == "STATUS_CLIENT" && action == "BOOTSTRAP" {
                            let progress = Int(arguments!["PROGRESS"]!)!
                            weakDelegate?.torConnProgress(progress)
                            if progress >= 100 {
                                vc.controller?.removeObserver(progressObs)
                                
                            }
                            return true
                        }
                        return false
                    })
                    
                    var obvs:Any!
                    obvs = vc.controller?.addObserver(forCircuitEstablished: { established in
                        
                        func connected() {
                            vc.state = .connected
                            weakDelegate?.torConnFinished()
                            vc.controller?.removeObserver(obvs)
                            
                        }
                        
                        // For some reason when reconnecting the Tor thread on the 3rd time we lose the observers and the code does not fire off
                        // even though Tor connects successfully, the only way I can reliably reconnect without issue is with the below. To test
                        // put the app into background, then foreground more then twice, executing an operation each time to ensure the connection
                        // is functional.
                        if established {
                            connected()
                            
                        } else if vc.state == .refreshing {
                            connected()
                            
                        }
                    })
                }
            } catch {
                print("failed connecting tor")
                weakDelegate?.torConnDifficulties()
                vc.state = .none
                
            }
        }
    }
    
//    func closeCircuits(_ circuits: [TorCircuit], _ callback: @escaping ((_ success: Bool) -> Void)) {
//        controller?.close(circuits, completion: callback)
//    }
//
//    func getCircuits(_ callback: @escaping ((_ circuits: [TorCircuit]) -> Void)) {
//        controller?.getCircuits(callback)
//    }
    
    func resign() {
        print("resign")
        controller?.disconnect()
        controller = nil
        thread?.cancel()
        thread = nil
        state = .stopped
    }
    
    private func createTorDirectory() -> String {
        torDirPath = self.getTorPath()
        do {
            try FileManager.default.createDirectory(atPath: torDirPath, withIntermediateDirectories: true, attributes: [
                FileAttributeKey.posixPermissions: 0o700])
            
        } catch {
            print("Directory previously created.")
            
        }
        return torDirPath
        
    }
    
    private func getTorPath() -> String {
        var torDirectory = ""
        #if targetEnvironment(simulator)
        let path = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true).first ?? ""
        torDirectory = "\(path.split(separator: Character("/"))[0..<2].joined(separator: "/"))/.tor_tmp"
        #else
        torDirectory = "\(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? "")/tor"
        #endif
        return torDirectory
        
    }
    
    private func createAuthDirectory() -> String {
        // Create tor v3 auth directory if it does not yet exist
        let authPath = URL(fileURLWithPath: self.torDirPath, isDirectory: true).appendingPathComponent("onion_auth", isDirectory: true).path
        do {
            try FileManager.default.createDirectory(atPath: authPath, withIntermediateDirectories: true, attributes: [
                FileAttributeKey.posixPermissions: 0o700])
            
        } catch {
            print("Auth directory previously created.")
            
        }
        return authPath
        
    }
    
    private func addAuthKeysToAuthDirectory(completion: @escaping () -> Void) {
        
        let authPath = self.authDirPath
        CoreDataService.retrieveEntity(entityName: .nodes) { (entity, errorDescription) in
            
            if entity != nil {
                
                if entity!.count > 0 {
                    
                    let nodesCount = entity!.count
                    
                    for (i, n) in entity!.enumerated() {
                                                                        
                        CoreDataService.retrieveEntity(entityName: .auth) { (authKeys, errorDescription) in
                            
                            if errorDescription == nil {
                                
                                if authKeys != nil {
                                    
                                    if authKeys!.count > 0 {
                                        
                                        if let encryptedPrivkey = authKeys![0]["privkey"] as? Data {
                                            
                                            Encryption.decryptData(dataToDecrypt: encryptedPrivkey) { (decryptedPrivkey) in
                                                
                                                if decryptedPrivkey != nil {
                                                    
                                                    let authorizedKey = String(bytes: decryptedPrivkey!, encoding: .utf8)!
                                                    let encryptedOnionAddress = n["onionAddress"] as! Data
                                                    
                                                    Encryption.decryptData(dataToDecrypt: encryptedOnionAddress) { (decryptedOnion) in
                                                        
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
    
}
