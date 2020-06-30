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
                        completion((false, nil, errorDescription))
                    }
                } else {
                    reset()
                    completion((false, nil, errorDescription))
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
                var signableKeys = [String]()
                for (i, key) in xprvsToSignWith.enumerated() {
                    let inputs = psbtToSign.inputs
                    for (x, input) in inputs.enumerated() {
                        /// Create an array of child keys that we know can sign our inputs.
                        if let origins: [PubKey : KeyOrigin] = input.canSign(key) {
                            for origin in origins {
                                if let childKey = try? key.derive(origin.value.path) {
                                    if let privKey = childKey.privKey {
                                        precondition(privKey.pubKey == origin.key)
                                        signableKeys.append(privKey.wif)
                                    }
                                }
                            }
                        }
                        /// Once the above loops complete we remove an duplicate signing keys from the array then sign the psbt with each unique key.
                        if i + 1 == xprvsToSignWith.count && x + 1 == inputs.count {
                            let uniqueSigners = Array(Set(signableKeys))
                            if uniqueSigners.count > 0 {
                                for (s, signer) in uniqueSigners.enumerated() {
                                    if let signingKey = Key(signer, chain) {
                                        psbtToSign.sign(signingKey)
                                        /// Once we completed the signing loop we finalize with our node.
                                        if s + 1 == uniqueSigners.count {
                                            finalizeWithBitcoind()
                                        }
                                    }
                                }
                            } else {
                                finalizeWithBitcoind()
                            }
                        }
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
