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
    
    init(dictionary: [String: Any]) {
        
        self.format = dictionary["format"] as? String ?? ""
        self.mOfNType = dictionary["mOfNType"] as? String ?? ""
        self.isHot = dictionary["isHot"] as? Bool ?? false
        self.chain = dictionary["chain"] as? String ?? ""
        self.isMulti = dictionary["isMulti"] as? Bool ?? false
        self.isBIP67 = dictionary["isBIP67"] as? Bool ?? false
        
    }
    
    public var description: String {
        return ""
    }
    
}
