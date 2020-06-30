//
//  Reducer.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

// MARK: What is the purpose of this class?

// The purpose of this file is to give a central place where all node commands go, that way we can check every single command for specific errors, such as a wallet
// not being loaded. This allows us to automatically load the wallet if at anytime it gets unloaded, this saves us from having to make this check every single time
// we make a node command. Wallets unload when your node reboots. The other important purpose is that we can incorporate different connection types to the node and
// use this class to "filter" the command to its appropriate class without having to make any changes to the exisiting code. For now the only two means of connecting to the node are locally (this is all commented out and for dev use only) and via tor.

import Foundation

class Reducer {
    
    class func makeCommand(walletName: String, command: BTC_CLI_COMMAND, param: Any, completion: @escaping ((object: Any?, errorDescription: String?)) -> Void) {
        
        func torCommand() {
            
            let torRPC = MakeRPCCall.sharedInstance
            torRPC.executeRPCCommand(walletName: walletName, method: command, param: param) { (success, objectToReturn, errorDesc) in
                
                if success && objectToReturn != nil {
                    
                    completion((objectToReturn, nil))
                    
                } else {
                    
                    if errorDesc != nil {
                        
                        if errorDesc!.contains("Requested wallet does not exist or is not loaded") {
                            
                            torRPC.executeRPCCommand(walletName: walletName, method: .loadwallet, param: "\"\(walletName)\"") { (success, objectToReturn, errorDesc) in
                                
                                if success && objectToReturn != nil  {
                                    
                                    torRPC.executeRPCCommand(walletName: walletName, method: command, param: param) { (success, objectToReturn, errorDesc) in
                                        
                                        if success && objectToReturn != nil  {
                                            
                                            completion((objectToReturn, nil))
                                            
                                        } else {
                                            
                                            completion((nil, errorDesc ?? "Requested wallet does not exist or is not loaded"))
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil, errorDesc ?? "Requested wallet does not exist or is not loaded"))
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            completion((nil, errorDesc!))
                            
                        }
                        
                    } else {
                        
                        completion((nil, errorDesc!))
                        
                    }
                    
                }
                
            }
            
        }
                
        torCommand()
        
        // This is for dev environment only, uncomment it to use it.
        
//        func localCommand() {
//
//            print("local")
//
//            let localRPC = LocalNode.sharedInstance
//            localRPC.command(walletName: walletName, method: command, param: param) { (success, errorDescription, result) in
//
//                if success {
//
//                    if result != nil {
//
//                        parseResponse(response: result as Any)
//
//                    }
//
//                } else {
//
//                    if errorDescription != nil {
//
//                        if errorDescription!.contains("Requested wallet does not exist or is not loaded") {
//
//                            localRPC.command(walletName: walletName, method: .loadwallet, param: "\"\(walletName)\"") { (success, errorDescription, result) in
//
//                                if success {
//
//                                    localRPC.command(walletName: walletName, method: command, param: param) { (success, errorDescription, result) in
//
//                                        if success {
//
//                                            if result != nil {
//
//                                                parseResponse(response: result as Any)
//
//                                            }
//
//                                        } else {
//
//                                            if errorDescription != nil {
//
//                                                self.errorBool = true
//                                                self.errorDescription = errorDescription!
//                                                completion()
//
//                                            }
//
//                                        }
//
//                                    }
//
//                                } else {
//
//                                    self.errorBool = true
//                                    self.errorDescription = "Wallet does not exist, maybe your node changed networks?"
//                                    completion()
//
//                                }
//
//                            }
//
//                        }
//
//                    }
//
//                }
//
//            }
//
//        }
        
        // For now we hardcode tor, for a dev environment we can uncomment the below code and the app will try and connect to
        // a local node.
        
        
//        let mgr = TorClient.sharedInstance
//
//        if mgr.state == .connected || mgr.state == .refreshing {
//
//            torCommand()
//
//        } else {
//
//            // this is for dev environment only... can be the begginings of mac app
//            localCommand()
//
//        }
        
    }
    
}
