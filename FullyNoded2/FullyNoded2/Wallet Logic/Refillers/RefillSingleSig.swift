//
//  RefillSingleSig.swift
//  FullyNoded2
//
//  Created by Peter on 27/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class RefillSingleSig {
    
    func refill(wallet: WalletStruct, completion: @escaping ((success: Bool, errorDescription: String?)) -> Void) {
        
        func importChangeKeys() {
                        
            let params = "[{ \"desc\": \"\(wallet.changeDescriptor)\", \"timestamp\": \"now\", \"range\": [\(wallet.maxRange),\(wallet.maxRange + 2500)], \"watchonly\": true, \"keypool\": true, \"internal\": true }]"
            
            Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: params) { (object, errorDesc) in
                
                if let result = object as? NSArray {
                    
                    if result.count > 0 {
                        
                        if let dict = result[0] as? NSDictionary {
                            
                            if let success = dict["success"] as? Bool {
                                
                                if success {
                                    
                                    CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "maxRange", newValue: wallet.maxRange + 2500, entityName: .wallets) { (success, errorDescription) in
                                        
                                        if success {
                                            
                                            completion((true, nil))
                                            
                                        } else {
                                            
                                            completion((false, errorDescription ?? "Error updating your wallet, please refill again"))
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    if let errorDict = dict["error"] as? NSDictionary {
                                        
                                        if let error = errorDict["message"] as? String {
                                            
                                            completion((false, error))
                                            
                                        } else {
                                            
                                            completion((false, "unknown error"))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((false, "unknown error"))
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        let params = "[{ \"desc\": \"\(wallet.descriptor)\", \"timestamp\": \"now\", \"range\": [\(wallet.maxRange),\(wallet.maxRange + 2500)], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": true, \"internal\": false }]"
        
        Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: params) { (object, errorDesc) in
            
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
                                        
                                        completion((false, "unknown error"))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((false, "unknown error"))
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}
