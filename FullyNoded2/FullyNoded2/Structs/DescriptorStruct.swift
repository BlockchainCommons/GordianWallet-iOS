//
//  DescriptorStruct.swift
//  FullyNoded2
//
//  Created by Peter on 15/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public struct DescriptorStruct: CustomStringConvertible {
    
    let format:String
    let isHot:Bool
    let mOfNType:String
    let chain:String
    let isMulti:Bool
    let isBIP67:Bool
    let isBIP49:Bool
    let isBIP84:Bool
    let isBIP44:Bool
    let isP2WPKH:Bool
    let isP2PKH:Bool
    let isP2SHP2WPKH:Bool
    let network:String
    
    init(dictionary: [String: Any]) {
        
        self.format = dictionary["format"] as? String ?? ""
        self.mOfNType = dictionary["mOfNType"] as? String ?? ""
        self.isHot = dictionary["isHot"] as? Bool ?? false
        self.chain = dictionary["chain"] as? String ?? ""
        self.isMulti = dictionary["isMulti"] as? Bool ?? false
        self.isBIP67 = dictionary["isBIP67"] as? Bool ?? false
        self.isBIP49 = dictionary["isBIP49"] as? Bool ?? false
        self.isBIP84 = dictionary["isBIP84"] as? Bool ?? false
        self.isBIP44 = dictionary["isBIP44"] as? Bool ?? false
        self.isP2PKH = dictionary["isP2PKH"] as? Bool ?? false
        self.isP2WPKH = dictionary["isP2WPKH"] as? Bool ?? false
        self.isP2SHP2WPKH = dictionary["isP2SHP2WPKH"] as? Bool ?? false
        self.network = dictionary["network"] as? String ?? ""
        
    }
    
    public var description: String {
        return ""
    }
    
}
