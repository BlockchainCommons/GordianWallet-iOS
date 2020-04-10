//
//  WalletCreator.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class WalletCreator {
    
    func createStandUpWallet(walletDict: [String:Any], completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        
        let wallet = WalletStruct.init(dictionary: walletDict)
        
        func createStandUpWallet() {
            
            let param = "\"\(wallet.name!)\", true, true, \"\", true"
            Reducer.makeCommand(walletName: "", command: .createwallet, param: param) { (object, errorDesc) in
                
                if let response = object as? NSDictionary {
                    
                    importPrimaryKeys(response: response)
                    
                } else {
                    
                    completion((false, errorDesc))
                    
                }
                
            }
            
        }
        
        func importPrimaryKeys(response: NSDictionary) {
            
            let warning = response["warning"] as! String
            
            if warning != "" {
                
                print("warning from bitcoin core: \(warning)")
                
            }
            
            let params = "[{ \"desc\": \"\(wallet.descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": true, \"internal\": false }]"
            
            Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: params) { (object, errorDescription) in
                
                if let result = object as? NSArray {
                    
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
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        func importChangeKeys() {
            
            let params = "[{ \"desc\": \"\(wallet.changeDescriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"keypool\": true, \"internal\": true }]"
            
            Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: params) { (object, errorDesc) in
                
                if let result = object as? NSArray {
                    
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
                                                    
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        createStandUpWallet()
        
    }
    
}
