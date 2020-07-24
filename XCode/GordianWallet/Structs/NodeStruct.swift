//
//  NodeStruct.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation


public struct NodeStruct: CustomStringConvertible {
    
    let label:String
    let onionAddress:String
    let rpcpassword:String
    let rpcuser:String
    let isActive:Bool
    let id:UUID
    let network:String
    
    init(dictionary: [String: Any]) {
        
        self.label = dictionary["label"] as? String ?? "Bitcoin Core"
        self.onionAddress = dictionary["onionAddress"] as? String ?? ""
        self.rpcpassword = dictionary["rpcpassword"] as? String ?? ""
        self.rpcuser = dictionary["rpcuser"] as? String ?? ""
        self.isActive = dictionary["isActive"] as? Bool ?? true
        self.id = dictionary["id"] as! UUID
        self.network = dictionary["network"] as? String ?? "testnet"
        
    }
    
    public var description: String {
        return ""
    }
    
}

