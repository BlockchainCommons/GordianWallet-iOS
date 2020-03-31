//
//  CreateMultisigWallet.swift
//  StandUp-Remote
//
//  Created by Peter on 14/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class CreateMultiSigWallet {
    
    let cd = CoreDataService()
    let enc = Encryption()
    
    func create(wallet: WalletStruct, nodeXprv: String, nodeXpub: String, completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        let reducer = Reducer()
        
        func importChange() {
            
            let array = (wallet.changeDescriptor).split(separator: "#")
            var descriptor = "\(array[0])"
            descriptor = descriptor.replacingOccurrences(of: nodeXpub, with: nodeXprv)
            
            reducer.makeCommand(walletName: wallet.name, command: .getdescriptorinfo, param: "\"\(descriptor)\"") {
                
                if !reducer.errorBool {
                    
                    if let updatedDescriptor = reducer.dictToReturn?["descriptor"] as? String {
                        
                        if let checksum = reducer.dictToReturn?["checksum"] as? String {
                            
                            let array = updatedDescriptor.split(separator: "#")
                            
                            if array.count > 0 {
                                
                                let hotDescriptor = "\(array[0])" + "#" + checksum
                                
                                var params = "[{ \"desc\": \"\(hotDescriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }], {\"rescan\": false}"
                                params = params.replacingOccurrences(of: nodeXpub, with: nodeXprv)
                                reducer.makeCommand(walletName: wallet.name, command: .importmulti, param: params) {
                                    
                                    if !reducer.errorBool {
                                        
                                        completion((true, nil))
                                        
                                    } else {
                                        
                                        completion((false, reducer.errorDescription))
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        func importMulti(param: Any) {
        
            reducer.makeCommand(walletName: wallet.name, command: .importmulti, param: param) {
                
                if !reducer.errorBool {
                    
                    if let result = reducer.arrayToReturn {
                        
                        if result.count > 0 {
                            
                            if let dict = result[0] as? NSDictionary {
                                
                                if let success = dict["success"] as? Bool {
                                    
                                    if success {
                                        
                                        print("success")
                                        importChange()
                                        
                                    } else {
                                        
                                        if let errorDict = dict["error"] as? NSDictionary {
                                            
                                            if let error = errorDict["message"] as? String {
                                                
                                                completion((false, "error importing multi: \(error)"))
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    completion((false, reducer.errorDescription))
                    
                }
                
            }
            
        }
        
        func createWallet() {
                
                let reducer = Reducer()
                let param = "\"\(wallet.name)\", false, true, \"\", true"
                reducer.makeCommand(walletName: wallet.name, command: .createwallet, param: param) {
                    
                    if !reducer.errorBool {
                        
                        let array = (wallet.descriptor).split(separator: "#")
                        var descriptor = "\(array[0])"
                        descriptor = descriptor.replacingOccurrences(of: nodeXpub, with: nodeXprv)
                        
                        reducer.makeCommand(walletName: wallet.name, command: .getdescriptorinfo, param: "\"\(descriptor)\"") {
                            
                            if !reducer.errorBool {
                                
                                if let updatedDescriptor = reducer.dictToReturn?["descriptor"] as? String {
                                    
                                    if let checksum = reducer.dictToReturn?["checksum"] as? String {
                                        
                                        let array = updatedDescriptor.split(separator: "#")
                                        let hotDescriptor = "\(array[0])" + "#" + checksum
                                        
                                        var params = "[{ \"desc\": \"\(hotDescriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }], {\"rescan\": false}"
                                        params = params.replacingOccurrences(of: nodeXpub, with: nodeXprv)
                                        importMulti(param: params)
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        completion((false, reducer.errorDescription))
                        
                    }
                    
                }
                
            }
        
        createWallet()
        
    }
    
}
