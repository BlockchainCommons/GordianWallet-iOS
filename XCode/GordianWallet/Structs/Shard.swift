//
//  Shard.swift
//  GordianWallet
//
//  Created by Peter on 9/22/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public struct Shard: CustomStringConvertible {
    let id: String
    let shareValue: String
    let groupThreshold: Int
    let groupCount: Int
    let groupIndex: Int
    let memberThreshold: Int
    let reserved: Int
    let memberIndex: Int
    let raw: String
    
    init(dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        shareValue = dictionary["shareValue"] as! String                        /// the length of this value should equal the length of the master seed
        groupThreshold = dictionary["groupThreshold"] as! Int                   /// required # of groups
        groupCount = dictionary["groupCount"] as! Int                           /// total # of possible groups
        groupIndex = dictionary["groupIndex"] as! Int                           /// the group this share belongs to
        memberThreshold = dictionary["memberThreshold"] as! Int                 /// # of shares required from this group
        reserved = dictionary["reserved"] as! Int                               /// MUST be 0
        memberIndex = dictionary["memberIndex"] as! Int                         ///  the shares member # within its group
        raw = dictionary["raw"] as! String
    }
    
    public var description: String {
        return ""
    }
}
