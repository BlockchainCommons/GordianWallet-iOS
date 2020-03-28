//
//  Reducer.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class Reducer {
    
    var dictToReturn:NSDictionary?
    var doubleToReturn:Double?
    var arrayToReturn:NSArray?
    var stringToReturn:String?
    var boolToReturn:Bool?
    var errorBool = Bool()
    var errorDescription = ""
    
    var method = ""
    
    func makeCommand(walletName: String, command: BTC_CLI_COMMAND, param: Any, completion: @escaping () -> Void) {
        
        method = command.rawValue
        
        func parseResponse(response: Any) {
            
            if let str = response as? String {
                
                self.stringToReturn = str
                completion()
                
            } else if let doub = response as? Double {
                
                self.doubleToReturn = doub
                completion()
                
            } else if let arr = response as? NSArray {
                
                self.arrayToReturn = arr
                completion()
                
            } else if let dic = response as? NSDictionary {
                
                self.dictToReturn = dic
                completion()
                
            } else {
                
                if command == .walletpassphrase {
                    
                    self.stringToReturn = "Wallet decrypted"
                    completion()
                    
                } else if command == .walletpassphrasechange {
                    
                    self.stringToReturn = "Passphrase updated"
                    completion()
                    
                } else if command == .encryptwallet || command == .walletlock {
                    
                    self.stringToReturn = "Wallet encrypted"
                    completion()
                    
                }
                
            }
            
        }
        
        func torCommand() {
            
            print("tor")
            let torRPC = MakeRPCCall.sharedInstance
            
            func getResult() {
                
                if !torRPC.errorBool {
                    
                    let response = torRPC.objectToReturn
                    parseResponse(response: response as Any)
                    
                } else {
                    
                    print("torRPC.errorDescription = \(torRPC.errorDescription)")
                    
                    if torRPC.errorDescription.contains("Requested wallet does not exist or is not loaded") {
                        
                        errorDescription = ""
                        errorBool = false
                        
                        torRPC.executeRPCCommand(walletName: walletName, method: .loadwallet, param: "\"\(walletName)\"") {
                            
                            if !torRPC.errorBool {
                                
                                torRPC.executeRPCCommand(walletName: walletName, method: command,
                                                              param: param,
                                                              completion: getResult)
                                
                            } else {
                                
                                self.errorBool = true
                                self.errorDescription = "Wallet does not exist, maybe your node changed networks?"
                                completion()
                                
                            }
                            
                        }
                        
                    } else if torRPC.errorDescription.contains("Could not connect to server") {
                        
                        print("restarting tor")
                        
                        let mgr = TorClient.sharedInstance
                        mgr.resign()
                        
                        mgr.start(delegate: nil) {
                            
                            torRPC.executeRPCCommand(walletName: walletName, method: command,
                                                          param: param,
                                                          completion: getResult)
                            
                        }
                                                
                    } else {
                        
                        errorBool = true
                        errorDescription = torRPC.errorDescription
                        completion()
                        
                    }
                
                    
                }
                
            }
            
            torRPC.errorBool = false
            torRPC.errorDescription = ""
            
            torRPC.executeRPCCommand(walletName: walletName, method: command, param: param, completion: getResult)
            
        }
        
        func localCommand() {
            
            print("local")
                        
            let localRPC = LocalNode.sharedInstance
            localRPC.command(walletName: walletName, method: command, param: param) { (success, errorDescription, result) in
                
                if success {
                    
                    if result != nil {
                        
                        parseResponse(response: result as Any)
                        
                    }
                    
                } else {
                    
                    if errorDescription != nil {
                        
                        if errorDescription!.contains("Requested wallet does not exist or is not loaded") {
                                                
                            localRPC.command(walletName: walletName, method: .loadwallet, param: "\"\(walletName)\"") { (success, errorDescription, result) in
                                
                                if success {
                                 
                                    localRPC.command(walletName: walletName, method: command, param: param) { (success, errorDescription, result) in
                                        
                                        if success {
                                            
                                            if result != nil {
                                                
                                                parseResponse(response: result as Any)
                                                
                                            }
                                            
                                        } else {
                                         
                                            if errorDescription != nil {
                                                
                                                self.errorBool = true
                                                self.errorDescription = errorDescription!
                                                completion()
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                 
                                    self.errorBool = true
                                    self.errorDescription = "Wallet does not exist, maybe your node changed networks?"
                                    completion()
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        if TorClient.sharedInstance.state == .connected {
            
            torCommand()
            
        } else {
            
            // this is for dev environment only... can be the begginings of mac app
            localCommand()
            
        }
        
    }
    
}
