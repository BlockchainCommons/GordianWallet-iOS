//
//  CheckSubAccounts.swift
//  FullyNoded2
//
//  Created by Peter on 21/07/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class CheckSubAccounts {
    
    class func check(words: String, derivation: String, completion: @escaping (([[String:Any]]?)) -> Void) {
        var derivations = [["derivation":derivation + "/1'", "addresses":[], "hasHistory":false],  ["derivation":derivation + "/2'", "addresses":[], "hasHistory":false], ["derivation": derivation + "/3'", "addresses":[], "hasHistory":false], ["derivation": derivation + "/4'", "addresses":[], "hasHistory":false], ["derivation": derivation + "/5'", "addresses":[], "hasHistory":false], ["derivation": derivation + "/6'", "addresses":[], "hasHistory":false], ["derivation": derivation + "/7'", "addresses":[], "hasHistory":false], ["derivation": derivation + "/8'", "addresses":[], "hasHistory":false], ["derivation":derivation + "/9'", "addresses":[], "hasHistory":false], ["derivation":derivation + "/10'", "addresses":[], "hasHistory":false]] as [[String:Any]]
        
        var addressesIndex = 0
        var balancesIndex = 0
        
        func fetchBalances(index: Int, addressIndex: Int) {
            if balancesIndex < derivations.count {
                let addresses = derivations[index]["addresses"] as! [String]
                if addressesIndex < addresses.count {
                    let shared = AddressScanner.sharedInstance
                    shared.scan(address: addresses[addressesIndex]) { (hasHistory) in
                        if hasHistory != nil {
                            if hasHistory! {
                                derivations[index]["hasHistory"] = true
                            }
                            addressesIndex += 1
                            if addressesIndex == addresses.count {
                                balancesIndex += 1
                            }
                            fetchBalances(index: index, addressIndex: addressesIndex)
                        }
                    }
                } else {
                    addressesIndex = 0
                    fetchBalances(index: balancesIndex, addressIndex: addressesIndex)
                }
            } else {
                completion(derivations)
            }
        }
        
        var fetchIndex = 0
        func fetchAddresses(index: Int) {
            if index < derivations.count {
                KeyFetcher.fetchAddresses(words: words, derivation: (derivations[index]["derivation"] as! String)) { (addresses) in
                    if addresses != nil {
                        derivations[index]["addresses"] = addresses!
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
