//
//  XpubConverter.swift
//  FullyNoded2
//
//  Created by Peter on 05/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class XpupConverter {
    
    class func convert(xpub: String) {
        
        //let xpubPrefix = "0488b21e"
//        let tpubPrefix = "043587cf"
        
//        let otherPrefixes =
//            [
//                "ypub": "049d7cb2",
//                "Ypub": "0295b43f",
//                "zpub": "04b24746",
//                "Zpub": "02aa7ed3",
//                "upub": "044a5262",
//                "Upub": "024289ef",
//                "vpub": "045f1cf6",
//                "Vpub": "02575483"
//        ]
        
//        var b58 = Base58.decode(xpub)
//        b58.removeFirst(4)
//        var prefix = Data(tpubPrefix)!
//        prefix.append(contentsOf: b58)
//        let array = [UInt8](prefix)
//        let tpub = Base58.encode(array)
//        print("tpub = \(tpub)")
        
        //let tpubwithoutchecksum = "tpubDF1KdVPYeyvXCb1B7B9SkvWBcpeqQqJwenDDprb7khy8JcHhYkL3TapsSPUvsBx68jDP1qc1hbDi5doNbbAHVDf1X4DfSixMNUHNC"
        
        // Original:
        // tpubDF1KdVPYeyvXCb1B7B9SkvWBcpeqQqJwenDDprb7khy8JcHhYkL3TapsSPUvsBx68jDP1qc1hbDi5doNbbAHVDf1X4DfSixMNUHNCDSgUzS
        
        // Converts to (using Lopps tool):
        // Vpub5msFd9xUDJSUembTvw45xuKcfZJYkZWUbCE9pn1k2ZHt5JZSjcY7A8hgxeSSuJuum1Wqmtu98P54k3hQ4Zdy9nxBZFBuzn898nqYF1Z5Dwk
        
        // Results in:
        // tpubDF1KdVPYeyvXCb1B7B9SkvWBcpeqQqJwenDDprb7khy8JcHhYkL3TapsSPUvsBx68jDP1qc1hbDi5doNbbAHVDf1X4DfSixMNUHNCFWtSLW
                
    }
}
