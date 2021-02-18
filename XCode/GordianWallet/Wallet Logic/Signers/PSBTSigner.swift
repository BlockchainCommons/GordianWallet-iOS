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
        
        var seedsToSignWith = [Data]()
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
                                    psbtToSign = try PSBT(psbt: processedPsbt, network: chain)
                                    attemptToSignLocallyWithActiveWalletXprv()
                                } catch {
                                    attemptToSignLocallyWithActiveWalletXprv()
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
        
        func attemptToSignLocallyWithActiveWalletXprv() {
            getActiveWalletNow { (wallet, error) in
                
                guard let wallet = wallet, let xprvs = wallet.xprvs, xprvs.count > 0 else {
                    finalizeWithBitcoind()
                    return
                }
                
                let encryptedXprvs = xprvs
                var signableKeys = [String]()
                
                for (x, encryptedXprv) in encryptedXprvs.enumerated() {
                    
                    Encryption.decryptData(dataToDecrypt: encryptedXprv) { (decryptedXprv) in
                        if decryptedXprv != nil {
                            if let xprv = String(bytes: decryptedXprv!, encoding: .utf8) {
                                if let key = try? HDKey(base58: xprv) {
                                    let inputs = psbtToSign.inputs
                                    for (i, input) in inputs.enumerated() {
                                        /// Create an array of child keys that we know can sign our inputs.
                                        if let origins = input.origins {
                                            for origin in origins {
                                                if let path = try? BIP32Path(string: (origin.value.path.description).replacingOccurrences(of: wallet.derivation + "/", with: "")) {
                                                    if let childKey = try? key.derive(using: path) {
                                                        if let privKey = childKey.privKey {
                                                            if privKey.pubKey == origin.key {
                                                                signableKeys.append(privKey.wif)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        if i + 1 == inputs.count && x + 1 == encryptedXprvs.count {
                                            let uniqueSigners = Array(Set(signableKeys))
                                            if uniqueSigners.count > 0 {
                                                for (w, wif) in uniqueSigners.enumerated() {
                                                    if let key = try? Key(wif: wif, network: chain) {
                                                        psbtToSign = try? psbtToSign.signed(with: key)
                                                    }
                                                    if w + 1 == uniqueSigners.count {
                                                        finalizeWithBitcoind()
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
                        psbtToSign = try PSBT(psbt: psbt, network: chain)
                        processWithActiveWallet()
                    } catch {
                        completion((false, nil, nil))
                    }
                }
            }
        }
        getChain()
    }
    
}
