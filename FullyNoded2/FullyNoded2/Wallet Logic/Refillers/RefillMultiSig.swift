//
//  RefillMultiSig.swift
//  FullyNoded2
//
//  Created by Peter on 29/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class RefillMultiSig {
    
    let cd = CoreDataService()
    let enc = Encryption()
    
    func refill(wallet: WalletStruct, recoveryXprv: String, recoveryXpub: String, completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        let reducer = Reducer()
        
        func importChange() {
            
            let array = (wallet.changeDescriptor).split(separator: "#")
            var descriptor = "\(array[0])"
            descriptor = descriptor.replacingOccurrences(of: recoveryXpub, with: recoveryXprv)
            
            reducer.makeCommand(walletName: wallet.name, command: .getdescriptorinfo, param: "\"\(descriptor)\"") {
                
                if !reducer.errorBool {
                    
                    if let updatedDescriptor = reducer.dictToReturn?["descriptor"] as? String {
                        
                        if let checksum = reducer.dictToReturn?["checksum"] as? String {
                            
                            let array = updatedDescriptor.split(separator: "#")
                            
                            if array.count > 0 {
                                
                                let hotDescriptor = "\(array[0])" + "#" + checksum
                                
                                var params = "[{ \"desc\": \"\(hotDescriptor)\", \"timestamp\": \"now\", \"range\": [\(wallet.maxRange),\(wallet.maxRange + 2500)], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }], {\"rescan\": false}"
                                params = params.replacingOccurrences(of: recoveryXpub, with: recoveryXprv)
                                reducer.makeCommand(walletName: wallet.name, command: .importmulti, param: params) {
                                    
                                    if !reducer.errorBool {
                                        
                                        self.cd.updateEntity(id: wallet.id, keyToUpdate: "maxRange", newValue: wallet.maxRange + 2500, entityName: .wallets) {
                                            
                                            if !self.cd.errorBool {
                                                
                                                completion((true, nil))
                                                
                                            } else {
                                                
                                                completion((false, "Error updating wallet maxRange property. Wallet refill was successfull though!"))
                                                
                                            }
                                            
                                        }
                                        
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
        
        func refillWallet() {
                
                let reducer = Reducer()
                let array = (wallet.descriptor).split(separator: "#")
                var descriptor = "\(array[0])"
                descriptor = descriptor.replacingOccurrences(of: recoveryXpub, with: recoveryXprv)
                
                reducer.makeCommand(walletName: wallet.name, command: .getdescriptorinfo, param: "\"\(descriptor)\"") {
                    
                    if !reducer.errorBool {
                        
                        if let updatedDescriptor = reducer.dictToReturn?["descriptor"] as? String {
                            
                            if let checksum = reducer.dictToReturn?["checksum"] as? String {
                                
                                let array = updatedDescriptor.split(separator: "#")
                                let hotDescriptor = "\(array[0])" + "#" + checksum
                                
                                var params = "[{ \"desc\": \"\(hotDescriptor)\", \"timestamp\": \"now\", \"range\": [\(wallet.maxRange),\(wallet.maxRange + 2500)], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }], {\"rescan\": false}"
                                params = params.replacingOccurrences(of: recoveryXpub, with: recoveryXprv)
                                importMulti(param: params)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
        
        refillWallet()
        
    }
    
}
