//
//  SeedParser.swift
//  FullyNoded2
//
//  Created by Peter on 01/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import LibWally

class SeedParser {
    
    class func parseWallet(wallet: WalletStruct, completion: @escaping ((known: Int?, unknown: Int?)) -> Void) {
        var xpubs = [String]()
        var derivedXpubs = [String]()
        let descriptorParser = DescriptorParser()
        let descriptorStruct = descriptorParser.descriptor(wallet.descriptor)
        let chain = network(descriptor: wallet.descriptor)
        
        if wallet.type == "MULTI" {
            xpubs = descriptorStruct.multiSigKeys
            
        } else {
            xpubs.append(descriptorStruct.accountXpub)
            
        }
        
        func checkKeys() {
            var known = 0
            var unknown = xpubs.count
            let unique = Array(Set(derivedXpubs))
            for (i, xpub) in xpubs.enumerated() {
                for (p, potentialXpub) in unique.enumerated() {
                    if xpub == potentialXpub {
                        /// It is known
                        known += 1
                        unknown -= 1
                    }
                    if i + 1 == xpubs.count && p + 1 == unique.count {
                        completion((known, unknown))
                    }
                }
            }
        }
        
        func getSeedsFromMnemonic(bip32Path: BIP32Path) {
            Encryption.decryptedSeeds { (decryptedSeeds) in
                if decryptedSeeds != nil {
                    for (i, seed) in decryptedSeeds!.enumerated() {
                        if let mnemonic = BIP39Mnemonic(seed) {
                            if let masterKey = HDKey(mnemonic.seedHex(""), chain) {
                                do {
                                    let hdkey = try masterKey.derive(bip32Path)
                                    let seedsDerivedXpub = hdkey.xpub
                                    derivedXpubs.append(seedsDerivedXpub)
                                    if i + 1 == decryptedSeeds!.count {
                                        checkKeys()
                                    }
                                } catch {
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
        if wallet.xprv != nil {
            Encryption.decryptData(dataToDecrypt: wallet.xprv!) { (decryptedXprv) in
                if decryptedXprv != nil {
                    if let xprv = String(bytes: decryptedXprv!, encoding: .utf8) {
                        if let masterKey = HDKey(xprv) {
                            let seedsDerivedXpub = masterKey.xpub
                            derivedXpubs.append(seedsDerivedXpub)
                            checkKeys()
                        }
                    } else {
                        completion((nil, nil))
                    }
                } else {
                    completion((nil, nil))
                }
            }
        } else {
            guard let bip32path = BIP32Path(wallet.derivation) else {
                completion((nil, nil))
                return
            }
            getSeedsFromMnemonic(bip32Path: bip32path)
        }
                
    }
    
    class func parseSeed(seed: SeedStruct, completion: @escaping (([String]?)) -> Void) {
        var walletLabelArray = [String]()
        let descriptorParser = DescriptorParser()
        
        if let encryptedSeed = seed.seed {
            
            Encryption.decryptData(dataToDecrypt: encryptedSeed) { decryptedSeed in
                
                if decryptedSeed != nil {
                    
                    if let words = String(data: decryptedSeed!, encoding: .utf8) {
                        
                        MnemonicCreator.convert(words: words) { (mnemonic, error) in
                            
                            if !error {
                                
                                CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                                    
                                    if wallets != nil {
                                        
                                        for (i, wallet) in wallets!.enumerated() {
                                            let walletStruct = WalletStruct(dictionary: wallet)
                                            
                                            if !walletStruct.isArchived {
                                                let descriptorStruct = descriptorParser.descriptor(walletStruct.descriptor)
                                                let chain = network(descriptor: walletStruct.descriptor)
                                                
                                                if let bip32path = BIP32Path(walletStruct.derivation) {
                                                    
                                                    if let masterKey = HDKey(mnemonic!.seedHex(""), chain) {
                                                        
                                                        do {
                                                            
                                                            let hdkey = try masterKey.derive(bip32path)
                                                            
                                                            if descriptorStruct.isMulti {
                                                                
                                                                for xpub in descriptorStruct.multiSigKeys {
                                                                    
                                                                    if xpub == hdkey.xpub {
                                                                        walletLabelArray.append(walletStruct.label)
                                                                        
                                                                    }
                                                                    
                                                                }
                                                                
                                                            } else {
                                                                
                                                                if hdkey.xpub == descriptorStruct.accountXpub {
                                                                    walletLabelArray.append(walletStruct.label)
                                                                    
                                                                }
                                                                
                                                            }
                                                            
                                                        } catch {
                                                            completion((nil))
                                                            
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            if i + 1 == wallets!.count {
                                                completion((walletLabelArray))
                                                
                                            }
                                            
                                        }
                                        
                                    } else {
                                        completion((nil))
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    class func fetchSeeds(wallet: WalletStruct, completion: @escaping ((words: [String]?, fingerprints: [String]?)) -> Void) {
        var derivation = ""
        var xpubs = [String]()
        var accountsSeeds = [String]()
        var fingerprints = [String]()
        let descriptorParser = DescriptorParser()
        let descriptorStruct = descriptorParser.descriptor(wallet.descriptor)
        let chain = network(descriptor: wallet.descriptor)
        
        if wallet.type == "MULTI" {
            xpubs = descriptorStruct.multiSigKeys
        } else {
            xpubs.append(descriptorStruct.accountXpub)
        }
        
        func checkMnemonics(seeds: [String], bip32Path: BIP32Path) {
            let unique = Array(Set(seeds))
            for (i, xpub) in xpubs.enumerated() {
                for (p, potentialSeed) in unique.enumerated() {
                    if let mnemonic = BIP39Mnemonic(potentialSeed) {
                        if let masterKey = HDKey(mnemonic.seedHex(""), chain) {
                            do {
                                let hdkey = try masterKey.derive(bip32Path)
                                if xpub == hdkey.xpub {
                                    accountsSeeds.append(potentialSeed)
                                    fingerprints.append(masterKey.fingerprint.hexString)
                                }
                                if i + 1 == xpubs.count && p + 1 == unique.count {
                                    completion((accountsSeeds, fingerprints))
                                }
                            } catch {
                                
                            }
                        }
                    }
                }
            }
        }
        
        func checkXprv(xprv: String, bip32Path: BIP32Path) {
            for (i, xpub) in xpubs.enumerated() {
                if let masterKey = HDKey(xprv) {
                    do {
                        let hdkey = try masterKey.derive(bip32Path)
                        if xpub == hdkey.xpub {
                            fingerprints.append(masterKey.fingerprint.hexString)
                        }
                        if i + 1 == xpubs.count {
                            completion(([xprv], fingerprints))
                        }
                    } catch {
                        
                    }
                }
            }
        }
                
        if wallet.xprv != nil {
            derivation = "0/0"
            
            guard let bip32path = BIP32Path(derivation) else {
                completion((nil, nil))
                return
            }
            
            Encryption.decryptData(dataToDecrypt: wallet.xprv!) { (decryptedXprv) in
                if decryptedXprv != nil {
                    if let xprv = String(bytes: decryptedXprv!, encoding: .utf8) {
                        checkXprv(xprv: xprv, bip32Path: bip32path)
                    } else {
                        completion((nil, nil))
                    }
                } else {
                    completion((nil, nil))
                }
            }
            
        } else {
            derivation = wallet.derivation
            
            guard let bip32path = BIP32Path(derivation) else {
                completion((nil, nil))
                return
            }
            
            Encryption.decryptedSeeds { (decryptedSeeds) in
                if decryptedSeeds != nil {
                    checkMnemonics(seeds: decryptedSeeds!, bip32Path: bip32path)
                } else {
                    completion((nil, nil))
                }
            }
        }
    }
    
}
