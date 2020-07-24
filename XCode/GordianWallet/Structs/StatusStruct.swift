//
//  StatusStruct.swift
//  FullyNoded2
//
//  Created by Peter on 22/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public struct StatusStruct: CustomStringConvertible {
    
    let shouldRefill:Bool
    
    init(dictionary: [String: Any]) {
        shouldRefill = dictionary["shouldRefill"] as! Bool
    }
    
    public var description: String {
        return ""
    }
}
