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
        
        func torCommand() {
            
            print("tor")
            let torRPC = MakeRPCCall.sharedInstance
            torRPC.executeRPCCommand(walletName: walletName, method: command, param: param) { [unowned vc = self] (success, objectToReturn, errorDesc) in
                
                if success && objectToReturn != nil {
                    
                    if let str = objectToReturn as? String {
                        
                        vc.stringToReturn = str
                        completion()
                        
                    } else if let doub = objectToReturn as? Double {
                        
                        vc.doubleToReturn = doub
                        completion()
                        
                    } else if let arr = objectToReturn as? NSArray {
                        
                        vc.arrayToReturn = arr
                        completion()
                        
                    } else if let dic = objectToReturn as? NSDictionary {
                        
                        vc.dictToReturn = dic
                        completion()
                        
                    }
                    
                } else {
                    
                    if errorDesc != nil {
                        
                        if errorDesc!.contains("Requested wallet does not exist or is not loaded") {
                            
                            torRPC.executeRPCCommand(walletName: walletName, method: .loadwallet, param: "\"\(walletName)\"") { [unowned vc = self] (success, objectToReturn, errorDesc) in
                                
                                if success && objectToReturn != nil  {
                                    
                                    torRPC.executeRPCCommand(walletName: walletName, method: command, param: param) { [unowned vc = self] (success, objectToReturn, errorDesc) in
                                        
                                        if success && objectToReturn != nil  {
                                            
                                            if let str = objectToReturn as? String {
                                                
                                                vc.stringToReturn = str
                                                completion()
                                                
                                            } else if let doub = objectToReturn as? Double {
                                                
                                                vc.doubleToReturn = doub
                                                completion()
                                                
                                            } else if let arr = objectToReturn as? NSArray {
                                                
                                                vc.arrayToReturn = arr
                                                completion()
                                                
                                            } else if let dic = objectToReturn as? NSDictionary {
                                                
                                                vc.dictToReturn = dic
                                                completion()
                                                
                                            }
                                            
                                        } else {
                                            
                                            vc.errorBool = true
                                            vc.errorDescription = errorDesc ?? "Requested wallet does not exist or is not loaded"
                                            completion()
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    vc.errorBool = true
                                    vc.errorDescription = errorDesc ?? "Requested wallet does not exist or is not loaded"
                                    completion()
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            vc.errorBool = true
                            vc.errorDescription = errorDesc!
                            completion()
                            
                        }
                        
                    } else {
                        
                        vc.errorBool = true
                        vc.errorDescription = errorDesc!
                        completion()
                        
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
