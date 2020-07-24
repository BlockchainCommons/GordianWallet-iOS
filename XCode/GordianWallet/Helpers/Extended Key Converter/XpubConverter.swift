//
//  XpubConverter.swift
//  FullyNoded2
//
//  Created by Peter on 05/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import CryptoKit

class XpubConverter {
    
    /// Takes in any extended public key format as per SLIP-0132 and returns a Bitcoin Core compatible xpub or tpub.
    class func convert(extendedKey: String) -> String? {
        let mainnetPrefix = "0488b21e"
        let testnetPrefix = "043587cf"
        var providedPrefix = ""
        var returnedPrefix = mainnetPrefix
        let possiblePrefixes = [
            "ypub": "049d7cb2",/// Mainnet
            "Ypub": "0295b43f",
            "zpub": "04b24746",
            "Zpub": "02aa7ed3",
            "upub": "044a5262",/// Testnet
            "Upub": "024289ef",
            "vpub": "045f1cf6",
            "Vpub": "02575483"
        ]
        
        for (key, value) in possiblePrefixes {
            
            if extendedKey.hasPrefix(key) {
                providedPrefix = value
                
            }
        }
        
        switch providedPrefix {
        case "044a5262", "024289ef", "045f1cf6", "02575483":
            /// It is testnet so we return a tpub
            returnedPrefix = testnetPrefix
            
        default:
            break
        }
        
        if providedPrefix != "" {
            /// Decodes our original extended key to base58 data.
            var b58 = Base58.decode(extendedKey)
            /// Removes the original prefix.
            b58.removeFirst(4)
            /// Converts the new prefix string to data.
            var prefix = Data(returnedPrefix)!
            /// Appends the xpub data to the new prefix.
            prefix.append(contentsOf: b58)
            /// Converts our data to array so we can easily manipulate it.
            var convertedXpub = [UInt8](prefix)
            /// Removes incorrect checksum.
            convertedXpub.removeLast(4)
            /// Hashes the new raw xpub twice.
            let hash = SHA256.hash(data: Data(SHA256.hash(data: convertedXpub)))
            /// Gets the correct checksum from the double hash.
            let checksum = Data(hash).subdata(in: Range(0...3))
            /// Appends it.
            convertedXpub.append(contentsOf: checksum)
            /// And its ready 🤩
            return Base58.encode(convertedXpub)
            
        } else {
            /// Invalid extended key supplied by the user.
            return nil
            
        }
    }
}
