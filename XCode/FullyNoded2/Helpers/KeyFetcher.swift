//
//  KeyFetcher.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import LibWally

class KeyFetcher {
    
    class func fingerprint(wallet: WalletStruct, completion: @escaping ((fingerprint: String?, error: Bool)) -> Void) {
        
        //let derivationPath = wallet.derivation
        
        if String(data: wallet.seed, encoding: .utf8) != "no seed" {
            
            Encryption.decryptData(dataToDecrypt: wallet.seed) { (seed) in
                
                if seed != nil {
                    
                    if let words = String(data: seed!, encoding: .utf8) {
                                            
                        let mnenomicCreator = MnemonicCreator()
                        mnenomicCreator.convert(words: words) { (mnemonic, error) in
                            
                            if let masterKey = HDKey((mnemonic!.seedHex("")), network(descriptor: wallet.descriptor)) {
                                
                                completion((masterKey.fingerprint.hexString, false))
                                
                            } else {
                                
                                print("error getting master key")
                                completion((nil, true))
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            
            completion((nil, true))
            print("no seed")
            
        }
        
    }
    
    class func privKey(path: BIP32Path, completion: @escaping ((privKey: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                //let derivationPath = wallet!.derivation
                
                if String(data: wallet!.seed, encoding: .utf8) != "no seed" {
                    
                    Encryption.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                        
                        if seed != nil {
                            
                            let words = String(data: seed!, encoding: .utf8)!
                            
                            let mnenomicCreator = MnemonicCreator()
                            
                            mnenomicCreator.convert(words: words) { (mnemonic, error) in
                                
                                if !error {
                                    
                                    if let masterKey = HDKey((mnemonic!.seedHex("")), network(descriptor: wallet!.descriptor)) {
                                        
                                        do {
                                            
                                            let key = try masterKey.derive(path)
                                            
                                            if let keyToReturn = key.privKey {
                                                
                                                let wif = keyToReturn.wif
                                                completion((wif,false))
                                                
                                            } else {
                                                
                                                completion((nil,true))
                                                
                                            }
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    if wallet!.xprv != nil {
                        
                        // its a recovered wallet without a mnemonic, need to remove the account derivation as we know the psbt will return the full path
                        var processedDerivation = ""
                        let arr = "\(path)".split(separator: "/")
                        for (i, pathComponent) in arr.enumerated() {
                            
                            if i > 3 {
                                
                                processedDerivation += "/" + "\(pathComponent)"
                                
                            }
                            
                            if i + 1 == arr.count {
                                
                                if let accountLessPath = BIP32Path(processedDerivation) {
                                    
                                    Encryption.decryptData(dataToDecrypt: wallet!.xprv!) { (decryptedXprv) in
                                        
                                        if decryptedXprv != nil {
                                            
                                            if let xprvString = String(data: decryptedXprv!, encoding: .utf8) {
                                                
                                                if let hdKey = HDKey(xprvString) {
                                                    
                                                    do {
                                                        
                                                        let key = try hdKey.derive(accountLessPath)
                                                        
                                                        if let keyToReturn = key.privKey {
                                                            
                                                            let wif = keyToReturn.wif
                                                            completion((wif,false))
                                                            
                                                        } else {
                                                            
                                                            completion((nil,true))
                                                            
                                                        }
                                                        
                                                    } catch {
                                                        
                                                        completion((nil,true))
                                                        print("failed deriving child key")
                                                        
                                                    }
                                                    
                                                }
                                                
                                            }
                                            
                                        } else {
                                            
                                            completion((nil,true))
                                            print("failed decrypting xprv")
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    print("failed deriving processed path")
                                    completion((nil,true))
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        // its a watch-only wallet
                        completion((nil,true))
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    class func key(path: BIP32Path, completion: @escaping ((key: HDKey?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                //let derivationPath = wallet!.derivation
                
                Encryption.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                    
                    if String(data: wallet!.seed, encoding: .utf8) != "no seed" {
                        
                        if seed != nil {
                            
                            let words = String(data: seed!, encoding: .utf8)!
                            let mnenomicCreator = MnemonicCreator()
                            mnenomicCreator.convert(words: words) { (mnemonic, error) in
                                
                                if !error {
                                    
                                    if let masterKey = HDKey((mnemonic!.seedHex("")), network(descriptor: wallet!.descriptor)) {
                                        
                                        do {
                                            
                                            let key = try masterKey.derive(path)
                                            completion((key,false))
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        if wallet!.xprv != nil {
                            
                            // its a recovered wallet without a mnemonic, need to remove the account derivation as we know the psbt will return the full path
                            var processedDerivation = ""
                            let arr = "\(path)".split(separator: "/")
                            for (i, pathComponent) in arr.enumerated() {
                                
                                if i > 3 {
                                    
                                    processedDerivation += "/" + "\(pathComponent)"
                                    
                                }
                                
                                if i + 1 == arr.count {
                                    
                                    if let accountLessPath = BIP32Path(processedDerivation) {
                                        
                                        Encryption.decryptData(dataToDecrypt: wallet!.xprv!) { (decryptedXprv) in
                                            
                                            if decryptedXprv != nil {
                                                
                                                if let xprvString = String(data: decryptedXprv!, encoding: .utf8) {
                                                    
                                                    if let hdKey = HDKey(xprvString) {
                                                        
                                                        do {
                                                            
                                                            let key = try hdKey.derive(accountLessPath)
                                                            completion((key,false))
                                                            
                                                        } catch {
                                                            
                                                            completion((nil,true))
                                                            print("failed deriving child key")
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                }
                                                
                                            } else {
                                                
                                                completion((nil,true))
                                                print("failed decrypting xprv")
                                                
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        print("failed deriving processed path")
                                        completion((nil,true))
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                    }
                    
                }
                
            }
            
        }
        
    }
    
    class func xpub(wallet: WalletStruct, completion: @escaping ((xpub: String?, error: Bool)) -> Void) {
        
        //let derivationPath = wallet.derivation
        Encryption.decryptData(dataToDecrypt: wallet.seed) { (seed) in
            
            if seed != nil {
                
                let words = String(data: seed!, encoding: .utf8)!
                let mnenomicCreator = MnemonicCreator()
                mnenomicCreator.convert(words: words) { (mnemonic, error) in
                    
                    if !error {
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network(descriptor: wallet.descriptor)) {
                            
                            if let path = BIP32Path(wallet.derivation) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    completion((account.xpub,false))
                                    
                                } catch {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        } else {
                            
                            completion((nil,true))
                            
                        }
                        
                    } else {
                        
                        completion((nil,true))
                        
                    }
                    
                }
                
            } else {
                
                completion((nil,true))
                
            }
            
        }
        
    }
    
    class func accountXpub(descriptorStruct: DescriptorStruct, completion: @escaping ((xpub: String?, error: Bool)) -> Void) {
        
        if descriptorStruct.isMulti {
            
            if descriptorStruct.multiSigKeys.count > 0 {
                
                if descriptorStruct.multiSigKeys[1] != "" {
                    
                    completion((descriptorStruct.multiSigKeys[1], false))
                    
                } else {
                    
                    completion(("", true))
                    
                }
                
            } else {
                
                completion(("", true))
                
            }
            
        } else {
           
            let xpub = descriptorStruct.accountXpub
            completion((xpub, false))
            
        }
        
    }
    
    class func accountXprv(completion: @escaping ((xprv: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil && !error {
                
                let derivationPath = wallet!.derivation
                Encryption.decryptData(dataToDecrypt: wallet!.seed) { (seed) in
                    
                    if seed != nil {
                        
                        let words = String(data: seed!, encoding: .utf8)!
                        let mnenomicCreator = MnemonicCreator()
                        mnenomicCreator.convert(words: words) { (mnemonic, error) in
                            
                            if !error {
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), network(descriptor: wallet!.descriptor)) {
                                    
                                    if let path = BIP32Path(derivationPath) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            
                                            if let xprv = account.xpriv {
                                                
                                                completion((xprv,false))
                                                
                                            } else {
                                                
                                                completion((nil,true))
                                                
                                            }
                                            
                                        } catch {
                                            
                                            completion((nil,true))
                                            
                                        }
                                        
                                    } else {
                                        
                                        completion((nil,true))
                                        
                                    }
                                    
                                } else {
                                    
                                    completion((nil,true))
                                    
                                }
                                
                            } else {
                                
                                completion((nil,true))
                                
                            }
                            
                        }
                        
                    } else {
                        
                        completion((nil,true))
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    class func musigAddress(completion: @escaping ((address: String?, error: Bool)) -> Void) {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                let index = wallet!.index + 1
                let param = "\"\(wallet!.descriptor)\", [\(index),\(index)]"
                
                Reducer.makeCommand(walletName: wallet!.name!, command: .deriveaddresses, param: param) { (object, errorDesc) in
                    
                    if let addresses = object as? NSArray {
                        
                        updateIndex(wallet: wallet!)
                        
                        if let address = addresses[0] as? String {
                            
                            completion((address,false))
                            
                        } else {
                            
                            completion((nil,true))
                            
                        }
                        
                    } else {
                        
                        completion((nil,true))
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    class func musigChangeAddress(completion: @escaping ((address: String?, error: Bool, errorDescription: String?)) -> Void) {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                let index = wallet!.index
                
                if wallet!.index < wallet!.maxRange {
                    
                    let param = "\"\(wallet!.changeDescriptor)\", [\(index),\(index)]"
                    
                    Reducer.makeCommand(walletName: wallet!.name!, command: .deriveaddresses, param: param) { (object, errorDesc) in
                        
                        if let addresses = object as? NSArray {
                            
                            if let address = addresses[0] as? String {
                                
                                completion((address,false,nil))
                                
                            } else {
                                
                                completion((nil,true,"error fecthing change address"))
                                
                            }
                            
                        } else {
                            
                            completion((nil,true,"error deriving addresses: \(errorDesc ?? "")"))
                            
                        }
                        
                    }
                    
                } else {
                    
                    completion((nil,true,"You need to refill the keypool in order to create more transactions"))
                    
                }
                
            }
            
        }
        
    }
    
    class func updateIndex(wallet: WalletStruct) {
        
        CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "index", newValue: wallet.index + 1, entityName: .wallets) { (success, errorDescription) in
            
            if !success {
                
                print("error updating index: \(errorDescription ?? "unknown error")")
                
            }
            
        }
        
    }
    
}
