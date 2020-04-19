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
        
        func finalizePsbt() {
            if psbtToSign.finalize() {
                if let hex = psbtToSign.transactionFinal?.description {
                    completion((true, nil, hex))
                } else {
                    completion((true, psbtToSign.description, nil))
                }
            }
        }
        
        func attemptToSign() {
            if xprvsToSignWith.count > 0 {
                for (i, key) in xprvsToSignWith.enumerated() {
                    psbtToSign.sign(key)
                    if i + 1 == xprvsToSignWith.count {
                        finalizePsbt()
                    }
                }
            }
        }
        
        /// Fetch keys to sign with
        func getKeysToSignWith() {
            for (i, wallet) in walletsToSignWith.enumerated() {
                let w = WalletStruct(dictionary: wallet)
                let encryptedSeed = w.seed
                if String(bytes: encryptedSeed, encoding: .utf8) != "no seed" {
                    Encryption.decryptData(dataToDecrypt: encryptedSeed) { (seed) in
                        if seed != nil {
                            if let words = String(data: seed!, encoding: .utf8) {
                                let mnenomicCreator = MnemonicCreator()
                                mnenomicCreator.convert(words: words) { (mnemonic, error) in
                                    if !error {
                                        if let masterKey = HDKey(mnemonic!.seedHex(""), network(path: w.derivation)) {
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
                    attemptToSign()
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
                            let walletNetwork = network(path: wallet.derivation)
                            if !wallet.isArchived && walletNetwork == psbtToSign.network {
                                walletsToSignWith.append(w)
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
                    var chain:Network!
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
        
        //        let cd = CoreDataService()
        //        cd.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
        //            if errorDescription == nil && wallets != nil {
        //                for w in wallets! {
        //                    let wallet = WalletStruct(dictionary: w)
        //                    let chain = network(path: wallet.derivation)
        //                    print("chain = \(chain)")
        //                    do {
        //                        var localPSBT = try PSBT(psbt, chain)
        //                        let inputs = localPSBT.inputs
        //                        print("inputs.count = \(inputs.count)")
        //                        for input in inputs {
        //                            let origins = input.origins
        //                            for origin in origins! {
        //                                var path = origin.value.path
        //                                print("path = \(path)")
        //                                let s = (path.description).replacingOccurrences(of: "m/", with: "")
        //                                path = BIP32Path(s)!
        //                                print("path2 = \(path)")
        //                                let encryptedSeed = wallet.seed
        //                                if String(bytes: encryptedSeed, encoding: .utf8) != "no seed" {
        //                                    let enc = Encryption()
        //                                    Encryption.decryptData(dataToDecrypt: encryptedSeed) { (seed) in
        //                                        if seed != nil {
        //                                            if let words = String(data: seed!, encoding: .utf8) {
        //                                                let mnenomicCreator = MnemonicCreator()
        //                                                mnenomicCreator.convert(words: words) { (mnemonic, error) in
        //                                                    if !error {
        //                                                        if let masterKey = HDKey(mnemonic!.seedHex(""), network(path: wallet.derivation)) {
        //                                                            if let walletPath = BIP32Path(wallet.derivation) {
        //                                                                do {
        //                                                                    let account = try masterKey.derive(walletPath)
        //                                                                    print("account xpub = \(account.xpub)")
        //
        //                                                                    do {
        //                                                                        let key = try account.derive(path)
        //                                                                        //if input.canSign(account) {
        //                                                                            if let privkey = key.privKey {
        //                                                                                print("privkey = \(privkey.wif)")
        //                                                                                let mk = masterKey.xpriv!
        //                                                                                let hdkey = HDKey(mk)
        //                                                                                localPSBT.sign(hdkey!)
        //                                                                                print("psbt signed")
        //                                                                                let final = localPSBT.finalize()
        //                                                                                let complete = localPSBT.complete
        //
        //                                                                                if final {
        //
        //                                                                                    if complete {
        //
        //                                                                                        if let hex = localPSBT.transactionFinal?.description {
        //
        //                                                                                            print("complete: \(hex)")
        //
        //                                                                                        } else {
        //
        //                                                                                            print("incomplete")
        //
        //                                                                                        }
        //
        //                                                                                    }
        //
        //                                                                                }
        //
        //                                                                            }
        ////                                                                        } else {
        ////                                                                            print("can't sign with that key")
        ////                                                                        }
        //                                                                    } catch {
        //                                                                        print("error deriving key")
        //                                                                    }
        //                                                                } catch {
        //                                                                    print("error deriving account")
        //                                                                }
        //                                                            }
        //
        //                                                        }
        //                                                    }
        //                                                }
        //                                            }
        //                                        }
        //                                    }
        //                                }
        //                            }
        //                        }
        //                    } catch {
        //
        //
        //                    }
        //
        //                }
        //
        //            }
        //
        //        }
        
        
        
    }
    
    
    
}
