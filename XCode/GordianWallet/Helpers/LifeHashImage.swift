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
        return LifeHashGenerator.generateSync(input)
    }
    
}
