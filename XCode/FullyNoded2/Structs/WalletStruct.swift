//
//  WalletStruct.swift
//  StandUp-Remote
//
//  Created by Peter on 09/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public struct WalletStruct: CustomStringConvertible {
    
    let birthdate:Int32
    let derivation:String
    let id:UUID?
    let identity:Data
    let isActive:Bool
    let seed:Data
    let name:String?
    let type:String
    let keys:String
    let descriptor:String
    let index:Int
    let lastUsed:Date
    let lastBalance:Double
    let nodeId:UUID
    let walletCreated:Bool
    let keysImported:Bool
    let isArchived:Bool
    let mOfNtype:String
    let changeDescriptor:String
    let xprv:Data?
    let blockheight:Int32
    let label:String
    let lastUpdated:Date
    var maxRange:Int
    
    init(dictionary: [String: Any]) {
        
        self.birthdate = dictionary["birthdate"] as? Int32 ?? 0
        self.derivation = dictionary["derivation"] as? String ?? ""
        self.id = dictionary["id"] as? UUID ?? nil
        self.identity = dictionary["identity"] as? Data ?? "no identity yet".data(using: .utf8)!
        self.isActive = dictionary["isActive"] as? Bool ?? false
        self.name = dictionary["name"] as? String ?? nil
        self.seed = dictionary["seed"] as? Data ?? "no seed".data(using: .utf8)!
        self.type = dictionary["type"] as? String ?? "DEFAULT"
        self.keys = dictionary["keys"] as? String ?? ""
        self.descriptor = dictionary["descriptor"] as? String ?? ""
        self.index = dictionary["index"] as? Int ?? 0
        self.lastUsed = dictionary["lastUsed"] as? Date ?? Date()
        self.lastBalance = dictionary["lastBalance"] as? Double ?? 0.0
        self.nodeId = dictionary["nodeId"] as? UUID ?? UUID()
        self.walletCreated = dictionary["walletCreated"] as? Bool ?? false
        self.keysImported = dictionary["keysImported"] as? Bool ?? false
        self.isArchived = dictionary["isArchived"] as? Bool ?? false
        self.mOfNtype = dictionary["mOfNtype"] as? String ?? ""
        self.changeDescriptor = dictionary["changeDescriptor"] as? String ?? ""
        self.xprv = dictionary["xprv"] as? Data ?? nil
        self.blockheight = dictionary["blockheight"] as? Int32 ?? 1
        self.label = dictionary["label"] as? String ?? "Add a wallet label"
        self.lastUpdated = dictionary["lastUpdated"] as? Date ?? Date()
        self.maxRange = dictionary["maxRange"] as? Int ?? 999
        
        if self.maxRange == 0 {
            
            self.maxRange = 999
            
        }
        
    }
    
    public var description: String {
        return ""
    }
    
}
