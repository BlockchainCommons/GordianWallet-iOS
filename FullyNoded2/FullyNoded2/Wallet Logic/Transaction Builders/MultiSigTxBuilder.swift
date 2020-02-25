//
//  MultiSigTxBuilder.swift
//  StandUp-Remote
//
//  Created by Peter on 20/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import LibWally

class MultiSigTxBuilder {
    
    func build(outputs: [Any], completion: @escaping ((signedTx: String?, unsignedPsbt: String?, errorDescription: String?)) -> Void) {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                func signPsbt(psbt: String, privateKeys: [String]) {
                    
                    do {
                        
                        let chain = network(path: wallet!.derivation)
                        
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
                                            
                                            completion((nil, nil, "Error: PSBT incomplete"))
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    } catch {
                        
                        completion((nil, nil, "Error creating local PSBT"))
                        
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
                        let keyFetcher = KeyFetcher()
                        if let bip32path = BIP32Path(path) {
                            
                            keyFetcher.privKey(path: bip32path) { (privKey, error) in
                                
                                if !error {
                                    
                                    privateKeys.append(privKey!)
                                    
                                    if i + 1 == inputs.count {
                                        
                                        signPsbt(psbt: psbt, privateKeys: privateKeys)
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil, nil, "Error fetching private key"))
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
                func decodePsbt(psbt: String) {
                    
                    let reducer = Reducer()
                    let param = "\"\(psbt)\""
                    reducer.makeCommand(walletName: wallet!.name, command: .decodepsbt, param: param) {
                        
                        if !reducer.errorBool {
                            
                            let dict = reducer.dictToReturn
                            parsePsbt(decodePsbt: dict, psbt: psbt)
                            
                        } else {
                            
                            completion((nil, nil, "Error decoding transaction: \(reducer.errorDescription)"))
                            
                        }
                        
                    }
                    
                }
                
                func processPsbt(psbt: String) {
                    
                    let reducer = Reducer()
                    let param = "\"\(psbt)\", true, \"ALL\", true"
                    reducer.makeCommand(walletName: wallet!.name, command: .walletprocesspsbt, param: param) {
                        
                        if !reducer.errorBool {
                            
                            let dict = reducer.dictToReturn
                            let procccessedPsbt = dict["psbt"] as! String
                            let descParser = DescriptorParser()
                            let descStr = descParser.descriptor(wallet!.descriptor)
                            
                            if descStr.isHot || String(data: wallet!.seed, encoding: .utf8) != "no seed" {
                                
                                decodePsbt(psbt: procccessedPsbt)
                                
                            } else {
                                
                                completion((nil, procccessedPsbt, nil))
                                
                            }
                            
                        } else {
                            
                            completion((nil, nil, "Error decoding transaction: \(reducer.errorDescription)"))
                            
                        }
                        
                    }
                    
                }
                
                func createPsbt(changeAddress: String) {
                    
                    let reducer = Reducer()
                    let feeTarget = UserDefaults.standard.object(forKey: "feeTarget") as? Int ?? 432
                    var outputsString = outputs.description
                    outputsString = outputsString.replacingOccurrences(of: "[", with: "")
                    outputsString = outputsString.replacingOccurrences(of: "]", with: "")
                    
                    let param = "''[]'', ''{\(outputsString)}'', 0, ''{\"includeWatching\": true, \"replaceable\": true, \"conf_target\": \(feeTarget), \"changeAddress\": \"\(changeAddress)\"}'', true"
                    
                    reducer.makeCommand(walletName: wallet!.name, command: .walletcreatefundedpsbt, param: param) {
                        
                        if !reducer.errorBool {
                            
                            let psbtDict = reducer.dictToReturn
                            let psbt = psbtDict["psbt"] as! String
                            processPsbt(psbt: psbt)
                            
                            
                        } else {
                            
                            completion((nil, nil, "error creating psbt: \(reducer.errorDescription)"))
                            
                        }
                        
                    }
                    
                }
                
                func getChangeAddress() {
                    
                    let keyFetcher = KeyFetcher()
                    
                    keyFetcher.musigChangeAddress { (address, error) in
                        
                        if !error {
                            
                            createPsbt(changeAddress: address!)
                            
                        } else {
                            
                            completion((nil, nil, "error getting change address"))
                            
                        }
                        
                    }
                    
                }
                
                getChangeAddress()
                
            }
            
        }
        
    }
    
}
