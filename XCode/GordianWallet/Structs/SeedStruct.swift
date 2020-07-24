//
//  SeedStruct.swift
//  FullyNoded2
//
//  Created by Peter on 01/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

public struct SeedStruct: CustomStringConvertible {
    
    let seed:Data?
    let walletId:UUID?
    let id:UUID?
    
    init(dictionary: [String: Any]) {
        seed = dictionary["seed"] as? Data ?? nil
        id = dictionary["id"] as? UUID ?? nil
        walletId = dictionary["walletId"] as? UUID ?? nil
        
    }
    
    public var description: String {
        return ""
    }
    
}
