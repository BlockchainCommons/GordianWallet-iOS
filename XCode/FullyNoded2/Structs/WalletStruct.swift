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
    let nodeId:UUID?
    let walletCreated:Bool
    let keysImported:Bool
    let isArchived:Bool
    let mOfNtype:String
    let changeDescriptor:String
    let xprv:Data?
    let blockheight:Int32
    let label:String
    let lastUpdated:Date
    let maxRange:Int
    let hasRange:Bool
    let knownSigners:Int
    let unknownSigners:Int
    let nodeIsSigner:Bool?
    let knownFingerprints:[String]?
    
    init(dictionary: [String: Any]) {
        birthdate = dictionary["birthdate"] as? Int32 ?? 0
        derivation = dictionary["derivation"] as? String ?? ""
        id = dictionary["id"] as? UUID ?? nil
        identity = dictionary["identity"] as? Data ?? "no identity yet".data(using: .utf8)!
        isActive = dictionary["isActive"] as? Bool ?? false
        name = dictionary["name"] as? String ?? nil
        seed = dictionary["seed"] as? Data ?? "no seed".data(using: .utf8)!
        type = dictionary["type"] as? String ?? "DEFAULT"
        keys = dictionary["keys"] as? String ?? ""
        descriptor = dictionary["descriptor"] as? String ?? ""
        index = dictionary["index"] as? Int ?? 0
        lastUsed = dictionary["lastUsed"] as? Date ?? Date()
        lastBalance = dictionary["lastBalance"] as? Double ?? 0.0
        nodeId = dictionary["nodeId"] as? UUID
        walletCreated = dictionary["walletCreated"] as? Bool ?? false
        keysImported = dictionary["keysImported"] as? Bool ?? false
        isArchived = dictionary["isArchived"] as? Bool ?? false
        mOfNtype = dictionary["mOfNtype"] as? String ?? ""
        changeDescriptor = dictionary["changeDescriptor"] as? String ?? ""
        xprv = dictionary["xprv"] as? Data ?? nil
        blockheight = dictionary["blockheight"] as? Int32 ?? 1
        label = dictionary["label"] as? String ?? "Add a wallet label"
        lastUpdated = dictionary["lastUpdated"] as? Date ?? Date()
        maxRange = dictionary["maxRange"] as? Int ?? 0
        hasRange = dictionary["hasRange"] as? Bool ?? true
        knownSigners = dictionary["knownSigners"] as? Int ?? 0
        unknownSigners = dictionary["unknownSigners"] as? Int ?? 0
        nodeIsSigner = dictionary["nodeIsSigner"] as? Bool
        knownFingerprints = dictionary["knownFingerprints"] as? [String]
        
    }
    
    public var description: String {
        return ""
    }
    
}
