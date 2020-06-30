//
//  WalletStatus.swift
//  FullyNoded2
//
//  Created by Peter on 22/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class WalletStatus {
    
    class func getStatus(wallet: WalletStruct, completion: @escaping (([String:Bool])) -> Void) {
        var shouldRefill = false
        let keyIndex = wallet.index
        let maxRange = wallet.maxRange
        if maxRange - keyIndex < 100 {
            shouldRefill = true
        }
        let dict = ["shouldRefill":shouldRefill]
        completion((dict))
    }
}
