//
//  LifeHashImage.swift
//  GordianWallet
//
//  Created by Peter on 9/18/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import LifeHash
import UIKit

enum LifeHash {
    
    static func image(_ input: String) -> UIImage {
        let arr = input.split(separator: "#")
        var bare = ""
        
        if arr.count > 0 {
            bare = "\(arr[0])".replacingOccurrences(of: "'", with: "h")
        } else {
            bare = input.replacingOccurrences(of: "'", with: "h")
        }
        
        return LifeHashGenerator.generateSync(bare)
    }
    
}
