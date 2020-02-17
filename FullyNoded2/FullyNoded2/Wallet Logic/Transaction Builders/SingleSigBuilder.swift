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
    
    func build(outputs: [Any], completion: @escaping ((signedTx: String?, errorDescription: String?)) -> Void) {
        
        func signSegwitWrapped(psbt: String) {
         
            let signer = OfflineSignerP2SHSegwit()
            signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

                if signedTx != nil {

                    completion((signedTx!, nil))

                }

            }
            
        }
        
        func signLegacy(psbt: String) {
            
            let signer = OfflineSignerLegacy()
            signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

                if signedTx != nil {

                    completion((signedTx!, nil))

                }

            }
            
        }
        
        func signSegwit(psbt: String) {
            
            let signer = NativeSegwitOfflineSigner()
            signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

                if signedTx != nil {

                    completion((signedTx!, nil))

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
                                    
                                    completion((hex, nil))
                                    
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
                
                completion((nil, "Error: Local PSBT creation failed"))
                
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
                let index = Int((path.split(separator: "/"))[1])!
                let keyFetcher = KeyFetcher()
                keyFetcher.privKey(index: index) { (privKey, error) in
                    
                    if !error {
                        
                        privateKeys.append(privKey!)
                        
                        if i + 1 == inputs.count {
                            
                            signPsbt(psbt: psbt, privateKeys: privateKeys)
                            
                        }
                        
                    } else {
                        
                        completion((nil, "Error: Failed fetching private key at index \(index)"))
                        
                    }
                    
                }
                
            }
            
        }
        
        func decodePsbt(psbt: String) {
            
            let reducer = Reducer()
            let param = "\"\(psbt)\""
            reducer.makeCommand(walletName: wallet.name, command: .decodepsbt, param: param) {
                
                if !reducer.errorBool {
                    
                    let dict = reducer.dictToReturn
                    parsePsbt(decodePsbt: dict, psbt: psbt)
                    
                } else {
                    
                    completion((nil, "Error decoding transaction: \(reducer.errorDescription)"))
                    
                }
                
            }
            
        }
        
        func processPsbt(psbt: String) {
            
            let reducer = Reducer()
            let param = "\"\(psbt)\", true, \"ALL\", true"
            reducer.makeCommand(walletName: wallet.name, command: .walletprocesspsbt, param: param) {
                
                if !reducer.errorBool {
                    
                    let dict = reducer.dictToReturn
                    let processedPsbt = dict["psbt"] as! String
                    decodePsbt(psbt: processedPsbt)
                    
                } else {
                    
                    completion((nil, "Error decoding transaction: \(reducer.errorDescription)"))
                    
                }
                
            }
            
        }
        
        func createPsbt() {

            let reducer = Reducer()
            let feeTarget = UserDefaults.standard.object(forKey: "feeTarget") as? Int ?? 432
            var outputsString = outputs.description
            outputsString = outputsString.replacingOccurrences(of: "[", with: "")
            outputsString = outputsString.replacingOccurrences(of: "]", with: "")
            var changeType = ""
            
            switch wallet.derivation {
            case "m/84'/1'/0'/0", "m/84'/0'/0'/0":
                changeType = "bech32"
            case "m/44'/1'/0'/0", "m/44'/0'/0'/0":
                changeType = "legacy"
            case "m/49'/1'/0'/0", "m/49'/0'/0'/0":
                changeType = "p2sh-segwit"
            default:
                break
            }

            let param = "''[]'', ''{\(outputsString)}'', 0, ''{\"includeWatching\": true, \"replaceable\": true, \"conf_target\": \(feeTarget), \"change_type\": \"\(changeType)\"}'', true"

            reducer.makeCommand(walletName: wallet.name, command: .walletcreatefundedpsbt, param: param) {

                if !reducer.errorBool {

                    let psbtDict = reducer.dictToReturn
                    let psbt = psbtDict["psbt"] as! String
                    
                    if self.wallet.type == "DEFAULT" {
                        
                        switch self.wallet.derivation {
                        case "m/84'/1'/0'/0", "m/84'/0'/0'/0": signSegwit(psbt: psbt)
                        case "m/44'/1'/0'/0", "m/44'/0'/0'/0": signLegacy(psbt: psbt)
                        case "m/49'/1'/0'/0", "m/49'/0'/0'/0": signSegwitWrapped(psbt: psbt)
                        default:
                            break
                        }
                        
                    } else if self.wallet.type == "MULTI" {
                     
                        processPsbt(psbt: psbt)
                        
                    }
                    

                } else {

                    completion((nil, "Error creating psbt: \(reducer.errorDescription)"))

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
