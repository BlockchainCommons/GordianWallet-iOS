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
        
        guard let bip32path = BIP32Path(wallet.derivation) else {
            completion((nil, nil))
            return
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
        
        CoreDataService.retrieveEntity(entityName: .seeds) { (encryptedSeeds, errorDescription) in
            
            if encryptedSeeds != nil {
                
                if encryptedSeeds!.count > 0 {
                    
                    for (i, seed) in encryptedSeeds!.enumerated() {
                        
                        let seedStruct = SeedStruct(dictionary: seed)
                        
                        if let encryptedSeed = seedStruct.seed {
                            
                            Encryption.decryptData(dataToDecrypt: encryptedSeed) { decryptedSeed in
                                
                                if decryptedSeed != nil {
                                    
                                    if let words = String(data: decryptedSeed!, encoding: .utf8) {
                                        
                                        MnemonicCreator.convert(words: words) { (mnemonic, error) in
                                            
                                            if !error {
                                                
                                                if let masterKey = HDKey(mnemonic!.seedHex(""), chain) {
                                                    
                                                    do {
                                                        
                                                        let hdkey = try masterKey.derive(bip32path)
                                                        let seedsDerivedXpub = hdkey.xpub
                                                        derivedXpubs.append(seedsDerivedXpub)
                                                        
                                                    } catch {
                                                        
                                                        
                                                        
                                                    }
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        if i + 1 == encryptedSeeds!.count {
                            checkKeys()
                            
                        }
                        
                    }
                    
                }
                
            }
            
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
    
    class func fetchSeeds(wallet: WalletStruct, completion: @escaping (([String]?)) -> Void) {
        
        var xpubs = [String]()
        var derivedXpubs = [String]()
        var potentialSeeds = [String]()
        var accountsSeeds = [String]()
        let descriptorParser = DescriptorParser()
        let descriptorStruct = descriptorParser.descriptor(wallet.descriptor)
        let chain = network(descriptor: wallet.descriptor)
        
        if wallet.type == "MULTI" {
            xpubs = descriptorStruct.multiSigKeys
            
        } else {
            xpubs.append(descriptorStruct.accountXpub)
            
        }
        
        guard let bip32path = BIP32Path(wallet.derivation) else {
            completion((nil))
            return
        }
        
        func checkKeys() {
            let unique = Array(Set(potentialSeeds))
            
            for (i, xpub) in xpubs.enumerated() {
                
                for (p, potentialSeed) in unique.enumerated() {
                    
                    MnemonicCreator.convert(words: potentialSeed) { (mnemonic, error) in
                        
                        if !error {
                            
                            if let masterKey = HDKey(mnemonic!.seedHex(""), chain) {
                                
                                do {
                                    
                                    let hdkey = try masterKey.derive(bip32path)
                                    
                                    if xpub == hdkey.xpub {
                                        accountsSeeds.append(potentialSeed)
                                        
                                    }
                                    
                                    if i + 1 == xpubs.count && p + 1 == unique.count {
                                        completion((accountsSeeds))

                                    }
                                    
                                } catch {
                                    
                                    
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        CoreDataService.retrieveEntity(entityName: .seeds) { (encryptedSeeds, errorDescription) in
            
            if encryptedSeeds != nil {
                
                if encryptedSeeds!.count > 0 {
                    
                    for (i, seed) in encryptedSeeds!.enumerated() {
                        
                        let seedStruct = SeedStruct(dictionary: seed)
                        
                        if let encryptedSeed = seedStruct.seed {
                            
                            Encryption.decryptData(dataToDecrypt: encryptedSeed) { decryptedSeed in
                                
                                if decryptedSeed != nil {
                                    
                                    if let words = String(data: decryptedSeed!, encoding: .utf8) {
                                        potentialSeeds.append(words)
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        if i + 1 == encryptedSeeds!.count {
                            checkKeys()
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
                
    }
    
}
