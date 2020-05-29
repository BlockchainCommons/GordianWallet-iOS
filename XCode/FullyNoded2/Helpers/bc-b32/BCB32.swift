//
//  BCB32.swift
//  FullyNoded2
//
//  Created by Peter on 21/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//
import Foundation

class BCB32 {
    
    /// Takes as input a utf8 plain text string and converts it to bc32 encoded string.
    class func encode(_ string: String) -> String? {
        let inputData = string.utf8
        let data = [UInt8](inputData)
        if let bc32 = bc32_encode(data, data.count) {
            return String(cString: bc32)
        } else {
            return nil
        }
    }
    
    /// Takes as input a bc32 encoded string and converts it to a plain text utf8 string.
    class func decode(_ string: String) -> String? {
        let cString = strdup(string)
        var count:Int = 0
        if let bc32Decoded = bc32_decode(&count, cString) {
            let data = Data(bytes: bc32Decoded, count: count)
            if let decodedString = String(bytes: data, encoding: .utf8) {
                return decodedString
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
}


