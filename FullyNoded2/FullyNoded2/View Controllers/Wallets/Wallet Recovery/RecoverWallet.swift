//
//  RecoverWallet.swift
//  FullyNoded2
//
//  Created by Peter on 27/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import CryptoKit
import Foundation
import LibWally

class RecoverWallet {
    
    enum recoveryType: CaseIterable {
        
        case fullMultiSig, partialMultiSig, singleSig, unknown
    }
    
    private func recoveryType(json: [String:Any], words: String?) -> recoveryType {
                
        if words != nil {
            
            if json["descriptor"] != nil && words != "" {
                
                return .fullMultiSig
                
            } else if json["descriptor"] == nil && words != "" {
                
                return .singleSig
                
            } else {
                
                return .unknown
                
            }
            
        } else {
            
            let p = DescriptorParser()
            let desc = json["descriptor"] as! String
            let descriptorStruct = p.descriptor(desc)
            
            if descriptorStruct.isMulti {
                
                return .partialMultiSig
                
            } else {
                
                return .singleSig
                
            }
            
        }
        
    }
    
    private func recoverPartialMultiSigQR(node: NodeStruct, json: [String:Any], completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        let hotDescriptor = json["descriptor"] as! String
        let p = DescriptorParser()
        let descriptorStruct = p.descriptor(hotDescriptor)
        let enc = Encryption.sharedInstance
        if let unEncryptedXprv = descriptorStruct.multiSigKeys[1].data(using: .utf8) {
            
            enc.encryptData(dataToEncrypt: unEncryptedXprv) {  (encryptedData, error) in
                
                if !error && encryptedData != nil {
                    
                    let unencryptedEntropy = json["entropy"] as! String
                    
                    if let bip39Entropy = BIP39Entropy(unencryptedEntropy) {
                        
                        if let bip39Mnemonic = BIP39Mnemonic(bip39Entropy) {
                            
                            let unencryptedWords = bip39Mnemonic.words
                            let joinedWords = unencryptedWords.joined(separator: " ")
                            enc.encryptData(dataToEncrypt: joinedWords.dataUsingUTF8StringEncoding) { (encryptedSeed, error) in
                                
                                if !error && encryptedData != nil {
                                    
                                    var newWallet = [String:Any]()
                                    newWallet["xprv"] = encryptedData!
                                    newWallet["birthdate"] = json["birthdate"] as! Int32
                                    newWallet["derivation"] = descriptorStruct.derivationArray[1]
                                    newWallet["id"] = UUID()
                                    newWallet["isActive"] = false
                                    newWallet["lastUsed"] = Date()
                                    newWallet["lastBalance"] = 0.0
                                    newWallet["isArchived"] = false
                                    newWallet["type"] = "MULTI"
                                    newWallet["seed"] = encryptedSeed!
                                    newWallet["nodeId"] = node.id
                                    newWallet["blockheight"] = json["blockheight"] as! Int
                                    newWallet["maxRange"] = 2500
                                    
                                    if let label = json["label"] as? String {
                                        
                                        newWallet["label"] = label
                                        
                                    }
                                    
                                    let hdXprv = HDKey(descriptorStruct.multiSigKeys[1])
                                    if let accountXpub = hdXprv?.xpub {
                                        
                                        //self.descriptor = (vc.json["descriptor"] as! String)
                                        let primaryPublicKeyDescriptor = hotDescriptor.replacingOccurrences(of: descriptorStruct.multiSigKeys[1], with: accountXpub)
                                        newWallet["descriptor"] = primaryPublicKeyDescriptor
                                        let digest = SHA256.hash(data: primaryPublicKeyDescriptor.dataUsingUTF8StringEncoding)
                                        let walletName = digest.map { String(format: "%02hhx", $0) }.joined()
                                        newWallet["name"] = walletName
                                        
                                        // need to check if wallet exists on our node or not first
                                        let reducer = Reducer()
                                        reducer.makeCommand(walletName: "", command: .listwalletdir, param: "") {
                                            
                                            if !reducer.errorBool {
                                                
                                                if let dict = reducer.dictToReturn {
                                                    
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
                                                                let hdXprv = HDKey(descriptorStruct.multiSigKeys[1])
                                                                if let accountXpub = hdXprv?.xpub {
                                                                    
                                                                    //hotDescriptor = (vc.json["descriptor"] as! String)
                                                                    let primaryPublicKeyDescriptor = hotDescriptor.replacingOccurrences(of: descriptorStruct.multiSigKeys[1], with: accountXpub)
                                                                    newWallet["descriptor"] = primaryPublicKeyDescriptor
                                                                    let changeDesc = self.multiSigChangeDescriptor(primary: primaryPublicKeyDescriptor, xpub: accountXpub, descStruct: descriptorStruct)
                                                                    
//                                                                    var changeDesc = primaryPublicKeyDescriptor.replacingOccurrences(of: "\(accountXpub)/0/*", with: "\(accountXpub)/1/*")
//                                                                    changeDesc = changeDesc.replacingOccurrences(of: "\(descriptorStruct.multiSigKeys[0])/0/*", with: "\(descriptorStruct.multiSigKeys[0])/1/*")
//                                                                    changeDesc = changeDesc.replacingOccurrences(of: "\(descriptorStruct.multiSigKeys[2])/0/*", with: "\(descriptorStruct.multiSigKeys[2])/1/*")
                                                                    
                                                                    //let arr = changeDesc.split(separator: "#")
                                                                    //changeDesc = "\(arr[0])"
                                                                    reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") {
                                                                        
                                                                        if !reducer.errorBool {
                                                                            
                                                                            if let result = reducer.dictToReturn {
                                                                                
                                                                                if let changeDescriptor = result["descriptor"] as? String {
                                                                                    
                                                                                    newWallet["changeDescriptor"] = changeDescriptor
                                                                                    self.saveWallet(wallet: newWallet, completion: completion)
                                                                                    
                                                                                }
                                                                                
                                                                                
                                                                            }
                                                                            
                                                                        } else {
                                                                            
                                                                            completion((false, reducer.errorDescription))
                                                                            
                                                                        }
                                                                        
                                                                    }
                                                                    
                                                                } else {
                                                                    
                                                                    completion((false, "failed deriving account xpub"))
                                                                    
                                                                }
                                                                
                                                                
                                                            } else {
                                                                
                                                                completion((false, "wallet does not exist, are you sure you are connected to the correct node?"))
                                                                
                                                            }
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                }
                                                
                                            } else {
                                                
                                                completion((false, reducer.errorDescription))
                                                
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((false, "failed deriving account xpub"))
                                        
                                    }
                                                                        
                                } else {
                                    
                                    completion((false, "failed encrypting mnemonic"))
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            completion((false, "failed converting entropy to mnemonic"))
                            
                        }
                        
                    } else {
                        
                        completion((false, "failed converting entropy string to bip39 entropy"))
                        
                    }
                    
                } else {
                    
                    completion((false, "failed encrypting xprv"))
                    
                }
                
            }
            
        } else {
            
            completion((false, "failed converting xprv to data"))
            
        }
        
    }
    
    private func recoverSingleSigQR(node: NodeStruct, json: [String:Any], completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        let enc = Encryption.sharedInstance
        let parser = DescriptorParser()
        let hotDescriptor = json["descriptor"] as! String
        let descriptorStruct = parser.descriptor(hotDescriptor)
        
        if let unEncryptedXprv = descriptorStruct.accountXprv.data(using: .utf8) {
            
            enc.encryptData(dataToEncrypt: unEncryptedXprv) {  (encryptedData, error) in
                
                if !error && encryptedData != nil {
                    
                    let unencryptedEntropy = json["entropy"] as! String
                    
                    if let bip39Entropy = BIP39Entropy(unencryptedEntropy) {
                        
                        if let bip39Mnemonic = BIP39Mnemonic(bip39Entropy) {
                            
                            let unencryptedWords = bip39Mnemonic.words
                            let joinedWords = unencryptedWords.joined(separator: " ")
                            enc.encryptData(dataToEncrypt: joinedWords.dataUsingUTF8StringEncoding) { (encryptedSeed, error) in
                                
                                if !error && encryptedData != nil {
                                    
                                    var newWallet = [String:Any]()
                                    newWallet["xprv"] = encryptedData!
                                    newWallet["birthdate"] = json["birthdate"] as! Int32
                                    newWallet["derivation"] = descriptorStruct.derivation
                                    newWallet["id"] = UUID()
                                    newWallet["isActive"] = false
                                    newWallet["lastUsed"] = Date()
                                    newWallet["lastBalance"] = 0.0
                                    newWallet["isArchived"] = false
                                    newWallet["type"] = "DEFAULT"
                                    newWallet["seed"] = encryptedSeed!
                                    newWallet["nodeId"] = node.id
                                    newWallet["blockheight"] = json["blockheight"] as! Int
                                    newWallet["maxRange"] = 2500
                                    
                                    if let label = json["label"] as? String {
                                        
                                        newWallet["label"] = label
                                        
                                    }
                                    
                                    let hdXprv = HDKey(descriptorStruct.accountXprv)
                                    if let accountXpub = hdXprv?.xpub {
                                        
                                        //vc.descriptor = (vc.json["descriptor"] as! String)
                                        let primaryPublicKeyDescriptor = hotDescriptor.replacingOccurrences(of: descriptorStruct.accountXprv, with: accountXpub)
                                        
                                        let reducer = Reducer()
                                        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryPublicKeyDescriptor)\"") {
                                            
                                            if !reducer.errorBool {
                                                
                                                if let dict = reducer.dictToReturn {
                                                    
                                                    let primaryDescriptor = dict["descriptor"] as! String
                                                    newWallet["descriptor"] = primaryDescriptor
                                                    let digest = SHA256.hash(data: primaryDescriptor.dataUsingUTF8StringEncoding)
                                                    let walletName = digest.map { String(format: "%02hhx", $0) }.joined()
                                                    newWallet["name"] = walletName
                                                    
                                                    var changeDesc = primaryPublicKeyDescriptor.replacingOccurrences(of: "\(accountXpub)/0/*", with: "\(accountXpub)/1/*")
                                                    let arr = changeDesc.split(separator: "#")
                                                    changeDesc = "\(arr[0])"
                                                    
                                                    reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") {
                                                        
                                                        if !reducer.errorBool {
                                                            
                                                            if let dict = reducer.dictToReturn {
                                                                
                                                                let changeDescriptor = dict["descriptor"] as! String
                                                                newWallet["changeDescriptor"] = changeDescriptor
                                                                
                                                                // need to check if wallet exists on our node or not first
                                                                let reducer = Reducer()
                                                                reducer.makeCommand(walletName: "", command: .listwalletdir, param: "") {
                                                                    
                                                                    if !reducer.errorBool {
                                                                        
                                                                        if let dict = reducer.dictToReturn {
                                                                            
                                                                            if let wallets = dict["wallets"] as? NSArray {
                                                                                
                                                                                var walletExists = false
                                                                                
                                                                                for (i, wallet) in wallets.enumerated() {
                                                                                    
                                                                                    if let walletDict = wallet as? NSDictionary {
                                                                                        
                                                                                        if let name = walletDict["name"] as? String {
                                                                                            
                                                                                            if name == walletName {
                                                                                                
                                                                                                walletExists = true
                                                                                                
                                                                                            }
                                                                                            
                                                                                            if i + 1 == wallets.count {
                                                                                                
                                                                                                if walletExists {
                                                                                                    
                                                                                                    print("we have a winner, the wallet is on our node")
                                                                                                    self.saveWallet(wallet: newWallet, completion: completion)
                                                                                                    
                                                                                                } else {
                                                                                                    
                                                                                                    //NEED TO FULLY RECOVER FROM THE QR HERE...
                                                                                                    let walletCreator = WalletCreator()
                                                                                                    walletCreator.walletDict = newWallet
                                                                                                    walletCreator.createStandUpWallet { (success, errorDescription) in
                                                                                                        
                                                                                                        if success {
                                                                                                            
                                                                                                            reducer.makeCommand(walletName: (newWallet["name"] as! String), command: .rescanblockchain, param: "\(json["blockheight"] as! Int)") {
                                                                                                                
                                                                                                                self.saveWallet(wallet: newWallet, completion: completion)
                                                                                                                
                                                                                                            }
                                                                                                                                                                                                                        
                                                                                                        } else {
                                                                                                            
                                                                                                            completion((false, errorDescription))
                                                                                                            
                                                                                                        }
                                                                                                        
                                                                                                    }
                                                                                                                                                                
                                                                                                }
                                                                                                
                                                                                            }
                                                                                            
                                                                                        }
                                                                                        
                                                                                    } else {
                                                                                        
                                                                                        completion((false, "unable to parse wallets from bitcoind"))
                                                                                        
                                                                                    }
                                                                                    
                                                                                }
                                                                                
                                                                            } else {
                                                                                
                                                                                completion((false, "no wallets exist on that node?"))
                                                                                
                                                                            }
                                                                            
                                                                        } else {
                                                                            
                                                                            completion((false, "invalid response from bitcoind"))
                                                                            
                                                                        }
                                                                        
                                                                    } else {
                                                                        
                                                                        completion((false, reducer.errorDescription))
                                                                        
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

                                    } else {
                                        
                                        completion((false, "failed deriving account xpub"))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((false, "failed encrypting the mnemonic"))
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            completion((false, "failed converting the entropy to a mnemonic"))
                            
                        }
                        
                    } else {
                        
                        completion((false, "failed converting entropy string to bip39 entropy"))
                        
                    }
                    
                } else {
                    
                    completion((false, "failed encrypting xprv"))
                    
                }
                
            }
            
        } else {
            
            completion((false, "failed converting xprv to data"))
            
        }
        
    }
    
    private func fullMultiSigRecovery(node: NodeStruct, json: [String:Any], words: String, completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        let enc = Encryption.sharedInstance
        let hotDescriptor = json["descriptor"] as! String
        let parser = DescriptorParser()
        let descriptorStruct = parser.descriptor(hotDescriptor)
        let blockheight = json["blockheight"] as! Int
        let localDerivation = descriptorStruct.derivationArray[1]
        let nodeDerivation = descriptorStruct.derivationArray[0]
        var newWallet = [String:Any]()
        newWallet["birthdate"] = json["birthdate"] as! Int32
        newWallet["id"] = UUID()
        newWallet["isActive"] = false
        newWallet["lastUsed"] = Date()
        newWallet["lastBalance"] = 0.0
        newWallet["isArchived"] = false
        newWallet["type"] = "MULTI"
        newWallet["derivation"] = localDerivation
        newWallet["nodeId"] = node.id
        newWallet["blockheight"] = blockheight
        newWallet["maxRange"] = 2500
        
        if let label = json["label"] as? String {
            
            newWallet["label"] = label
            
        }
        
        // when recovering a full multisig wallet we need to switch around the designated keys so that the backup becomes the nodes xprv, the backup is then essentially consumed and the multissig setup is now for all practical purposes a 2 of 2. When a user recovers a multisig wallet in this way we need to advise the user that it would be wise to sweep the wallet to a new multi-sig wallet.
        let oldRecoveryXpub = descriptorStruct.multiSigKeys[0]
        let deviceXprv = descriptorStruct.multiSigKeys[1]
        let oldNodeXpub = descriptorStruct.multiSigKeys[2]
        
        let unencryptedRecoveryKitWords = words
        
        // in this scenario we need to use the recovery kit words as the nodes signer
        if let bip39RecoveryKitWords = BIP39Mnemonic(unencryptedRecoveryKitWords) {
            
            if let nodesMasterKey = HDKey((bip39RecoveryKitWords.seedHex("")), network(path: nodeDerivation)) {
                
                if let path = BIP32Path(nodeDerivation) {
                    
                    do {
                        
                        let account = try nodesMasterKey.derive(path)
                        
                        if let nodesXprv = account.xpriv {
                            
                            if let deviceKey = HDKey(deviceXprv) {
                                
                                // first we need to get the public key descriptor and set it to the new wallet
                                let deviceXpub = deviceKey.xpub
                                let primaryDescriptor = hotDescriptor.replacingOccurrences(of: deviceXprv, with: deviceXpub)
                                newWallet["descriptor"] = primaryDescriptor
                                let digest = SHA256.hash(data: primaryDescriptor.dataUsingUTF8StringEncoding)
                                let walletName = digest.map { String(format: "%02hhx", $0) }.joined()
                                newWallet["name"] = walletName
                                
                                // then we need to get the change descriptor and set it to the new wallet
                                let changeDesc = multiSigChangeDescriptor(primary: primaryDescriptor, xpub: oldRecoveryXpub, descStruct: descriptorStruct)
//                                var changeDescriptor = primaryDescriptor.replacingOccurrences(of: "\(oldRecoveryXpub)/0/*", with: "\(oldRecoveryXpub)/1/*")
//                                changeDescriptor = changeDescriptor.replacingOccurrences(of: "\(deviceXpub)/0/*", with: "\(deviceXpub)/1/*")
//                                changeDescriptor = changeDescriptor.replacingOccurrences(of: "\(oldNodeXpub)/0/*", with: "\(oldNodeXpub)/1/*")
//                                let arr = changeDescriptor.split(separator: "#")
//                                changeDescriptor = "\(arr[0])"
                                
                                let reducer = Reducer()
                                reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") {
                                    
                                    if !reducer.errorBool {
                                        
                                        if let dict = reducer.dictToReturn {
                                            
                                            if let changeDescriptor = dict["descriptor"] as? String {
                                                
                                                newWallet["changeDescriptor"] = changeDescriptor
                                                // now we can actually create the wallet
                                                let entropy = json["entropy"] as! String
                                                
                                                if let bip39Entropy = BIP39Entropy(entropy) {
                                                    
                                                    if let mnemonic = BIP39Mnemonic(bip39Entropy) {
                                                        
                                                        let unencryptedWords = (mnemonic.words).joined(separator: " ")
                                                        let unencryptedWordsData = unencryptedWords.dataUsingUTF8StringEncoding
                                                        
                                                        enc.encryptData(dataToEncrypt: unencryptedWordsData) { (encryptedData, error) in
                                                            
                                                            if !error && encryptedData != nil {
                                                                
                                                                newWallet["seed"] = encryptedData!
                                                                let wallet = WalletStruct(dictionary: newWallet)
                                                                let create = CreateMultiSigWallet()
                                                                
                                                                create.create(wallet: wallet, nodeXprv: nodesXprv, nodeXpub: oldRecoveryXpub) { (success, error) in
                                                                    
                                                                    if success {
                                                                        
                                                                        reducer.makeCommand(walletName: walletName, command: .rescanblockchain, param: "\(blockheight)") {
                                                                            
                                                                            self.saveWallet(wallet: newWallet, completion: completion)
                                                                            
                                                                        }
                                                                        
                                                                    } else if error != nil {
                                                                        
                                                                        // incase user inputs both the words and recoveryQR we revert to partial recovery
                                                                        if error!.contains("already exists") {
                                                                            
                                                                            self.recoverPartialMultiSigQR(node: node, json: json) { (success, errorDescription) in
                                                                                
                                                                                if success {
                                                                                    
                                                                                    completion((true, nil))
                                                                                    
                                                                                } else {
                                                                                    
                                                                                    completion((false, errorDescription!))
                                                                                    
                                                                                }
                                                                                
                                                                            }
                                                                            
                                                                        } else {
                                                                            
                                                                            completion((false, error!))
                                                                            
                                                                        }
                                                                                                                                                
                                                                    } else {
                                                                        
                                                                        completion((false, "error creating wallet: unknown error"))
                                                                        
                                                                    }
                                                                    
                                                                }
                                                                
                                                            } else {
                                                                
                                                                completion((false, "failed encrypting seed"))
                                                                
                                                            }
                                                            
                                                        }
                                                        
                                                    } else {
                                                        
                                                        completion((false, "failed deriving mnemonic from entropy"))
                                                        
                                                    }
                                                    
                                                } else {
                                                    
                                                    completion((false, "failed deriving entropy"))
                                                    
                                                }
                                                
                                            } else {
                                                
                                                completion((false, "failed descriptor response from bitcoind"))
                                                
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((false, reducer.errorDescription))
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                completion((false, "failed deriving HDKey"))
                                
                            }
                            
                        } else {
                            
                            completion((false, "failed fetching xprv"))
                            
                        }
                        
                    } catch {
                        
                        completion((false, "failed deriving account"))
                        
                    }
                    
                } else {
                    
                    completion((false, "error converting derivation to path"))
                    
                }
                
            }
            
        } else {
            
            completion((false, "error converting words to mnemonic"))
            
        }
        
    }
    
    private func recoverWordsOnly(node: NodeStruct, derivation: String, words: String, completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        if let _ = BIP32Path(derivation) {
                        
            if let _ = BIP39Mnemonic(words) {
                
                var newWallet = [String:Any]()
                newWallet["derivation"] = derivation
                newWallet["type"] = "DEFAULT"
                newWallet["birthdate"] = keyBirthday()
                newWallet["id"] = UUID()
                newWallet["isActive"] = false
                newWallet["lastUsed"] = Date()
                newWallet["lastBalance"] = 0.0
                newWallet["isArchived"] = false
                newWallet["nodeId"] = node.id
                newWallet["blockheight"] = 1// user is only importing words, so we need to do a full rescan when recovering
                newWallet["maxRange"] = 2500
                
                let enc = Encryption.sharedInstance
                enc.encryptData(dataToEncrypt: words.dataUsingUTF8StringEncoding) { (encryptedData, error) in
                    
                    if !error && encryptedData != nil {
                        
                        newWallet["seed"] = encryptedData!
                        
                        let keyFetcher = KeyFetcher()
                        let w = WalletStruct(dictionary: newWallet)
                        keyFetcher.xpub(wallet: w) { (xpub, error) in
                            
                            if !error {
                                
                                keyFetcher.fingerprint(wallet: w) { (fingerprint, error) in
                                    
                                    if !error && fingerprint != nil {
                                        
                                        var param = ""
                                        
                                        switch w.derivation {
                                            
                                        case "m/84'/1'/0'":
                                            param = "\"wpkh([\(fingerprint!)/84'/1'/0']\(xpub!)/0/*)\""
                                            
                                        case "m/84'/0'/0'":
                                            param = "\"wpkh([\(fingerprint!)/84'/0'/0']\(xpub!)/0/*)\""
                                            
                                        case "m/44'/1'/0'":
                                            param = "\"pkh([\(fingerprint!)/44'/1'/0']\(xpub!)/0/*)\""
                                             
                                        case "m/44'/0'/0'":
                                            param = "\"pkh([\(fingerprint!)/44'/0'/0']\(xpub!)/0/*)\""
                                            
                                        case "m/49'/1'/0'":
                                            param = "\"sh(wpkh([\(fingerprint!)/49'/1'/0']\(xpub!)/0/*))\""
                                            
                                        case "m/49'/0'/0'":
                                            param = "\"sh(wpkh([\(fingerprint!)/49'/0'/0']\(xpub!)/0/*))\""
                                            
                                        default:
                                            
                                            break
                                            
                                        }
                                        
                                        let reducer = Reducer()
                                        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) {
                                            
                                            if !reducer.errorBool {
                                                
                                                if let dict = reducer.dictToReturn {
                                                    
                                                    let primaryDescriptor = dict["descriptor"] as! String
                                                    newWallet["descriptor"] = primaryDescriptor
                                                    let digest = SHA256.hash(data: primaryDescriptor.dataUsingUTF8StringEncoding)
                                                    let stringHash = digest.map { String(format: "%02hhx", $0) }.joined()
                                                    newWallet["name"] = stringHash
                                                    
                                                    switch w.derivation {
                                                        
                                                    case "m/84'/1'/0'":
                                                        param = "\"wpkh([\(fingerprint!)/84'/1'/0']\(xpub!)/1/*)\""
                                                        
                                                    case "m/84'/0'/0'":
                                                        param = "\"wpkh([\(fingerprint!)/84'/0'/0']\(xpub!)/1/*)\""
                                                        
                                                    case "m/44'/1'/0'":
                                                        param = "\"pkh([\(fingerprint!)/44'/1'/0']\(xpub!)/1/*)\""
                                                         
                                                    case "m/44'/0'/0'":
                                                        param = "\"pkh([\(fingerprint!)/44'/0'/0']\(xpub!)/1/*)\""
                                                        
                                                    case "m/49'/1'/0'":
                                                        param = "\"sh(wpkh([\(fingerprint!)/49'/1'/0']\(xpub!)/1/*))\""
                                                        
                                                    case "m/49'/0'/0'":
                                                        param = "\"sh(wpkh([\(fingerprint!)/49'/0'/0']\(xpub!)/1/*))\""
                                                        
                                                    default:
                                                        
                                                        break
                                                        
                                                    }
                                                    
                                                    reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) {
                                                        
                                                        if !reducer.errorBool {
                                                            
                                                            if let dict = reducer.dictToReturn {
                                                                
                                                                let changeDescriptor = dict["descriptor"] as! String
                                                                newWallet["changeDescriptor"] = changeDescriptor
                                                                
                                                                let walletCreator = WalletCreator()
                                                                walletCreator.walletDict = newWallet
                                                                walletCreator.createStandUpWallet { (success, errorDescription) in
                                                                    
                                                                    if success {
                                                                                                                                                
                                                                        reducer.makeCommand(walletName: (newWallet["name"] as! String), command: .rescanblockchain, param: "1") {
                                                                            
                                                                            self.saveWallet(wallet: newWallet, completion: completion)
                                                                            
                                                                        }
                                                                        
                                                                    } else {
                                                                        
                                                                        if errorDescription != nil {
                                                                            
                                                                            if errorDescription!.contains("already exists") {
                                                                                
                                                                                self.saveWallet(wallet: newWallet, completion: completion)
                                                                                
                                                                            } else {
                                                                                
                                                                                completion((false, errorDescription))
                                                                                
                                                                            }
                                                                            
                                                                        } else {
                                                                            
                                                                            completion((false, "unknown error"))
                                                                            
                                                                        }
                                                                        
                                                                    }
                                                                    
                                                                }
                                                                
                                                            }
                                                            
                                                        } else {
                                                            
                                                            completion((false, reducer.errorDescription))
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                }
                                                
                                            } else {
                                                
                                                completion((false, reducer.errorDescription))
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                completion((false, "error getting xpub"))
                                
                            }
                            
                        }
                        
                    } else {
                        
                        completion((false, "error encrypting your mnemonic"))
                        
                    }
                    
                }
                
            } else {
                
                completion((false, "error converting those words to a valid mnemonic"))
                
            }
            
        } else {
            
            completion((false, "error converting derivation path"))
            
        }
        
    }
    
    func recover(node: NodeStruct, json: [String:Any]?, words: String?, derivation: String?, completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        if json != nil {
            
            let type = self.recoveryType(json: json!, words: words)
            
            switch type {
                
            case .fullMultiSig:
                print("full multisig recovery")
                fullMultiSigRecovery(node: node, json: json!, words: words!, completion: completion)
            
            case .partialMultiSig:
                print("partial multisig recovery")
                recoverPartialMultiSigQR(node: node, json: json!, completion: completion)
                
            case .singleSig:
                print("single sig recovery")
                recoverSingleSigQR(node: node, json: json!, completion: completion)
                
            case .unknown:
                print("unknown")
                
            }
        
        } else {
            
            // we know its just words, so it is single signature
            print("single sig recovery")
            recoverWordsOnly(node: node, derivation: derivation!, words: words!, completion: completion)
            
        }
        
    }
    
    private func multiSigChangeDescriptor(primary: String, xpub: String, descStruct: DescriptorStruct) -> String {
        
        var changeDesc = primary.replacingOccurrences(of: "\(xpub)/0/*", with: "\(xpub)/1/*")
        changeDesc = changeDesc.replacingOccurrences(of: "\(descStruct.multiSigKeys[0])/0/*", with: "\(descStruct.multiSigKeys[0])/1/*")
        changeDesc = changeDesc.replacingOccurrences(of: "\(descStruct.multiSigKeys[2])/0/*", with: "\(descStruct.multiSigKeys[2])/1/*")
        let arr = changeDesc.split(separator: "#")
        return "\(arr[0])"
        
    }
    
    private func saveWallet(wallet: [String:Any], completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        let walletSaver = WalletSaver()
        walletSaver.save(walletToSave: wallet) { (success) in
            
            if success {
                
                completion((true, nil))
                
            } else {
                
                completion((false, "error saving wallet"))
                
            }
            
        }
        
    }
    
}
