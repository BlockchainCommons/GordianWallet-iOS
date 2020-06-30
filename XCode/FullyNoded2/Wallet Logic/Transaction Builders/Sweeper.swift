//
//  Sweeper.swift
//  FullyNoded2
//
//  Created by Peter on 17/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class Sweeper {
    
    class func sweepTo(receivingAddress: String, completion: @escaping ((psbt: String?, errorDesc: String?)) -> Void) {
        var walletName:String!
        
        func parsePsbtDict(dict: NSDictionary) {
            if let psbt = dict["psbt"] as? String {
                completion((psbt, nil))
            } else {
                completion((nil, "Error parsing the psbt dictionary."))
            }
        }
        
        func createPsbt(params: String) {
            Reducer.makeCommand(walletName: walletName, command: .walletcreatefundedpsbt, param: params) { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    parsePsbtDict(dict: dict)
                } else {
                    completion((nil, errorDescription))
                }
            }
        }
        
        func parseUtxos(utxos: NSArray) {
            var inputArray = [Any]()
            var amount = Double()
            var spendFromCold = Bool()
            for utxo in utxos {
                let utxoDict = utxo as! NSDictionary
                let txid = utxoDict["txid"] as! String
                let vout = "\(utxoDict["vout"] as! Int)"
                let spendable = utxoDict["spendable"] as! Bool
                if !spendable {
                    spendFromCold = true
                }
                amount += utxoDict["amount"] as! Double
                let input = "{\"txid\":\"\(txid)\",\"vout\": \(vout),\"sequence\": 1}"
                inputArray.append(input)
            }
            let processedInputs = processInputs(inputArray)
            let ud = UserDefaults.standard
            let feeTarget = ud.object(forKey: "feeTarget") as! Int
            let param = "''\(processedInputs)'', ''{\"\(receivingAddress)\":\(rounded(number: amount))}'', 0, ''{\"includeWatching\": \(spendFromCold), \"replaceable\": true, \"conf_target\": \(feeTarget), \"subtractFeeFromOutputs\": [0], \"changeAddress\": \"\(receivingAddress)\"}'', true"
            createPsbt(params: param)
        }
        
        func listUnspent() {
            Reducer.makeCommand(walletName: walletName, command: .listunspent, param: "0") { (object, errorDescription) in
                if let utxos = object as? NSArray {
                    if utxos.count > 0 {
                        parseUtxos(utxos: utxos)
                    } else {
                        completion((nil, "No available utxo's"))
                    }
                } else {
                    completion((nil, errorDescription))
                }
            }
        }
        
        getActiveWalletNow { (wallet, error) in
            if wallet != nil {
                if wallet!.name != nil {
                    walletName = wallet!.name!
                    listUnspent()
                }
            }
        }
    }
    
    class func processInputs(_ inputArray: [Any]) -> String {
        var inputs = inputArray.description
        inputs = inputs.replacingOccurrences(of: "[\"", with: "[")
        inputs = inputs.replacingOccurrences(of: "\"]", with: "]")
        inputs = inputs.replacingOccurrences(of: "\"{", with: "{")
        inputs = inputs.replacingOccurrences(of: "}\"", with: "}")
        return inputs.replacingOccurrences(of: "\\", with: "")
    }
    
}
