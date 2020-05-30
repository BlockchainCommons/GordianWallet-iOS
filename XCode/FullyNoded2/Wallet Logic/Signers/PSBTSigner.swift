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
        
        var seedsToSignWith = [[String:Any]]()
        var xprvsToSignWith = [HDKey]()
        var psbtToSign:PSBT!
        var chain:Network!
        
        func reset() {
            seedsToSignWith.removeAll()
            xprvsToSignWith.removeAll()
            psbtToSign = nil
            chain = nil
        }
        
        func finalizeWithBitcoind() {
            Reducer.makeCommand(walletName: "", command: .finalizepsbt, param: "\"\(psbtToSign.description)\"") { (object, errorDescription) in
                if let result = object as? NSDictionary {
                    if let complete = result["complete"] as? Bool {
                        if complete {
                            let hex = result["hex"] as! String
                            reset()
                            completion((true, nil, hex))
                        } else {
                            let psbt = result["psbt"] as! String
                            reset()
                            completion((true, psbt, nil))
                        }
                    } else {
                        reset()
                        completion((false, psbtToSign.description, nil))
                    }
                } else {
                    reset()
                    completion((false, psbtToSign.description, nil))
                }
            }
        }
        
        func processWithActiveWallet() {
            getActiveWalletNow { (w, error) in
                if w != nil {
                    Reducer.makeCommand(walletName: w!.name ?? "", command: .walletprocesspsbt, param: "\"\(psbtToSign.description)\", true, \"ALL\", true") { (object, errorDescription) in
                        if let dict = object as? NSDictionary {
                            if let processedPsbt = dict["psbt"] as? String {
                                do {
                                    psbtToSign = try PSBT(processedPsbt, chain)
                                    if xprvsToSignWith.count > 0 {
                                       attemptToSignLocally()
                                    } else {
                                        finalizeWithBitcoind()
                                    }
                                } catch {
                                    if xprvsToSignWith.count > 0 {
                                       attemptToSignLocally()
                                    } else {
                                        finalizeWithBitcoind()
                                    }
                                }
                            }
                        } else {
                            reset()
                            completion((false, nil, nil))
                        }
                    }
                } else {
                    reset()
                    completion((false, nil, nil))
                }
            }
        }
        
        func attemptToSignLocally() {
            /// Need to ensure similiar seeds do not sign mutliple times. This can happen if a user adds the same seed multiple times.
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
                    psbtToSign.sign(key)
                    if i + 1 == xprvsToSignWith.count {
                        /// There is a bug in LibWally-Swift so until that gets fixed we rely on bitcoind to finalize PSBT's for us
                        finalizeWithBitcoind()
                    }
                }
            }
        }
        
        /// Fetch keys to sign with
        func getKeysToSignWith() {
            xprvsToSignWith.removeAll()
            for (i, seed) in seedsToSignWith.enumerated() {
                let seedStruct = SeedStruct(dictionary: seed)
                if seedStruct.seed != nil {
                    Encryption.decryptData(dataToDecrypt: seedStruct.seed!) { (seed) in
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
                if i + 1 == seedsToSignWith.count {
                    processWithActiveWallet()
                }
            }
        }
        
        /// Fetch wallets on the same network
        func getSeeds() {
            seedsToSignWith.removeAll()
            CoreDataService.retrieveEntity(entityName: .seeds) { (seeds, errorDescription) in
                if errorDescription == nil && seeds != nil {
                    if seeds!.count > 0 {
                        for (i, seed) in seeds!.enumerated() {
                            seedsToSignWith.append(seed)
                            if i + 1 == seeds!.count {
                                getKeysToSignWith()
                            }
                        }
                    } else {
                        processWithActiveWallet()
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
