//
//  Encryption.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import CryptoKit

class Encryption {
    
    class func sha256hash(_ text: String) -> String {
        let digest = SHA256.hash(data: text.dataUsingUTF8StringEncoding)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    
    }
    
    class func privateKey() -> Data {
        return P256.Signing.PrivateKey().rawRepresentation
        
    }
    
    class func encryptData(dataToEncrypt: Data, completion: @escaping ((encryptedData: Data?, error: Bool)) -> Void) {
        
        if let key = KeyChain.getData("privateKey") {
            
            let k = SymmetricKey(data: key)
            
            if let sealedBox = try? ChaChaPoly.seal(dataToEncrypt, using: k) {
                
                let encryptedData = sealedBox.combined
                completion((encryptedData,false))
                
            } else {
                
                completion((nil,true))
                
            }
            
        }
        
    }
    
    class func decryptData(dataToDecrypt: Data, completion: @escaping ((Data?)) -> Void) {
        
        if #available(iOS 13.0, *) {
            
            if let key = KeyChain.getData("privateKey") {
                
                do {
                    
                    let box = try ChaChaPoly.SealedBox.init(combined: dataToDecrypt)
                    let k = SymmetricKey(data: key)
                    let decryptedData = try ChaChaPoly.open(box, using: k)
                    completion((decryptedData))
                    
                } catch {
                    
                    print("failed decrypting")
                    completion((nil))
                    
                }
                
            }
            
        }
        
    }
    
    class func getNode(completion: @escaping ((node: NodeStruct?, error: Bool)) -> Void) {
        
        if let key = KeyChain.getData("privateKey") {
            
            let pk = SymmetricKey(data: key)
            CoreDataService.retrieveEntity(entityName: .nodes) { (nodes, errorDescription) in
                
                if errorDescription == nil {
                    
                    if nodes!.count > 0 {
                        
                        for node in nodes! {
                            
                            if (node["isActive"] as! Bool) {
                                
                                var decryptedNode = node
                                var loopCount = 0
                                
                                for (k, value) in node {
                                    
                                    if k != "isActive" && k != "id" && k != "network" {
                                        
                                        loopCount += 1
                                        
                                        let dataToDecrypt = value as! Data
                                        
                                        do {
                                            
                                            let box = try ChaChaPoly.SealedBox.init(combined: dataToDecrypt)
                                            let decryptedData = try ChaChaPoly.open(box, using: pk)
                                            if let decryptedValue = String(data: decryptedData, encoding: .utf8) {
                                                
                                                decryptedNode[k] = decryptedValue
                                                
                                                if loopCount == 4 {
                                                    
                                                    // we know there will be 7 keys, so can check the loop has finished here
                                                    let nodeStruct = NodeStruct.init(dictionary: decryptedNode)
                                                    decryptedNode.removeAll()
                                                    completion((nodeStruct,false))
                                                    
                                                }
                                                
                                            } else {
                                                
                                                completion((nil,true))
                                                
                                            }
                                            
                                        } catch {
                                            
                                            print("error decryting node")
                                            completion((nil,true))
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        print("no nodes")
                        completion((nil,true))
                        
                    }
                    
                } else {
                    
                    print("error getting nodes: \(errorDescription!)")
                }
                
            }
            
        } else {
            
            print("private key not accessible")
            completion((nil,true))
            
        }
        
    }
    
    class func saveNode(newNode: [String:Any], completion: @escaping ((success: Bool, error: String?)) -> Void) {
        
        if let key = KeyChain.getData("privateKey") {
            
            let pk = SymmetricKey(data: key)
            var encryptedNode = newNode
            
            func save() {
                
                for (k, value) in newNode {
                    
                    if k != "id" && k != "isActive" && k != "network" {
                        
                        let stringToEncrypt = value as! String
                        
                        if let dataToEncrypt = stringToEncrypt.data(using: .utf8) {
                            
                            if let sealedBox = try? ChaChaPoly.seal(dataToEncrypt, using: pk) {
                                
                                let encryptedData = sealedBox.combined
                                encryptedNode[k] = encryptedData
                                
                            } else {
                                
                                completion((false, "node encryption failed"))
                                
                            }
                            
                        } else {
                            
                            completion((false, "node encryption failed"))
                            
                        }
                        
                    }
                    
                }
                
                CoreDataService.saveEntity(dict: encryptedNode, entityName: .nodes) { (success, errorDesc) in
                    
                    if success {
                        
                        completion((true, nil))
                        
                    } else {
                        
                        completion((false, errorDesc ?? "error saving node"))
                        
                    }
                    
                }
                
            }
            
            CoreDataService.retrieveEntity(entityName: .nodes) { (existingNodes, errorDescription) in
                
                if errorDescription == nil && existingNodes != nil {
                    
                    if existingNodes!.count > 0 {
                        
                        var nodeAlreadyExists = false
                        
                        for (i, n) in existingNodes!.enumerated() {
                            
                            let existingOnionEncrypted = n["onionAddress"] as! Data
                            Encryption.decryptData(dataToDecrypt: existingOnionEncrypted) { (decrpytedOnion) in
                                
                                if decrpytedOnion != nil {
                                    
                                    if (newNode["onionAddress"] as! String) == String(data: decrpytedOnion!, encoding: .utf8) {
                                        
                                        nodeAlreadyExists = true
                                        
                                    }
                                    
                                    if i + 1 == existingNodes!.count {
                                        
                                        if !nodeAlreadyExists {
                                            
                                            save()
                                            
                                        } else {
                                            
                                            completion((false, "node already added"))
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        save()
                        
                    }
                    
                }
                
            }
            
        } else {
            
            completion((false, nil))
            
        }
        
    }
    
    class func updateNode(newCredentials: [String:Any], nodeToUpdate: UUID, completion: @escaping ((success: Bool, error: String?)) -> Void) {
                    
            if let key = KeyChain.getData("privateKey") {
                
                let pk = SymmetricKey(data: key)
                var encryptedNode = newCredentials
                
                for (k, value) in newCredentials {
                    
                    if k != "id" && k != "isActive" && k != "network" {
                        
                        let stringToEncrypt = value as! String
                        
                        if let dataToEncrypt = stringToEncrypt.data(using: .utf8) {
                            
                            if let sealedBox = try? ChaChaPoly.seal(dataToEncrypt, using: pk) {
                                
                                let encryptedData = sealedBox.combined
                                encryptedNode[k] = encryptedData
                                
                            } else {
                                
                                completion((false, "node encryption failed"))
                                
                            }
                            
                        } else {
                            
                            completion((false, "node encryption failed"))
                            
                        }
                        
                    }
                    
                }
                
                CoreDataService.updateNode(nodeToUpdate: nodeToUpdate, newCredentials: encryptedNode) { (success, errorDesc) in
                    
                    if success {
                        
                        completion((true, nil))
                        
                    } else {
                        
                        completion((false, nil))
                        
                    }
                    
                }
                
            } else {
                
                completion((false, nil))
                
            }
        
    }
    
}
