//
//  Import.swift
//  FullyNoded2
//
//  Created by Peter on 30/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

///     An example descriptor from Specter, we need to convert it to HD and create the change descriptor:
///     Key_123&wsh(sortedmulti(2,[fe23bc9a/48h/1h/0h/2h]tpubDEzBBGMH87CU5rCdo7gSaByN6SVvJW7c4WDkMuC6mKS8bcqpaVD3FCoiAEefcGhC4TwRCtACZnmnTZbPUk4cbx6dsLnHG8CyG8jz2Gr6j2z,
///     [e120e47b/48h/1h/0h/2h]tpubDEvTHKHDhi8rQyogJNsnoNsbF8hMefbAzXFCT8CuJiZtxeZM7vUHcH65qpsp7teB2hJPQMKpLV9QcEJkNy3fvnvR6zckoN1E3fFywzfmcBA,
///     [f0578536/48h/1h/0h/2h]tpubDE5GYE61m5mx2WrgtFe1kSAeAHT5Npoy5C2TpQTQGLTQkRkmsWMoA5PSP5XAkt4DBLgKY386iyGDjJKT5fVrRgShJ5CSEdd66UUc4icA8rw))

import Foundation

class Import {
    
    class func importDescriptor(descriptor: String, completion: @escaping (([String:Any]?)) -> Void) {
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
        
        func importSpecterWallet() {
            /// TODO: Support any type of m of n from Specter. Need to puzzle UI first.
            let arr = descriptor.split(separator: "&")
            let label = "\(arr[0])"
            var primaryDesc = "\(arr[1])"
            let arr1 = primaryDesc.split(separator: ",")
            let key1 = "\(arr1[1])/0/*"
            let key2 = "\(arr1[2])/0/*"
            let key3 = "\(arr1[3])".replacingOccurrences(of: "))", with: "/0/*))")
            primaryDesc = primaryDesc.replacingOccurrences(of: "\(arr1[1])", with: key1)
            primaryDesc = primaryDesc.replacingOccurrences(of: "\(arr1[2])", with: key2)
            primaryDesc = primaryDesc.replacingOccurrences(of: "\(arr1[3])", with: key3)
            let changeDesc = primaryDesc.replacingOccurrences(of: "/0/*", with: "/1/*")
            walletToImport["label"] = label
            getDescriptors(primaryDesc: primaryDesc, changeDesc: changeDesc)
            
        }
        
        func process(node: NodeStruct) {
            let p = DescriptorParser()
            let str = p.descriptor(descriptor)
            walletToImport["derivation"] = str.derivation
            walletToImport["nodeId"] = node.id
            walletToImport["birthdate"] = keyBirthday()
            walletToImport["id"] = UUID()
            walletToImport["isArchived"] = false
            walletToImport["maxRange"] = 2500
            walletToImport["index"] = 0
            walletToImport["blockheight"] = 1
            walletToImport["lastUsed"] = Date()
            walletToImport["lastBalance"] = 0.0
            
            if str.isSpecter && str.mOfNType == "2 of 3" {
                walletToImport["type"] = "MULTI"
                importSpecterWallet()
                
            } else if str.isHD {
                
                if str.isMulti {
                    walletToImport["type"] = "MULTI"
                    
                } else {
                    walletToImport["type"] = "DEFAULT"
                    
                }
                
                /// Here we will need to process the descriptor.
                
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
            let descriptor = accountMap["descriptor"] as! String
            let p = DescriptorParser()
            let str = p.descriptor(descriptor)
            let walletName = Encryption.sha256hash(descriptor)
            walletToImport["derivation"] = str.derivation
            walletToImport["name"] = walletName
            walletToImport["descriptor"] = descriptor
            walletToImport["nodeId"] = node.id
            //walletToImport["birthdate"] = accountMap["birthdate"] as! Int32
            walletToImport["id"] = UUID()
            walletToImport["isArchived"] = false
            walletToImport["maxRange"] = 2500
            walletToImport["index"] = 0
            walletToImport["blockheight"] = accountMap["blockheight"] as! Int32
            walletToImport["lastUsed"] = Date()
            walletToImport["lastBalance"] = 0.0
            walletToImport["label"] = accountMap["label"] as? String ?? ""
            
            if str.isMulti {
                walletToImport["type"] = "MULTI"
                
            } else {
                walletToImport["type"] = "DEFAULT"
                
            }
            
            var changeDescriptor = descriptor.replacingOccurrences(of: "/0/*", with: "/1/*")
            let arr = changeDescriptor.split(separator: "#")
            changeDescriptor = "\(arr[0])"
            getChangeDescriptor(changeDesc: changeDescriptor)
            
        }
        
        Encryption.getNode { (n, error) in
            
            if n != nil {
                process(node: n!)
                
            } else {
                completion(nil)
                
            }
        }
        
    }
    
}
