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
    func torConnDifficulties(_ message: String)
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
        #if targetEnvironment(macCatalyst)
        #else
        session.configuration.urlCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        #endif

        clearAuthKeys { [weak self] in
            guard let self = self else { return }

            self.addAuthKeysToAuthDirectory { [weak self] in
                guard let self = self else { return }

                self.config.options = [
                    "DNSPort": "12346",
                    "AutomapHostsOnResolve": "1",
                    /*"SocksPort": "29050 OnionTrafficOnly",*/
                    "SocksPort": "29050",
                    "AvoidDiskWrites": "1",
                    "ClientOnionAuthDir": "\(self.authDirPath)",
                    "LearnCircuitBuildTimeout": "1",
                    "NumEntryGuards": "8",
                    "SafeSocks": "1",
                    "LongLivedPorts": "80,443",
                    "NumCPUs": "2",
                    "DisableDebuggerAttachment": "1",
                    "SafeLogging": "1",
                    /*"ExcludeExitNodes": "1",*/
                    "StrictNodes": "1"
                ]

                self.config.cookieAuthentication = true
                self.config.dataDirectory = URL(fileURLWithPath: torDir)
                self.config.controlSocket = self.config.dataDirectory?.appendingPathComponent("cp")
                self.config.arguments = ["--ignore-missing-torrc"]
            }

        }
        
    }

    // Start the tor client.
    func start(delegate: OnionManagerDelegate?) {
        print("start")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            weak var weakDelegate = delegate
            self.state = .started
            
            // Initiate the controller.
            if self.controller == nil {
                if self.config.controlSocket != nil {
                    self.controller = TorController(socketURL: self.config.controlSocket!)
                }
            }
            
            if self.thread == nil {
                self.thread = TorThread(configuration: self.config)
                self.thread?.start()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                
                // Connect Tor controller.
                if !(self.controller?.isConnected ?? false) {
                    try? self.controller?.connect()
                }
                
                guard let dataDir = self.config.dataDirectory else {
                    weakDelegate?.torConnDifficulties("Could not access the Tor config data directory")
                    self.state = .stopped
                    return
                }
                
                guard let cookie = try? Data(contentsOf: dataDir.appendingPathComponent("control_auth_cookie"), options: NSData.ReadingOptions(rawValue: 0)) else {
                    weakDelegate?.torConnDifficulties("Could not create the control cookie")
                    self.state = .stopped
                    return
                }
                
                self.controller?.authenticate(with: cookie) { [weak self] (success, error) in
                    guard let self = self else { return }
                    
                    guard success else {
                        
                        guard let error = error else {
                            weakDelegate?.torConnDifficulties("Could not authenticate with the control cookie")
                            self.state = .stopped
                            return
                        }
                        
                        weakDelegate?.torConnDifficulties(error.localizedDescription)
                        self.state = .stopped
                        
                        return
                    }
                    
                    var progressObs: Any?
                    progressObs = self.controller?.addObserver(forStatusEvents: {
                        (type: String, severity: String, action: String, arguments: [String : String]?) -> Bool in
                        #if DEBUG
                        print("args = \(String(describing: arguments))")
                        #endif
                        
                        if type == "STATUS_CLIENT" && action == "BOOTSTRAP" {
                            let progress = Int(arguments!["PROGRESS"]!)!
                            weakDelegate?.torConnProgress(progress)
                            if progress >= 100 {
                                self.controller?.removeObserver(progressObs)
                                
                            }
                            return true
                        }
                        return false
                    })
                    
                    var obvs:Any!
                    obvs = self.controller?.addObserver(forCircuitEstablished: { established in
                        
                        func connected() {
                            self.state = .connected
                            weakDelegate?.torConnFinished()
                            self.controller?.removeObserver(obvs)
                            
                        }
                        
                        // For some reason when reconnecting the Tor thread on the 3rd time we lose the observers and the code does not fire off
                        // even though Tor connects successfully, the only way I can reliably reconnect without issue is with the below. To test
                        // put the app into background, then foreground more then twice, executing an operation each time to ensure the connection
                        // is functional.
                        if established {
                            connected()
                        } else if self.state == .refreshing {
                            connected()
                        }
                    })
                }
            }
        }
    }
    
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
        print("addAuthKeysToAuthDirectory")
        
        Encryption.getNode { (node, error) in
            guard let activeNode = node else {
                print("no node")
                completion()
                return
            }
            
            print("node ID: \(activeNode.id)")
            
            CoreDataService.retrieveEntity(entityName: .auth) { (authKeys, errorDescription) in
                guard let authKeys = authKeys,
                    authKeys.count > 0,
                    let encryptedPrivkey = authKeys[0]["privkey"] as? Data else {
                        print("no auth keys")
                        completion()
                        return
                }
                
                print("auth keys exist")
                                    
                Encryption.decryptData(dataToDecrypt: encryptedPrivkey) { (decryptedPrivkey) in
                    guard let decryptedPrivkey = decryptedPrivkey,
                        let authorizedKey = String(bytes: decryptedPrivkey, encoding: .utf8) else {
                        completion()
                        return
                    }
                    
                    let onionAddressArray = activeNode.onionAddress.components(separatedBy: ".onion:")
                    let authString = onionAddressArray[0] + ":descriptor:x25519:" + authorizedKey
                    let file = URL(fileURLWithPath: self.authDirPath, isDirectory: true).appendingPathComponent("\(randomString(length: 10)).auth_private")
                    
                    try? authString.write(to: file, atomically: true, encoding: .utf8)
                    try? (file as NSURL).setResourceValue(URLFileProtection.complete, forKey: .fileProtectionKey)
                    completion()
                }
            }
        }
    }
    
    private func clearAuthKeys(completion: @escaping () -> Void) {
        
        let fileManager = FileManager.default
        
        do {
            
            let filePaths = try fileManager.contentsOfDirectory(atPath: self.authDirPath)
            
            for filePath in filePaths {
                
                let url = URL(fileURLWithPath: self.authDirPath + "/" + filePath)
                try fileManager.removeItem(at: url)
                #if DEBUG
                print("deleted key")
                #endif
                
            }
            
            completion()
            
        } catch {
            #if DEBUG
            print("error deleting existing keys")
            #endif
            completion()
            
        }
        
    }
    
}
