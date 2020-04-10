//
//  CreateMultisigWallet.swift
//  StandUp-Remote
//
//  Created by Peter on 14/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class CreateMultiSigWallet {
        
    func create(wallet: WalletStruct, nodeXprv: String, nodeXpub: String, completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        func importChange() {
            
            let array = (wallet.changeDescriptor).split(separator: "#")
            var descriptor = "\(array[0])"
            descriptor = descriptor.replacingOccurrences(of: nodeXpub, with: nodeXprv)
            
            Reducer.makeCommand(walletName: wallet.name!, command: .getdescriptorinfo, param: "\"\(descriptor)\"") { (object, errorDesc) in
                
                if let dict = object as? NSDictionary {
                    
                    if let updatedDescriptor = dict["descriptor"] as? String {
                        
                        if let checksum = dict["checksum"] as? String {
                            
                            let array = updatedDescriptor.split(separator: "#")
                            
                            if array.count > 0 {
                                
                                let hotDescriptor = "\(array[0])" + "#" + checksum
                                
                                var params = "[{ \"desc\": \"\(hotDescriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }], {\"rescan\": false}"
                                params = params.replacingOccurrences(of: nodeXpub, with: nodeXprv)
                                Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: params) { (object, errorDesc) in
                                    
                                    if object != nil {
                                        
                                        completion((true, nil))
                                        
                                    } else {
                                        
                                        completion((false, errorDesc))
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        func importMulti(param: Any) {
        
            Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: param) { (object, errorDesc) in
                
                if let result = object as? NSArray {
                    
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
                    
                } else {
                    
                    completion((false, errorDesc))
                    
                }
                
            }
            
        }
        
        func createWallet() {
                
                let param = "\"\(wallet.name!)\", false, true, \"\", true"
                Reducer.makeCommand(walletName: wallet.name!, command: .createwallet, param: param) { (object, errorDesc) in
                    
                    if object != nil {
                        
                        let array = (wallet.descriptor).split(separator: "#")
                        var descriptor = "\(array[0])"
                        descriptor = descriptor.replacingOccurrences(of: nodeXpub, with: nodeXprv)
                        
                        Reducer.makeCommand(walletName: wallet.name!, command: .getdescriptorinfo, param: "\"\(descriptor)\"") { (object, errorDesc) in
                            
                            if let dict = object as? NSDictionary {
                                
                                if let updatedDescriptor = dict["descriptor"] as? String {
                                    
                                    if let checksum = dict["checksum"] as? String {
                                        
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
                        
                        completion((false, errorDesc))
                        
                    }
                    
                }
                
            }
        
        createWallet()
        
    }
    
}
