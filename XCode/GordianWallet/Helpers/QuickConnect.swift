//
//  QuickConnect.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import UIKit

class QuickConnect {

    var nodeToUpdate:UUID!
    
    // MARK: QuickConnect uri examples
    // btcstandup://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233bygtrdertgfd.onion:1309?label=Node%20Name
    // btcstandup://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233b.onion:1309?
    
    func addNode(vc: UIViewController, url: String, completion: @escaping ((success: Bool, errorDesc: String?)) -> Void) {
        var label = "GordianServer"
        
        guard var host = URLComponents(string: url)?.host,
            let port = URLComponents(string: url)?.port,
            let rpcPassword = URLComponents(string: url)?.password,
            let rpcUser = URLComponents(string: url)?.user else {
                completion((false, "invalid url"))
                return
        }
        
        host += ":" + String(port)
        
        if let labelCheck = URL(string: url)?.value(for: "label") {
            label = labelCheck
        }
        
        guard host != "", rpcUser != "", rpcPassword != "" else {
            completion((false, "either the hostname, rpcuser or rpcpassword is empty"))
            return
        }
        
        var node = [String:Any]()
        node["onionAddress"] = host
        node["label"] = label
        node["rpcuser"] = rpcUser
        node["rpcpassword"] = rpcPassword
        
        if nodeToUpdate == nil {
            node["id"] = UUID()
        } else {
            node["id"] = nodeToUpdate
        }
        
        node["isActive"] = true
        
        func deactivate(newNodeID: UUID) {
            
            CoreDataService.retrieveEntity(entityName: .nodes) { (nodes, errorDescription) in
                
                if errorDescription == nil {
                    
                    if nodes!.count > 0 {
                        
                        for (i, node) in nodes!.enumerated() {
                            
                            if node ["id"] as! UUID != newNodeID {
                                
                                CoreDataService.updateEntity(id: (node["id"] as! UUID), keyToUpdate: "isActive", newValue: false, entityName: .nodes) {_ in }
                                
                            }
                            
                            if i + 1 == nodes!.count {
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .nodeSwitched, object: nil, userInfo: nil)
                                }
                            }
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        // adding a new node
        if nodeToUpdate == nil {
            
            Encryption.saveNode(newNode: node) { (success, error) in
                
                if success {
                    
                    print("standup node added")
                    deactivate(newNodeID: node["id"] as! UUID)
                    node.removeAll()
                    completion((true, nil))
                    
                } else {
                    
                    completion((false, "Error adding QuickConnect node: \(error ?? "Error adding QuickConnect node")"))
                    
                }
                
            }
            
        // updating an exisiting node
        } else {
            print("update a node")
            Encryption.updateNode(newCredentials: node, nodeToUpdate: nodeToUpdate) { (success, error) in
                
                if error == nil && success {
                    
                    print("node updated")
                    node.removeAll()
                    completion((true, nil))
                    
                } else {
                    
                    completion((false, "Error updating QuickConnect node: \(error ?? "unknown error")"))
                    
                }
                
            }
            
        }
        
    }
    
}

extension URL {
    
    func value(for paramater: String) -> String? {
        
        let queryItems = URLComponents(string: self.absoluteString)?.queryItems
        let queryItem = queryItems?.filter({$0.name == paramater}).first
        let value = queryItem?.value
        return value
    }
    
}
