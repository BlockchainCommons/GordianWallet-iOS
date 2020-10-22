//
//  Import.swift
//  FullyNoded2
//
//  Created by Peter on 30/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import LibWally

class Import {
    
    class func importDescriptor(descriptor: String, completion: @escaping (([String:Any]?)) -> Void) {
        var walletToImport = [String:Any]()
        let updated = updatedDesc(descriptor)
        let descriptorParser = DescriptorParser()
        let descriptorStruct = descriptorParser.descriptor(updated)
        
        func getChangeDescriptor(changeDesc: String) {
            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    let changeDescriptor = dict["descriptor"] as! String
                    walletToImport["changeDescriptor"] = changeDescriptor
                    completion(walletToImport)
                } else {
                    completion(nil)
                }
            }
        }
        
        func getDescriptors(primaryDesc: String, changeDesc: String) {
            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryDesc)\"") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    let descriptor = dict["descriptor"] as! String
                    let walletName = Encryption.sha256hash(descriptor)
                    walletToImport["descriptor"] = descriptor
                    walletToImport["name"] = walletName
                    getChangeDescriptor(changeDesc: changeDesc)
                } else {
                    completion(nil)
                }
            }
        }
        
        func process(node: NodeStruct) {
            walletToImport["derivation"] = descriptorStruct.derivation
            walletToImport["nodeId"] = node.id
            walletToImport["birthdate"] = keyBirthday()
            walletToImport["id"] = UUID()
            walletToImport["isArchived"] = false
            walletToImport["maxRange"] = 2500
            walletToImport["index"] = 0
            walletToImport["blockheight"] = Int32(1)
            walletToImport["lastUsed"] = Date()
            walletToImport["lastBalance"] = 0.0
            walletToImport["nodeIsSigner"] = false
            if descriptorStruct.isHot {
                if descriptorStruct.isMulti {
                    var xprvs:[Data] = []
                    for (i, key) in descriptorStruct.multiSigKeys.enumerated() {
                        if key.hasPrefix("xprv") || key.hasPrefix("tprv") {
                            Encryption.encryptData(dataToEncrypt: key.dataUsingUTF8StringEncoding) { (encryptedData, error) in
                                if encryptedData != nil {
                                    xprvs.append(encryptedData!)
                                } else {
                                    completion(nil)
                                }
                            }
                        }
                        if i + 1 == descriptorStruct.multiSigKeys.count {
                            walletToImport["xprvs"] = xprvs
                        }
                    }
                } else {
                    let xprv = descriptorStruct.accountXprv
                    Encryption.encryptData(dataToEncrypt: xprv.dataUsingUTF8StringEncoding) { (encryptedData, error) in
                        if encryptedData != nil {
                            walletToImport["xprvs"] = [encryptedData!]
                        } else {
                            completion(nil)
                        }
                    }
                }
            }
            
            if descriptorStruct.isHD {
                if descriptorStruct.isMulti {
                    walletToImport["type"] = "MULTI"
                } else {
                    walletToImport["type"] = "DEFAULT"
                }
                /// Here we will need to process the descriptor.
                let changeDesc = updated.replacingOccurrences(of: "/0/*", with: "/1/*")
                getDescriptors(primaryDesc: updated, changeDesc: changeDesc)
            } else {
                print("descriptor type is not supported...")
                completion(nil)
            }
        }
        
        Encryption.getNode { (n, error) in
            if n != nil {
                process(node: n!)
            } else {
                completion(nil)
            }
        }
    }
    
    class func importAccountMap(accountMap: [String:Any], completion: @escaping (([String:Any]?)) -> Void) {
        var walletToImport = [String:Any]()
        
        func getChangeDescriptor(changeDesc: String) {
            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    let changeDescriptor = dict["descriptor"] as! String
                    walletToImport["changeDescriptor"] = changeDescriptor
                    completion(walletToImport)
                } else {
                    completion(nil)
                }
            }
        }
        
        func process(node: NodeStruct) {
            let updated = updatedDesc(accountMap["descriptor"] as! String)
            
            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(updated)\"") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    let p = DescriptorParser()
                    let descriptor = dict["descriptor"] as! String
                    let descStruct = p.descriptor(descriptor)
                    let walletName = Encryption.sha256hash(descriptor)
                    walletToImport["derivation"] = descStruct.derivation
                    walletToImport["name"] = walletName
                    walletToImport["descriptor"] = descriptor
                    walletToImport["nodeId"] = node.id
                    walletToImport["birthdate"] = keyBirthday()
                    walletToImport["id"] = UUID()
                    walletToImport["isArchived"] = false
                    walletToImport["maxRange"] = 2500
                    walletToImport["index"] = 0
                    walletToImport["blockheight"] = accountMap["blockheight"] as! Int32
                    walletToImport["lastUsed"] = Date()
                    walletToImport["lastBalance"] = 0.0
                    walletToImport["label"] = accountMap["label"] as? String ?? ""
                    walletToImport["nodeIsSigner"] = false
                    if descStruct.isMulti {
                        walletToImport["type"] = "MULTI"
                    } else {
                        walletToImport["type"] = "DEFAULT"
                    }
                    var changeDescriptor = descriptor.replacingOccurrences(of: "/0/*", with: "/1/*")
                    let arr = changeDescriptor.split(separator: "#")
                    changeDescriptor = "\(arr[0])"
                    getChangeDescriptor(changeDesc: changeDescriptor)
                } else {
                    completion(nil)
                }
            }
        }
        
        Encryption.getNode { (n, error) in
            if n != nil {
                process(node: n!)
            } else {
                completion(nil)
            }
        }
    }
    
    class func importColdCard(coldcardDict: NSDictionary, fingerprint: String, completion: @escaping (([String:Any]?)) -> Void) {
        var accountToImport = [String:Any]()
        accountToImport["birthdate"] = keyBirthday()
        accountToImport["isArchived"] = false
        accountToImport["blockheight"] = Int32(1)
        accountToImport["maxRange"] = 2500
        accountToImport["index"] = 0
        accountToImport["lastUsed"] = Date()
        accountToImport["lastBalance"] = 0.0
        accountToImport["id"] = UUID()
        accountToImport["type"] = "DEFAULT"
        accountToImport["label"] = "COLDCARD"
        accountToImport["nodeIsSigner"] = false
        
        func getChangeDescriptor(changeDesc: String) {
            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    let changeDescriptor = dict["descriptor"] as! String
                    accountToImport["changeDescriptor"] = changeDescriptor
                    completion(accountToImport)
                } else {
                    completion(nil)
                }
            }
        }
        
        func getDescriptors(primaryDesc: String, changeDesc: String) {
            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryDesc)\"") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    let descriptor = dict["descriptor"] as! String
                    let walletName = Encryption.sha256hash(descriptor)
                    accountToImport["descriptor"] = descriptor
                    accountToImport["name"] = walletName
                    getChangeDescriptor(changeDesc: changeDesc)
                } else {
                    completion(nil)
                }
            }
        }
        
        func process() {
            let xpub = coldcardDict["xpub"] as! String
            let derivation = coldcardDict["deriv"] as! String
            accountToImport["derivation"] = derivation
            let name = coldcardDict["name"] as! String
            var prefix = ""
            /// Only working for single-sig now.
            switch name {
            case "p2pkh": prefix = "pkh("
            case "p2wpkh-p2sh": prefix = "sh(wpkh("
            case "p2wpkh": prefix = "wpkh("
            default:
                break
            }
            let path = derivation.replacingOccurrences(of: "m", with: fingerprint)
            var primDesc = prefix + "[\(path)]\(xpub)/0/*"
            
            if prefix == "sh(wpkh(" {
                primDesc += "))"
            } else {
                primDesc += ")"
            }
            let changeDesc = primDesc.replacingOccurrences(of: "/0/*", with: "/1/*")
            getDescriptors(primaryDesc: primDesc, changeDesc: changeDesc)
        }
        
        Encryption.getNode { (n, error) in
            if n != nil {
                accountToImport["nodeId"] = n!.id
                process()
            } else {
                completion(nil)
            }
        }
    }
    
    class func importColdCardMultiSig(coldcardDict: [String:Any], completion: @escaping ((coldcardWallet: [String:Any]?, offlineWords: String?, deviceWords: String?)) -> Void) {
        var chain:Network!
        var path:BIP32Path!
        var deviceKey = ""
        var nodeKey = ""
        var coldCardKey = ""
        var offlineWords = ""
        var deviceWords = ""
        var accountToImport = [String:Any]()
        accountToImport["birthdate"] = keyBirthday()
        accountToImport["isArchived"] = false
        accountToImport["blockheight"] = Int32(1)
        accountToImport["maxRange"] = 2500
        accountToImport["index"] = 0
        accountToImport["lastUsed"] = Date()
        accountToImport["lastBalance"] = 0.0
        accountToImport["id"] = UUID()
        accountToImport["type"] = "MULTI"
        accountToImport["label"] = "COLDCARD"
        accountToImport["nodeIsSigner"] = false
        
        func getChangeDescriptor(changeDesc: String) {
            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    let changeDescriptor = dict["descriptor"] as! String
                    accountToImport["changeDescriptor"] = changeDescriptor
                    completion((accountToImport, offlineWords, deviceWords))
                } else {
                    completion((nil,nil,nil))
                }
            }
        }
        
        func getDescriptors(primaryDesc: String, changeDesc: String) {
            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryDesc)\"") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    let descriptor = dict["descriptor"] as! String
                    let walletName = Encryption.sha256hash(descriptor)
                    accountToImport["descriptor"] = descriptor
                    accountToImport["name"] = walletName
                    getChangeDescriptor(changeDesc: changeDesc)
                } else {
                    completion((nil,nil,nil))
                }
            }
        }
        
        func getDeviceXpub(mnemonic: BIP39Mnemonic) {
            let seed = mnemonic.seedHex("")
            if let masterKey = HDKey(seed, chain) {
                let fingerprint = masterKey.fingerprint.hexString
                do {
                    let xpub = try masterKey.derive(path).xpub
                    let path1 = (path.description).replacingOccurrences(of: "m", with: fingerprint)
                    deviceKey = "[\(path1)]\(xpub)/0/*"
                } catch {
                    completion((nil,nil,nil))
                }
            } else {
                completion((nil,nil,nil))
            }
        }
        
        func getNodeXpub(mnemonic: BIP39Mnemonic) {
            let seed = mnemonic.seedHex("")
            if let masterKey = HDKey(seed, chain) {
                let fingerprint = masterKey.fingerprint.hexString
                do {
                    let xpub = try masterKey.derive(path).xpub
                    let path1 = (path.description).replacingOccurrences(of: "m", with: fingerprint)
                    nodeKey = "[\(path1)]\(xpub)/0/*"
                } catch {
                    completion((nil,nil,nil))
                }
            } else {
                completion((nil,nil,nil))
            }
        }
        
        func process() {
            let zpub = coldcardDict["p2wsh"] as! String
            let fingerprint = coldcardDict["xfp"] as! String
            let xpub = XpubConverter.convert(extendedKey: zpub)
            let derivation = coldcardDict["p2wsh_deriv"] as! String
            path = BIP32Path(derivation)
            accountToImport["derivation"] = derivation
            KeychainCreator.createKeyChain() { (device_words, error) in
                if device_words != nil {
                    deviceWords = device_words!
                    KeychainCreator.createKeyChain() { (offline_words, error) in
                        if offline_words != nil {
                            offlineWords = offline_words!
                            let deviceMnemonic = BIP39Mnemonic(device_words!)
                            let offlineMnemonic = BIP39Mnemonic(offline_words!)
                            getDeviceXpub(mnemonic: deviceMnemonic!)
                            getNodeXpub(mnemonic: offlineMnemonic!)
                            let path1 = (path.description).replacingOccurrences(of: "m", with: fingerprint)
                            if xpub != nil {
                                coldCardKey = "[\(path1)]\(xpub!)/0/*"
                                let primDesc = "wsh(sortedmulti(2,\(coldCardKey),\(deviceKey),\(nodeKey)))"
                                let changeDesc = primDesc.replacingOccurrences(of: "/0/*", with: "/1/*")
                                getDescriptors(primaryDesc: primDesc, changeDesc: changeDesc)
                            }
                        }
                    }
                }
            }
        }
        Encryption.getNode { (n, error) in
            if n != nil {
                if n!.network == "testnet" {
                    chain = .testnet
                } else {
                    chain = .mainnet
                }
                accountToImport["nodeId"] = n!.id
                process()
            } else {
                completion((nil,nil,nil))
            }
        }
    }
    
    private class func updatedDesc(_ desc: String) -> String {
        var rawDesc = desc
        let p = DescriptorParser()
        var descStruct = p.descriptor(rawDesc)
        
        if rawDesc.contains("#") {
            let rawDescArr = desc.split(separator: "#")
            rawDesc = "\(rawDescArr[0])"
        }
        
        rawDesc = rawDesc.replacingOccurrences(of: "'", with: "h")
        descStruct = p.descriptor(rawDesc)
        
        // Sparrow wallet exports do not include range
        if !rawDesc.contains("/0/*") {
            if descStruct.isMulti {
                for key in descStruct.multiSigKeys {
                    if !key.contains("/0/*") {
                        rawDesc = rawDesc.replacingOccurrences(of: key, with: key + "/0/*")
                    }
                }
            } else {
                if !descStruct.accountXpub.contains("/0/*") {
                    rawDesc = rawDesc.replacingOccurrences(of: descStruct.accountXpub, with: descStruct.accountXpub + "/0/*")
                }
            }
        }
        
        descStruct = p.descriptor(rawDesc)
        
        // If the descriptor is multisig, we sort the keys lexicographically
        if rawDesc.contains(",") {
            var dictArray = [[String:String]]()
            
            for keyWithPath in descStruct.keysWithPath {
                let arr = keyWithPath.split(separator: "]")
                let dict = ["path":"\(arr[0])]", "key": "\(arr[1].replacingOccurrences(of: "))", with: ""))"]
                dictArray.append(dict)
            }
            
            dictArray.sort(by: {($0["key"]!) < $1["key"]!})
            
            var sortedKeys = ""
            
            for (i, sortedItem) in dictArray.enumerated() {
                let path = sortedItem["path"]!
                let key = sortedItem["key"]!
                let fullKey = path + key
                sortedKeys += fullKey
                
                if i + 1 < dictArray.count {
                    sortedKeys += ","
                }
            }
            
            let arr2 = desc.split(separator: ",")
            return "\(arr2[0])," + sortedKeys + "))"
        } else {
            return rawDesc
        }
    }
    
}
