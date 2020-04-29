//
//  PSBTSigner.swift
//  FullyNoded2
//
//  Created by Peter on 19/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import LibWally

class PSBTSigner {
    
    class func sign(psbt: String, completion: @escaping ((success: Bool, psbt: String?, rawTx: String?)) -> Void) {
        
        var walletsToSignWith = [[String:Any]]()
        var xprvsToSignWith = [HDKey]()
        var psbtToSign:PSBT!
        var chain:Network!
        
        func finalizeWithBitcoind() {
            Reducer.makeCommand(walletName: "", command: .finalizepsbt, param: "\"\(psbtToSign.description)\"") { (object, errorDescription) in
                if let result = object as? NSDictionary {
                    if let complete = result["complete"] as? Bool {
                        if complete {
                            let hex = result["hex"] as! String
                            completion((true, nil, hex))
                        } else {
                            print("fail finalize 0")
                            let psbt = result["psbt"] as! String
                            completion((true, psbt, nil))
                        }
                    } else {
                        print("fail finalize 1")
                        completion((false, psbtToSign.description, nil))
                    }
                } else {
                    print("fail finalize 2")
                    completion((false, psbtToSign.description, nil))
                }
            }
        }
        
        func processWithActiveWallet() {
            print("processWithActiveWallet")
            getActiveWalletNow { (w, error) in
                if w != nil {
                    Reducer.makeCommand(walletName: w!.name ?? "", command: .walletprocesspsbt, param: "\"\(psbtToSign.description)\", true, \"ALL\", true") { (object, errorDescription) in
                        if let dict = object as? NSDictionary {
                            if let processedPsbt = dict["psbt"] as? String {
                                do {
                                    psbtToSign = try PSBT(processedPsbt, chain)
                                    attemptToSignLocally()
                                } catch {
                                    print("catch processWithActiveWallet")
                                    attemptToSignLocally()
                                }
                            }
                        } else {
                            print("failed catch processWithActiveWallet")
                            completion((false, psbtToSign.description, nil))
                        }
                    }
                } else {
                    print("failed2 catch processWithActiveWallet")
                    completion((false, psbtToSign.description, nil))
                }
            }
        }
        
        /// There is a bug in LibWally-Swift so until that gets fixed we rely on bitcoind to finalize PSBT's for us
        
//        func finalizePsbtLocally() {
//            if psbtToSign.finalize() {
//                if let hex = psbtToSign.transactionFinal?.description {
//                    completion((true, nil, hex))
//                } else {
//                    //processWithActiveWallet()
//                    completion((true, psbtToSign.description, nil))
//                }
//            }
//        }
        
        
        
        func attemptToSignLocally() {
            print("attemptToSignLocally")
            
            /// Need to ensure similiar seeds do not sign mutliple times. This can happen if a user utilizes the same seed for
            /// a multisig wallet and a single sig wallet.
            var xprvStrings = [String]()
            
            for xprv in xprvsToSignWith {
                xprvStrings.append(xprv.description)
                
            }
            
            xprvsToSignWith.removeAll()
            let uniqueXprvs = Array(Set(xprvStrings))
            
            for uniqueXprv in uniqueXprvs {
                
                if let xprv = HDKey(uniqueXprv) {
                    xprvsToSignWith.append(xprv)
                    
                }
            }
            
            if xprvsToSignWith.count > 0 {
                for (i, key) in xprvsToSignWith.enumerated() {
                    print("sign")
                    psbtToSign.sign(key)
                    if i + 1 == xprvsToSignWith.count {
                        /// There is a bug in LibWally-Swift so until that gets fixed we rely on bitcoind to finalize PSBT's for us
                        //finalizePsbtLocally()
                        finalizeWithBitcoind()
                    }
                }
            }
        }
        
        /// Fetch keys to sign with
        func getKeysToSignWith() {
            xprvsToSignWith.removeAll()
            for (i, wallet) in walletsToSignWith.enumerated() {
                let w = WalletStruct(dictionary: wallet)
                let encryptedSeed = w.seed
                if String(bytes: encryptedSeed, encoding: .utf8) != "no seed" {
                    Encryption.decryptData(dataToDecrypt: encryptedSeed) { (seed) in
                        if seed != nil {
                            if let words = String(data: seed!, encoding: .utf8) {
                                MnemonicCreator.convert(words: words) { (mnemonic, error) in
                                    if !error {
                                        if let masterKey = HDKey(mnemonic!.seedHex(""), chain) {
                                            if let xprv = masterKey.xpriv {
                                                if let hdkey = HDKey(xprv) {
                                                    xprvsToSignWith.append(hdkey)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if i + 1 == walletsToSignWith.count {
                    print("processWithActiveWallet")
                    processWithActiveWallet()
                }
            }
        }
        
        /// Fetch wallets on the same network
        func getSeeds() {
            CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                if errorDescription == nil && wallets != nil {
                    for (i, w) in wallets!.enumerated() {
                        if w["id"] != nil && w["name"] != nil && w["isArchived"] != nil {
                            let wallet = WalletStruct(dictionary: w)
                            let walletNetwork = network(descriptor: wallet.descriptor)
                            if !wallet.isArchived && walletNetwork == psbtToSign.network {
                                if String(data: wallet.seed, encoding: .utf8) != "no seed" || wallet.xprv != nil {
                                    walletsToSignWith.append(w)
                                }
                            }
                        }
                        if i + 1 == wallets!.count {
                            getKeysToSignWith()
                        }
                    }
                }
            }
        }
                
        /// Can only sign for one network so we get the active nodes network
        func getChain() {
            Encryption.getNode { (node, error) in
                if node != nil {
                    if node!.network == "testnet" {
                        chain = .testnet
                    } else {
                        chain = .mainnet
                    }
                    do {
                        psbtToSign = try PSBT(psbt, chain)
                        getSeeds()
                    } catch {
                        completion((false, nil, nil))
                        
                    }
                }
            }
        }
        
        getChain()
        
    }
    
}
