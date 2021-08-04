//
//  KeychainCreator.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import LibWally

class KeychainCreator {
    
    class func createKeyChain(completion: @escaping ((mnemonic: String?, error: Bool)) -> Void) {
        let bytesCount = 16
        var randomBytes = [UInt8](repeating: 0, count: bytesCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        guard status == errSecSuccess else { completion((nil,true)); return }
        let data = Data(randomBytes)
        let entropy = BIP39Mnemonic.Entropy(data)
        
        guard let mnemonic = try? BIP39Mnemonic(entropy: entropy) else { completion((nil,true)); return }
        var words = (mnemonic.words.description).replacingOccurrences(of: "\"", with: "")
        words = words.replacingOccurrences(of: ",", with: "")
        words = words.replacingOccurrences(of: "[", with: "")
        words = words.replacingOccurrences(of: "]", with: "")
        
        completion((words,false))
    }
}
