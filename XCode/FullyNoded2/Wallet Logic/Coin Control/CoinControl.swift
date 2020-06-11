//
//  CoinControl.swift
//  FullyNoded2
//
//  Created by Peter on 10/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class CoinControl {
    
    class func lockUtxos(utxos: [[String:Any]], completion: @escaping ((Bool)) -> Void) {
        getActiveWalletNow { (wallet, error) in
            if wallet != nil {
                if utxos.count > 0 {
                    let param = "false, ''\(updateUtxos(utxos))''"
                    Reducer.makeCommand(walletName: wallet!.name!, command: .lockunspent, param: param) { (object, _) in
                        if let utxosLocked = object as? Bool {
                            if utxosLocked {
                                for (i, utxo) in utxos.enumerated() {
                                    let txid = utxo["txid"] as! String
                                    let vout = utxo["vout"] as! Int
                                    let confs = utxo["confirmations"] as! Int
                                    let amount = utxo["amount"] as! Double
                                    let desc = utxo["desc"] as! String
                                    let address = utxo["address"] as! String
                                    let label = utxo["label"] as? String ?? ""
                                    let ourDict = ["id":UUID(), "txid":txid, "vout":vout, "address":address, "amount":amount, "desc":desc, "confs":confs, "label":label] as [String : Any]
                                    CoreDataService.saveEntity(dict: ourDict, entityName: .lockedUtxos) { (success, _) in
                                        if !success {
                                            completion((false))
                                        }
                                        if i + 1 == utxos.count {
                                            completion((success))
                                        }
                                    }
                                }
                            } else {
                                completion((false))
                            }
                        } else {
                            completion((false))
                        }
                    }
                } else {
                    completion((false))
                }
            } else {
                completion(false)
            }
        }
    }
    
    class func unlockUtxos(utxos: [[String:Any]], completion: @escaping ((Bool)) -> Void) {
        getActiveWalletNow { (wallet, error) in
            if wallet != nil {
                let param = "true, ''\(updateUtxos(utxos))''"
                Reducer.makeCommand(walletName: wallet!.name!, command: .lockunspent, param: param) { (object, _) in
                    if let success = object as? Bool {
                        if success {
                            for utxo in utxos {
                                CoreDataService.retrieveEntity(entityName: .lockedUtxos) { (lockedUtxos, _) in
                                    if lockedUtxos != nil {
                                        if lockedUtxos!.count > 0 {
                                            for (i, lockedUtxo) in lockedUtxos!.enumerated() {
                                                let str = LockedUtxoStruct.init(dictionary: lockedUtxo)
                                                if (utxo["txid"] as! String) == str.txid && (utxo["vout"] as! Int) == str.vout {
                                                    CoreDataService.deleteEntity(id: str.id, entityName: .lockedUtxos) { _ in }
                                                }
                                                if i + 1 == lockedUtxos!.count {
                                                    completion(success)
                                                }
                                            }
                                        } else {
                                            completion(true)
                                        }
                                    } else {
                                        completion(true)
                                    }
                                }
                            }
                        } else {
                            completion(false)
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
    
    class func updateUtxos(_ utxosToEdit: [[String:Any]]) -> String {
           var utxos = [String]()
           var stringToReturn = ""
           for (i, utxoToEdit) in utxosToEdit.enumerated() {
               let txid = utxoToEdit["txid"] as! String
               let vout = utxoToEdit["vout"] as! Int
               let dict = "{\"txid\":\"\(txid)\",\"vout\":\(vout)}"
               utxos.append(dict)
               if i + 1 == utxosToEdit.count {
                   stringToReturn = process(utxos)
               }
           }
           return stringToReturn
       }
    
    class func process(_ utxos: [String]) -> String {
        var processedUtxos = (utxos.description).replacingOccurrences(of: "\"{", with: "{")
        processedUtxos = processedUtxos.replacingOccurrences(of: "}\"", with: "}")
        processedUtxos = processedUtxos.replacingOccurrences(of: "\"[", with: "[")
        processedUtxos = processedUtxos.replacingOccurrences(of: "]\"", with: "]")
        return processedUtxos.replacingOccurrences(of: "\\\"", with: "\"")
    }
}
