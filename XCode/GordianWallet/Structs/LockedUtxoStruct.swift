//
//  LockedUtxoStruct.swift
//  FullyNoded2
//
//  Created by Peter on 10/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public struct LockedUtxoStruct: CustomStringConvertible {
    
    let amount:Double
    let desc:String
    let id:UUID
    let txid:String
    let vout:Int16
    let address:String
    let label:String
    
    init(dictionary: [String: Any]) {
        amount = dictionary["amount"] as! Double
        desc = dictionary["desc"] as! String
        id = dictionary["id"] as! UUID
        txid = dictionary["txid"] as! String
        vout = dictionary["vout"] as! Int16
        address = dictionary["address"] as! String
        label = dictionary["label"] as? String ?? ""
    }
    
    public var description: String {
        return ""
    }
    
}
