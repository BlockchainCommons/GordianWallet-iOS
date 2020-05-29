//
//  TransactionStruct.swift
//  FullyNoded2
//
//  Created by Peter on 19/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public struct TransactionStruct: CustomStringConvertible {
    let accountLabel:String
    let btcReceived:Double
    let btcSent:Double
    let date:Date?
    let derivation:String
    let descriptor:String
    let fingerprint:String
    let fxRate:Double?
    let incoming:Bool
    let outgoing:Bool
    let memo:String
    let miningFeeBtc:Double
    let txid:String
    let xpub:String
    let id:UUID?
    
    init(dictionary: [String:Any]) {
        accountLabel = dictionary["accountLabel"] as? String ?? ""
        btcReceived = dictionary["btcReceived"] as? Double ?? 0.0
        btcSent = dictionary["btcSent"] as? Double ?? 0.0
        date = dictionary["date"] as? Date
        derivation = dictionary["derivation"] as? String ?? ""
        descriptor = dictionary["descriptor"] as? String ?? ""
        fingerprint = dictionary["fingerprint"] as? String ?? ""
        fxRate = dictionary["fxRate"] as? Double
        incoming = dictionary["incoming"] as? Bool ?? false
        outgoing = dictionary["outgoing"] as? Bool ?? false
        memo = dictionary["memo"] as? String ?? ""
        miningFeeBtc = dictionary["miningFeeBtc"] as? Double ?? 0.0
        txid = dictionary["txid"] as? String ?? ""
        xpub = dictionary["xpub"] as? String ?? ""
        id = dictionary["id"] as? UUID
    }
    
    public var description: String {
        return ""
    }
}
