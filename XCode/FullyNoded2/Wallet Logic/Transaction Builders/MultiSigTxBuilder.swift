//
//  MultiSigTxBuilder.swift
//  StandUp-Remote
//
//  Created by Peter on 20/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class MultiSigTxBuilder {

    class func build(outputs: [Any], completion: @escaping ((signedTx: String?, unsignedPsbt: String?, errorDescription: String?)) -> Void) {

        getActiveWalletNow { (wallet, error) in

            if wallet != nil && !error {

                func signPsbt(psbt: String) {
                    
                    PSBTSigner.sign(psbt: psbt) { (success, incompletePsbt, rawTx) in

                        if success {

                            if incompletePsbt != nil {

                                completion((nil, incompletePsbt!, nil))

                            } else if rawTx != nil {

                                completion((rawTx!, nil, nil))

                            }

                        } else {

                            completion((nil, nil, "Error signing psbt"))

                        }

                    }

                }

                func createPsbt(changeAddress: String) {

                    let feeTarget = UserDefaults.standard.object(forKey: "feeTarget") as? Int ?? 432
                    var outputsString = outputs.description
                    outputsString = outputsString.replacingOccurrences(of: "[", with: "")
                    outputsString = outputsString.replacingOccurrences(of: "]", with: "")

                    let param = "''[]'', ''{\(outputsString)}'', 0, ''{\"includeWatching\": true, \"replaceable\": true, \"conf_target\": \(feeTarget), \"changeAddress\": \"\(changeAddress)\"}'', false"

                    Reducer.makeCommand(walletName: wallet!.name!, command: .walletcreatefundedpsbt, param: param) { (object, errorDesc) in
                        
                        if errorDesc != nil {
                            
                            completion((nil, nil, "error creating psbt: \(errorDesc!)"))
                            
                        } else if let psbtDict = object as? NSDictionary {

                            if let psbt = psbtDict["psbt"] as? String {

                                signPsbt(psbt: psbt)

                            } else {

                                completion((nil, nil, "error creating psbt"))

                            }

                        } else {

                            completion((nil, nil, "error creating psbt"))

                        }

                    }

                }

                func getChangeAddress() {

                    KeyFetcher.musigChangeAddress { (address, error, errorDescription) in

                        if !error {

                            createPsbt(changeAddress: address!)

                        } else {

                            completion((nil, nil, errorDescription ?? "error getting change address"))

                        }

                    }

                }

                getChangeAddress()

            } else {
                completion((nil, nil, "Error getting active wallet"))
                
            }

        }

    }

}
