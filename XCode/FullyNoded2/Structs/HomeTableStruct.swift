//
//  HomeTableStruct.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation


public struct HomeStruct: CustomStringConvertible {
    
    let fiatBalance:String
    let network:String
    let hashrate:String
    let amount:Double
    let coldBalance:String
    let version:String
    let torReachable:Bool
    let incomingCount:Int
    let outgoingCount:Int
    let blockheight:Int
    let difficulty:String
    let size:String
    let progress:String
    let pruned:Bool
    let mempoolCount:Int
    let transactions:[[String: Any]]
    let uptime:Int
    let feeRate:String
    let p2pOnionAddress:String
    let unconfirmed:Bool
    let noUtxos:Bool
    let halvingDate:Date
    let knownSigners:Int
    let unknownSigners:Int
    let fxRate:String
    
    init(dictionary: [String: Any]) {
        
        feeRate = dictionary["feeRate"] as? String ?? ""
        uptime = dictionary["uptime"] as? Int ?? 0
        network = dictionary["chain"] as? String ?? ""
        hashrate = dictionary["networkhashps"] as? String ?? ""
        amount = dictionary["amount"] as? Double ?? 0.0
        coldBalance = dictionary["coldBalance"] as? String ?? "0.0"
        version = dictionary["subversion"] as? String ?? ""
        torReachable = dictionary["reachable"] as? Bool ?? false
        incomingCount = dictionary["incomingCount"] as? Int ?? 0
        outgoingCount = dictionary["outgoingCount"] as? Int ?? 0
        blockheight = dictionary["blocks"] as? Int ?? 0
        difficulty = dictionary["difficulty"] as? String ?? ""
        size = dictionary["size"] as? String ?? ""
        progress = dictionary["progress"] as? String ?? ""
        pruned = dictionary["pruned"] as? Bool ?? false
        mempoolCount = dictionary["mempoolCount"] as? Int ?? 0
        transactions = dictionary["transactions"] as? [[String: Any]] ?? []
        p2pOnionAddress = dictionary["p2pOnionAddress"] as? String ?? "none"
        unconfirmed = dictionary["unconfirmed"] as? Bool ?? false
        noUtxos = dictionary["noUtxos"] as? Bool ?? true
        halvingDate = dictionary["halvingDate"] as? Date ?? Date()
        fiatBalance = dictionary["fiatBalance"] as? String ?? "$0"
        knownSigners = dictionary["knownSigners"] as? Int ?? 0
        unknownSigners = dictionary["unknownSigners"] as? Int ?? 0
        fxRate = dictionary["fxRate"] as? String ?? ""
        
    }
    
    public var description: String {
        return ""
    }
    
}
