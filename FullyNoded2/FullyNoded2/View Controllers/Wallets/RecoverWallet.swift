//
//  RecoverWallet.swift
//  FullyNoded2
//
//  Created by Peter on 27/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import LibWally

class RecoverWallet {
    
    var words = ""
    var json:[String:Any]!
    var descriptorStruct:DescriptorStruct!
    var descriptor:String!
    var birthdate:Int32!
    var walletName:String!
    
    enum recoveryType: CaseIterable {
        
        case fullMultiSig, partialMultiSig, singleSig, unknown
    }
    
    private func recoveryType() -> recoveryType {
        
        if json != nil && words != "" {
            
            return .fullMultiSig
            
        } else if json != nil && words == "" {
            
            if descriptorStruct.isMulti {
                
                return .partialMultiSig
                
            } else {
                
                return .singleSig
                
            }
            
        } else if json == nil && words != "" {
            
            return .singleSig
            
        } else {
            
            return .unknown
            
        }
        
    }
    
    private func recoverPartialMultiSigQR(completion: @escaping ((Bool)) -> Void) {
        print("recoverPartialMultiSigQR")
        
        let enc = Encryption()
        if let unEncryptedXprv = descriptorStruct.multiSigKeys[1].data(using: .utf8) {
         
            enc.encryptData(dataToEncrypt: unEncryptedXprv) { (encryptedData, error) in
                
                if !error && encryptedData != nil {
                    
                    let walletName = self.json["walletName"] as! String
                    var newWallet = [String:Any]()
                    newWallet["xprv"] = encryptedData!
                    newWallet["birthdate"] = self.json["birthdate"] as! Int32
                    newWallet["derivation"] = self.descriptorStruct.derivationArray[1]
                    newWallet["id"] = UUID()
                    newWallet["isActive"] = false
                    newWallet["lastUsed"] = Date()
                    newWallet["lastBalance"] = 0.0
                    newWallet["isArchived"] = false
                    newWallet["name"] = walletName
                    newWallet["type"] = "MULTI"
                    
                    enc.getNode { (node, error) in
                        
                        if !error && node != nil {
                            
                            newWallet["nodeId"] = node!.id
                            
                            // need to check if wallet exists on our node or not first
                            let reducer = Reducer()
                            reducer.makeCommand(walletName: "", command: .listwalletdir, param: "") {
                                
                                if !reducer.errorBool {
                                    
                                    let dict = reducer.dictToReturn
                                    let wallets = dict["wallets"] as! NSArray
                                    var walletExists = false
                                    
                                    for (i, wallet) in wallets.enumerated() {
                                        
                                        let name = (wallet as! NSDictionary)["name"] as! String
                                        
                                        if name == walletName {
                                            
                                            walletExists = true
                                            
                                        }
                                        
                                        if i + 1 == wallets.count {
                                            
                                            if walletExists {
                                                
                                                print("we have a winner, the wallet is on our node")
                                                // need to convert existing descriptor to a public key descriptor and a change descriptor
                                                let hdXprv = HDKey(self.descriptorStruct.multiSigKeys[1])
                                                if let accountXpub = hdXprv?.xpub {
                                                    
                                                    self.descriptor = (self.json["descriptor"] as! String)
                                                    let primaryPublicKeyDescriptor = self.descriptor.replacingOccurrences(of: self.descriptorStruct.multiSigKeys[1], with: accountXpub)
                                                    newWallet["descriptor"] = primaryPublicKeyDescriptor
                                                     var changeDesc = primaryPublicKeyDescriptor.replacingOccurrences(of: "\(accountXpub)/0/*", with: "\(accountXpub)/1/*")
                                                    changeDesc = changeDesc.replacingOccurrences(of: "\(self.descriptorStruct.multiSigKeys[0])/0/*", with: "\(self.descriptorStruct.multiSigKeys[0])/1/*")
                                                    changeDesc = changeDesc.replacingOccurrences(of: "\(self.descriptorStruct.multiSigKeys[2])/0/*", with: "\(self.descriptorStruct.multiSigKeys[2])/1/*")
                                                    
                                                    let arr = changeDesc.split(separator: "#")
                                                    changeDesc = "\(arr[0])"
                                                    reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") {
                                                        
                                                        if !reducer.errorBool {
                                                            
                                                            let result = reducer.dictToReturn
                                                            newWallet["changeDescriptor"] = result["descriptor"] as! String
                                                            let walletSaver = WalletSaver()
                                                            walletSaver.save(walletToSave: newWallet) { (success) in
                                                                
                                                                if success {
                                                                    
                                                                    completion((true))
                                                                    
                                                                } else {
                                                                    
                                                                    completion((false))
                                                                    
                                                                }
                                                                
                                                            }
                                                            
                                                        } else {
                                                            
                                                            completion((false))
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                } else {
                                                    
                                                    completion((false))
                                                    print("failed deriving account xpub")
                                                    
                                                }
                                                
                                                
                                            } else {
                                                
                                                completion((false))
                                                print("wallet does not exist, need to recreate it")
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((false))
                                    print("recovery error: \(reducer.errorDescription)")
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    private func recoverSingleSigQR(completion: @escaping ((Bool)) -> Void) {
        print("recoverSingleSigQR")
        
        let enc = Encryption()
        if let unEncryptedXprv = descriptorStruct.accountXprv.data(using: .utf8) {
         
            enc.encryptData(dataToEncrypt: unEncryptedXprv) { (encryptedData, error) in
                
                if !error && encryptedData != nil {
                    
                    let walletName = self.json["walletName"] as! String
                    var newWallet = [String:Any]()
                    newWallet["xprv"] = encryptedData!
                    newWallet["birthdate"] = self.json["birthdate"] as! Int32
                    newWallet["derivation"] = self.descriptorStruct.derivation
                    newWallet["id"] = UUID()
                    newWallet["isActive"] = false
                    newWallet["lastUsed"] = Date()
                    newWallet["lastBalance"] = 0.0
                    newWallet["isArchived"] = false
                    newWallet["name"] = walletName
                    newWallet["type"] = "DEFAULT"
                    
                    enc.getNode { (node, error) in
                        
                        if !error && node != nil {
                            
                            newWallet["nodeId"] = node!.id
                            
                            // need to check if wallet exists on our node or not first
                            let reducer = Reducer()
                            reducer.makeCommand(walletName: "", command: .listwalletdir, param: "") {
                                
                                if !reducer.errorBool {
                                    
                                    let dict = reducer.dictToReturn
                                    let wallets = dict["wallets"] as! NSArray
                                    var walletExists = false
                                    
                                    for (i, wallet) in wallets.enumerated() {
                                        
                                        let name = (wallet as! NSDictionary)["name"] as! String
                                        
                                        if name == walletName {
                                            
                                            walletExists = true
                                            
                                        }
                                        
                                        if i + 1 == wallets.count {
                                            
                                            if walletExists {
                                                
                                                print("we have a winner, the wallet is on our node")
                                                // need to convert existing descriptor to a public key descriptor and a change descriptor
                                                let hdXprv = HDKey(self.descriptorStruct.accountXprv)
                                                if let accountXpub = hdXprv?.xpub {
                                                    
                                                    self.descriptor = (self.json["descriptor"] as! String)
                                                    let primaryPublicKeyDescriptor = self.descriptor.replacingOccurrences(of: self.descriptorStruct.accountXprv, with: accountXpub)
                                                    newWallet["descriptor"] = primaryPublicKeyDescriptor
                                                    newWallet["changeDescriptor"] = primaryPublicKeyDescriptor.replacingOccurrences(of: "\(accountXpub)/0/*", with: "\(accountXpub)/1/*")
                                                    
                                                    let walletSaver = WalletSaver()
                                                    walletSaver.save(walletToSave: newWallet) { (success) in
                                                        
                                                        if success {
                                                            
                                                            completion((true))
                                                            
                                                        } else {
                                                            
                                                            completion((false))
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                } else {
                                                    
                                                    completion((false))
                                                    print("failed deriving account xpub")
                                                    
                                                }
                                                
                                                
                                            } else {
                                                
                                                completion((false))
                                                print("wallet does not exist, need to recreate it")
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((false))
                                    print("recovery error: \(reducer.errorDescription)")
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func recover(completion: @escaping ((Bool)) -> Void) {
        
        if json != nil {
        
            let p = DescriptorParser()
            descriptorStruct = p.descriptor(json["descriptor"] as! String)
            
            let type = self.recoveryType()
            
            switch type {
                
            case .fullMultiSig:
                print("full multisig recovery")
            
            case .partialMultiSig:
                print("partial multisig recovery")
                recoverPartialMultiSigQR(completion: completion)
                
            case .singleSig:
                print("single sig recovery")
                recoverSingleSigQR(completion: completion)
                
            case .unknown:
                print("unknown")
                
            }
        
        } else {
            
            // we know its just words, so it is single signature
            
        }
        
    }
    
}
