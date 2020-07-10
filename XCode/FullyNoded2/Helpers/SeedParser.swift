//
//  SeedParser.swift
//  FullyNoded2
//
//  Created by Peter on 01/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import LibWally

class SeedParser {
    
    class func getSigners(wallet: WalletStruct, completion: @escaping ((knownSigners: [String], uknownSigners: [String])) -> Void) {
        var knownSigners = [String]()
        var unknownSigners = [String]()
        var xpubs = [String]()
        var unknownXpubs = [String]()
        let descriptorParser = DescriptorParser()
        let descriptorStruct = descriptorParser.descriptor(wallet.descriptor)
        
        if wallet.type == "MULTI" {
            xpubs = descriptorStruct.multiSigKeys
        } else {
            xpubs.append(descriptorStruct.accountXpub)
        }
        unknownXpubs = xpubs
                
        if wallet.xprvs != nil {
            // we know the wallet can sign, rely on actual xprvs to derive fingerprints
            for (x, encryptedXprv) in wallet.xprvs!.enumerated() {
                Encryption.decryptData(dataToDecrypt: encryptedXprv) { (decryptedXprv) in
                    if decryptedXprv != nil {
                        if let xprvString = String(bytes: decryptedXprv!, encoding: .utf8) {
                            if let hdKey = HDKey(xprvString) {
                                for (i, xpub) in xpubs.enumerated() {
                                    if xpub == hdKey.xpub {
                                        // Here we can remove xpubs from the unknown array as we know it is known
                                        if unknownXpubs.count > i {
                                            unknownXpubs.remove(at: i)
                                        }
                                        let fingerprint = hdKey.fingerprint.hexString
                                        knownSigners.append(fingerprint)
                                    }
                                    if i + 1 == xpubs.count && x + 1 == wallet.xprvs!.count {
                                        for (u, unknowXpub) in unknownXpubs.enumerated() {
                                            let keysWithPath = descriptorStruct.keysWithPath
                                            for (k, keyWithPath) in keysWithPath.enumerated() {
                                                if keyWithPath.contains(unknowXpub) {
                                                    unknownSigners.append(descriptorStruct.fingerprints[k])
                                                }
                                                if k + 1 == keysWithPath.count && u + 1 == unknownXpubs.count {
                                                    completion((unknownSigners, knownSigners))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            unknownSigners = descriptorStruct.fingerprints
            completion(([""], unknownSigners))
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
