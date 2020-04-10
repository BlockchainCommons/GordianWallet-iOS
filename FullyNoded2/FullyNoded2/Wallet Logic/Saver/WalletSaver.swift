//
//  WalletSaver.swift
//  StandUp-Remote
//
//  Created by Peter on 09/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class WalletSaver {
        
    func save(walletToSave: [String:Any], completion: @escaping ((Bool)) -> Void) {
        
        CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
            
            if errorDescription == nil {
                
                CoreDataService.saveEntity(dict: walletToSave, entityName: .wallets) { (success, errorDescription) in
                    
                    if success {
                        
                        if wallets!.count == 0 {
                            
                            let w = WalletStruct(dictionary: walletToSave)
                            
                            CoreDataService.updateEntity(id: w.id!, keyToUpdate: "isActive", newValue: true, entityName: .wallets) { (success1, errorDescription1) in
                                
                                if success1 {
                                    
                                  completion((true))
                                    
                                } else {
                                    
                                    completion((false))
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            completion((true))
                            
                        }
                        
                    } else {
                        
                        print("error saving wallet")
                        completion((false))
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}
