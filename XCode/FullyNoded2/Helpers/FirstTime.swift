//
//  FirstTime.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class FirstTime {
    
    let ud = UserDefaults.standard
    
    func firstTimeHere(completion: @escaping ((Bool)) -> Void) {
        if KeyChain.getData("privateKey") == nil {
            let privateKey = Encryption.privateKey()
            if KeyChain.set(privateKey, forKey: "privateKey") {
                print("set new private key")
                let keypair = KeyGen.generate()
                let pubkeyData = keypair.pubKey.dataUsingUTF8StringEncoding
                let privkeyData = keypair.privKey.dataUsingUTF8StringEncoding
                Encryption.encryptData(dataToEncrypt: privkeyData) { (encryptedPrivkey, error) in
                    if !error {
                        let dict = ["privkey":encryptedPrivkey!, "pubkey":pubkeyData]
                        CoreDataService.retrieveEntity(entityName: .auth) { (entity, errorDescription) in
                            if errorDescription == nil && entity != nil {
                                if entity!.count == 0 {
                                    CoreDataService.saveEntity(dict: dict, entityName: .auth) { (success, errorDescription) in
                                        if success {
                                            self.ud.set(false, forKey: "firstTime")
                                            completion(true)
                                        } else {
                                            print("error saving auth keys")
                                            completion(false)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        print("error encrypting auth key")
                        completion(false)
                    }
                }
            } else {
                print("keychain did not set privkey")
                completion(false)
            }
        }
    }
    
}

