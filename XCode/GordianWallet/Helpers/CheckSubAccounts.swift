//
//  CheckSubAccounts.swift
//  GordianWallet
//
//  Created by Peter on 28/07/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class CheckSubAccounts {
    
    class func check(derivation: String, words: String, coinType: String, completion: @escaping (([[String:Any]]?)) -> Void) {
        
        let bip84 = "m/84'/\(coinType)'/0'/0/0"
        let bip44 = "m/44'/\(coinType)'/0'/0/0"
        let bip49 = "m/49'/\(coinType)'/0'/0/0"
        
        var derivsToScan:[[String:Any]] = []
        let derivations = [["derivation":bip84, "addresses":[], "hasHistory":false],  ["derivation":bip44, "addresses":[], "hasHistory":false], ["derivation": bip49, "addresses":[], "hasHistory":false]] as [[String:Any]]
        
        for deriv in derivations {
            if !(deriv["derivation"] as! String).contains(derivation) {
                derivsToScan.append(deriv)
            }
        }
        
        var addressesIndex = 0
        var balancesIndex = 0
        
        func fetchBalances(index: Int, addressIndex: Int) {
            if balancesIndex < derivsToScan.count {
                let addresses = derivsToScan[index]["addresses"] as! [String]
                if addressesIndex < addresses.count {
                    let shared = AddressScanner.sharedInstance
                    shared.scan(address: addresses[addressesIndex]) { (hasHistory) in
                        if hasHistory != nil {
                            if hasHistory! {
                                derivsToScan[index]["hasHistory"] = true
                                completion(derivsToScan)
                            } else {
                                addressesIndex += 1
                                if addressesIndex == addresses.count {
                                    balancesIndex += 1
                                }
                                fetchBalances(index: index, addressIndex: addressesIndex)
                            }
                        }
                    }
                } else {
                    addressesIndex = 0
                    fetchBalances(index: balancesIndex, addressIndex: addressesIndex)
                }
            } else {
                completion(derivsToScan)
            }
        }
        
        var fetchIndex = 0
        func fetchAddresses(index: Int) {
            if index < derivsToScan.count {
                KeyFetcher.fetchAddresses(words: words, derivation: (derivsToScan[index]["derivation"] as! String)) { (addresses) in
                    if addresses != nil {
                        derivsToScan[index]["addresses"] = addresses!
                        fetchIndex += 1
                        fetchAddresses(index: fetchIndex)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                fetchBalances(index: 0, addressIndex: 0)
            }
        }
        
        fetchAddresses(index: fetchIndex)
        
    }
    
}
