//
//  SingleSigBuilder.swift
//  StandUp-Remote
//
//  Created by Peter on 30/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class SingleSigBuilder {

    class func build(outputs: [Any], completion: @escaping ((signedTx: String?, unsignedPsbt: String?, errorDescription: String?)) -> Void) {

        getActiveWalletNow { (w, error) in

            if w != nil && !error {

                let feeTarget = UserDefaults.standard.object(forKey: "feeTarget") as? Int ?? 432
                var outputsString = outputs.description
                outputsString = outputsString.replacingOccurrences(of: "[", with: "")
                outputsString = outputsString.replacingOccurrences(of: "]", with: "")
                var changeType = ""
                let parser = DescriptorParser()
                let str = parser.descriptor(w!.descriptor)

                if str.isP2WPKH || str.isBIP84 {

                    changeType = "bech32"

                } else if str.isP2SHP2WPKH || str.isBIP49 {

                    changeType = "p2sh-segwit"

                } else if str.isP2PKH || str.isBIP44 {

                    changeType = "legacy"

                }

                let param = "''[]'', ''{\(outputsString)}'', 0, ''{\"includeWatching\": true, \"replaceable\": true, \"conf_target\": \(feeTarget), \"change_type\": \"\(changeType)\"}'', true"

                Reducer.makeCommand(walletName: w!.name!, command: .walletcreatefundedpsbt, param: param) { (object, errorDesc) in

                    if let psbtDict = object as? NSDictionary {

                        if let psbt = psbtDict["psbt"] as? String {

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

                        } else {

                            completion((nil, nil, "Error creating psbt"))

                        }

                    } else {

                        completion((nil, nil, "Error creating psbt: \(errorDesc ?? "")"))

                    }

                }

            }

        }

    }

}
