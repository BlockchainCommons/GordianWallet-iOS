//
//  SingleSigBuilder.swift
//  StandUp-Remote
//
//  Created by Peter on 30/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import LibWally

class SingleSigBuilder {
    
    var wallet:WalletStruct!
    
    func build(outputs: [Any], completion: @escaping ((signedTx: String?, unsignedPsbt: String?, errorDescription: String?)) -> Void) {
        
        func signSegwitWrapped(psbt: String) {
         
            let signer = OfflineSignerP2SHSegwit()
            signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

                if signedTx != nil {

                    completion((signedTx!, nil, nil))

                }

            }
            
        }
        
        func signLegacy(psbt: String) {
            
            let signer = OfflineSignerLegacy()
            signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

                if signedTx != nil {

                    completion((signedTx!, nil, nil))

                }

            }
            
        }
        
        func signSegwit(psbt: String) {
            
            let signer = NativeSegwitOfflineSigner()
            signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

                if signedTx != nil {

                    completion((signedTx!, nil, nil))

                }

            }
            
        }
        
        func fallbackToNormalSigning(psbt: String) {
            print("fallbackToNormalSigning")
            
            getActiveWalletNow { (wallet, error) in
                
                if wallet != nil && !error {
                    
                    if wallet!.derivation.contains("84") {

                        signSegwitWrapped(psbt: psbt)

                    } else if wallet!.derivation.contains("44") {

                        signLegacy(psbt: psbt)

                    } else if wallet!.derivation.contains("49") {

                        signSegwitWrapped(psbt: psbt)

                    }
                    
                }
                
            }
            
        }
        
        func signPsbt(psbt: String, privateKeys: [String]) {
            print("sign psbt")
            
            let chain = network(path: wallet.derivation)
            
            do {
                
                var localPSBT = try PSBT(psbt, chain)
                
                for (i, key) in privateKeys.enumerated() {
                    
                    let pk = Key(key, chain)
                    localPSBT.sign(pk!)
                    
                    if i + 1 == privateKeys.count {
                        
                        let final = localPSBT.finalize()
                        let complete = localPSBT.complete
                        
                        if final {
                            
                            if complete {
                                
                                if let hex = localPSBT.transactionFinal?.description {
                                    
                                    completion((hex, nil, nil))
                                    
                                } else {
                                    
                                    fallbackToNormalSigning(psbt: psbt)
                                    
                                }
                                
                            } else {
                                
                                fallbackToNormalSigning(psbt: psbt)
                                
                            }
                                                    
                        }
                        
                    }
                    
                }
                
            } catch {
                
                completion((nil, nil, "Error: Local PSBT creation failed"))
                
            }
            
        }
        
        func parsePsbt(decodePsbt: NSDictionary, psbt: String) {
            
            var privateKeys = [String]()
            let inputs = decodePsbt["inputs"] as! NSArray
            for (i, input) in inputs.enumerated() {
                
                let dict = input as! NSDictionary
                let bip32derivs = dict["bip32_derivs"] as! NSArray
                let bip32deriv = bip32derivs[0] as! NSDictionary
                let path = bip32deriv["path"] as! String
                if let bip32path = BIP32Path(path) {
                    
                    KeyFetcher.privKey(path: bip32path) { (privKey, error) in
                        
                        if !error {
                            
                            privateKeys.append(privKey!)
                            
                            if i + 1 == inputs.count {
                                
                                signPsbt(psbt: psbt, privateKeys: privateKeys)
                                
                            }
                            
                        } else {
                            
                            completion((nil, nil, "Error: Failed fetching private key at path \(bip32path)"))
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        func decodePsbt(psbt: String) {
            
            let param = "\"\(psbt)\""
            Reducer.makeCommand(walletName: wallet.name!, command: .decodepsbt, param: param) { (object, errorDesc) in
                
                if let dict = object as? NSDictionary {
                    
                    parsePsbt(decodePsbt: dict, psbt: psbt)
                    
                } else {
                    
                    completion((nil, nil, errorDesc))
                    
                }
                
            }
            
        }
        
        func processPsbt(psbt: String) {
            
            let param = "\"\(psbt)\", true, \"ALL\", true"
            Reducer.makeCommand(walletName: wallet.name!, command: .walletprocesspsbt, param: param) { (object, errorDesc) in
                
                if let dict = object as? NSDictionary {
                    
                    if let processedPsbt = dict["psbt"] as? String {
                        
                        decodePsbt(psbt: processedPsbt)
                        
                    } else {
                        
                        completion((nil, nil, "Error decoding transaction: \(errorDesc ?? "")"))
                        
                    }
                    
                } else {
                    
                    completion((nil, nil, "Error decoding transaction: \(errorDesc ?? "")"))
                    
                }
                
            }
            
        }
        
        func createPsbt() {

            let feeTarget = UserDefaults.standard.object(forKey: "feeTarget") as? Int ?? 432
            var outputsString = outputs.description
            outputsString = outputsString.replacingOccurrences(of: "[", with: "")
            outputsString = outputsString.replacingOccurrences(of: "]", with: "")
            var changeType = ""
            let parser = DescriptorParser()
            let str = parser.descriptor(wallet.descriptor)
            
            if str.isP2WPKH || str.isBIP84 {
                
                changeType = "bech32"
                
            } else if str.isP2SHP2WPKH || str.isBIP49 {
                
                changeType = "p2sh-segwit"
                
            } else if str.isP2PKH || str.isBIP44 {
                
                changeType = "legacy"
                
            }

            let param = "''[]'', ''{\(outputsString)}'', 0, ''{\"includeWatching\": true, \"replaceable\": true, \"conf_target\": \(feeTarget), \"change_type\": \"\(changeType)\"}'', true"

            Reducer.makeCommand(walletName: wallet.name!, command: .walletcreatefundedpsbt, param: param) { (object, errorDesc) in
                
                if let psbtDict = object as? NSDictionary {
                    
                    if let psbt = psbtDict["psbt"] as? String {
                        
                        if self.wallet.type == "DEFAULT" || self.wallet.type == "CUSTOM" {
                            
                            if str.isHot || String(data: self.wallet.seed, encoding: .utf8) != "no seed" || self.wallet.xprv != nil {
                                
                                if str.isP2WPKH || str.isBIP84 {
                                    
                                    signSegwit(psbt: psbt)
                                    
                                } else if str.isP2SHP2WPKH || str.isBIP49 {
                                    
                                    signSegwitWrapped(psbt: psbt)
                                    
                                } else if str.isP2PKH || str.isBIP44 {
                                    
                                    signLegacy(psbt: psbt)
                                    
                                }
                                
                            } else {
                                
                                completion((nil, psbt, nil))
                                
                            }
                            
                            
                        } else if self.wallet.type == "MULTI" {
                            
                            processPsbt(psbt: psbt)
                            
                        }
                        
                    } else {
                        
                        completion((nil, nil, "Error creating psbt"))
                        
                    }
                    
                } else {
                    
                    completion((nil, nil, "Error creating psbt: \(errorDesc ?? "")"))
                    
                }
                
            }

        }
        
        getActiveWalletNow { (w, error) in
            
            if w != nil && !error {
                
                self.wallet = w!
                createPsbt()
                
            }
            
        }
        
    }
    
}
