//
//  ImportCustomDescriptor.swift
//  FullyNoded2
//
//  Created by Peter on 10/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class ImportCustomDescriptor {
    
    func create(descriptor: String, completion: @escaping ((success: Bool, error:Bool, errorDescription: String?)) -> Void) {
        
        func importChange(str: WalletStruct, params: String, reducer: Reducer, newWallet: [String:Any], descStruct: DescriptorStruct) {
            print("importChange")
            
            reducer.makeCommand(walletName: str.name, command: .importmulti, param: params) {
                print("import change param: \(params)")
                
                if !reducer.errorBool {
                    
                    let walletSaver = WalletSaver()
                    walletSaver.save(walletToSave: newWallet) { (success) in
                        
                        if success {
                            
                            completion((true, false, nil))
                            
                        } else {
                            
                            completion((false, true, "failed saving wallet locally"))
                            
                        }
                        
                    }
                    
                } else {
                    
                    completion((false, true, reducer.errorDescription))
                    
                }
                
            }
            
        }
        
        func importPrimary(str: WalletStruct, params: String, reducer: Reducer, newWallet: [String:Any], descStruct: DescriptorStruct, descriptor: String) {
            print("importprimary")
            
            reducer.makeCommand(walletName: str.name, command: .importmulti, param: params) {
                
                if !reducer.errorBool {
                    
                    if !descStruct.isMulti {
                        
                        var changeParams = ""
                        
                        if descStruct.isHot {
                            
                            changeParams = "[{ \"desc\": \"\(descriptor)\", \"timestamp\": \"now\", \"range\": [1000,1999], \"watchonly\": false, \"keypool\": true, \"internal\": true }]"
                            
                        } else {
                            
                            changeParams = "[{ \"desc\": \"\(descriptor)\", \"timestamp\": \"now\", \"range\": [1000,1999], \"watchonly\": true, \"keypool\": true, \"internal\": true }]"
                            
                        }
                        
                        importChange(str: str, params: changeParams, reducer: reducer, newWallet: newWallet, descStruct: descStruct)
                        
                    } else {
                        
                        let walletSaver = WalletSaver()
                        walletSaver.save(walletToSave: newWallet) { (success) in
                            
                            if success {
                                
                                completion((true, false, nil))
                                
                            } else {
                                
                                completion((false, true, "failed saving wallet locally"))
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    completion((false, true, reducer.errorDescription))
                    
                }
                
            }
            
        }
        
        let enc = Encryption()
        enc.getNode { (node, error) in
            
            if node != nil && !error {
                
                let reducer = Reducer()
                var newWallet = [String:Any]()
                newWallet["birthdate"] = keyBirthday()
                newWallet["id"] = UUID()
                newWallet["isActive"] = false
                newWallet["name"] = "\(randomString(length: 10))_StandUp"
                newWallet["lastUsed"] = Date()
                newWallet["lastBalance"] = 0.0
                newWallet["type"] = "CUSTOM"
                newWallet["nodeId"] = node!.id
                newWallet["isArchived"] = false
                let str = WalletStruct(dictionary: newWallet)
                let param = "\"\(str.name)\", true, true, \"\", true"
                reducer.makeCommand(walletName: str.name, command: .createwallet, param: param) {
                    
                    if !reducer.errorBool {
                        
                        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(descriptor)\"") {
                            
                            if !reducer.errorBool {
                                
                                let result = reducer.dictToReturn
                                let processedDescriptor = result["descriptor"] as! String
                                newWallet["descriptor"] = processedDescriptor
                                var params = ""
                                let descParser = DescriptorParser()
                                let descStruct = descParser.descriptor(processedDescriptor)
                                if descStruct.isHot {
                                    
                                    if !descStruct.isMulti {
                                        
                                        // import change too, designate first 1,000 as primary
                                        params = "[{ \"desc\": \"\(processedDescriptor)\", \"timestamp\": \"now\", \"range\": [0,999], \"watchonly\": false, \"label\": \"FullyNoded2\", \"keypool\": true, \"internal\": false }]"
                                        
                                    } else {
                                        
                                        // its mutlisig, import 2,000 as we can't add keys to keypool
                                        params = "[{ \"desc\": \"\(processedDescriptor)\", \"timestamp\": \"now\", \"range\": [0,1999], \"watchonly\": false, \"label\": \"FullyNoded2\", \"keypool\": false, \"internal\": false }]"
                                        
                                    }
                                    
                                } else {
                                    
                                    if !descStruct.isMulti {
                                        
                                        // import change too, designate first 1,000 as primary
                                        params = "[{ \"desc\": \"\(processedDescriptor)\", \"timestamp\": \"now\", \"range\": [0,999], \"watchonly\": true, \"label\": \"FullyNoded2\", \"keypool\": true, \"internal\": false }]"
                                        
                                    } else {
                                        
                                        // its mutlisig, import 2,000 as we can't add keys to keypool
                                        params = "[{ \"desc\": \"\(processedDescriptor)\", \"timestamp\": \"now\", \"range\": [0,1999], \"watchonly\": true, \"label\": \"FullyNoded2\", \"keypool\": false, \"internal\": false }]"
                                        
                                    }
                                    
                                }
                                
                                importPrimary(str: str, params: params, reducer: reducer, newWallet: newWallet, descStruct: descStruct, descriptor: processedDescriptor)
                                
                                                                
                            } else {
                                
                                completion((false, true, reducer.errorDescription))
                                
                            }
                            
                        }
                        
                    } else {
                        
                        completion((false, true, reducer.errorDescription))
                        
                    }
                    
                }
                
            } else {
                
                completion((false, true, "error getting active node"))
                
            }
            
        }
        
    }
        
}
