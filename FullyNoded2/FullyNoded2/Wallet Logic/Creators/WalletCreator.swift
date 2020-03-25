//
//  WalletCreator.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class WalletCreator {
    
    var errorString = ""
    var walletDict = [String:Any]()
    
    func createStandUpWallet(completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        
        let wallet = WalletStruct.init(dictionary: walletDict)
        
        func createStandUpWallet() {
            
            let param = "\"\(wallet.name)\", true, true, \"\", true"
            executeNodeCommand(method: .createwallet, param: param)
            
        }
        
        func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
            
            let reducer = Reducer()
            
            func getResult() {
                
                if !reducer.errorBool {
                    
                    switch method {
                        
                    case .createwallet:
                        
                        if let response = reducer.dictToReturn {
                            
                            handleWalletCreation(response: response)
                            
                        }
                        
                    case .importmulti:
                        
                        if let result = reducer.arrayToReturn {
                            
                            if result.count > 0 {
                                
                                if let dict = result[0] as? NSDictionary {
                                    
                                    if let success = dict["success"] as? Bool {
                                        
                                        if success {
                                            
                                            importChangeKeys()
                                            
                                        } else {
                                            
                                            if let errorDict = dict["error"] as? NSDictionary {
                                                
                                                if let error = errorDict["message"] as? String {
                                                    
                                                    completion((false, error))
                                                    
                                                } else {
                                                    
                                                    completion((false, nil))
                                                    
                                                }
                                                
                                            } else {
                                                
                                                completion((false, nil))
                                                
                                            }
                                            
                                        }
                                        
                                        if let warnings = dict["warnings"] as? NSArray {
                                            
                                            if warnings.count > 0 {
                                                
                                                for warning in warnings {
                                                    
                                                    let warn = warning as! String
                                                    self.errorString += warn
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    default:
                        
                        break
                        
                    }
                    
                } else {
                    
                    completion((false,reducer.errorDescription))
                    
                }
                
            }
            
            reducer.makeCommand(walletName: wallet.name, command: method,
                                param: param,
                                completion: getResult)
            
        }
        
        func handleWalletCreation(response: NSDictionary) {
            
            let warning = response["warning"] as! String
            
            if warning != "" {
                
                print("warning from bitcoin core: \(warning)")
                
            }
            
            let params = "[{ \"desc\": \"\(wallet.descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": true, \"internal\": false }]"
            
            executeNodeCommand(method: .importmulti, param: params)
            
        }
        
        func importChangeKeys() {
            
            let reducer = Reducer()
            
            let params = "[{ \"desc\": \"\(wallet.changeDescriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"keypool\": true, \"internal\": true }]"
            
            reducer.makeCommand(walletName: wallet.name, command: .importmulti, param: params) {
                
                if let result = reducer.arrayToReturn {
                    
                    if result.count > 0 {
                        
                        if let dict = result[0] as? NSDictionary {
                            
                            if let success = dict["success"] as? Bool {
                                
                                if success {
                                    
                                    completion((true, nil))
                                    
                                } else {
                                    
                                    if let errorDict = dict["error"] as? NSDictionary {
                                        
                                        if let error = errorDict["message"] as? String {
                                            
                                            completion((false, error))
                                            
                                        } else {
                                            
                                            completion((false, nil))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((false, nil))
                                        
                                    }
                                    
                                }
                                
                                if let warnings = (result[0] as! NSDictionary)["warnings"] as? NSArray {
                                    
                                    if warnings.count > 0 {
                                        
                                        for warning in warnings {
                                            
                                            let warn = warning as! String
                                            self.errorString += warn
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        createStandUpWallet()
        
    }
    
}
