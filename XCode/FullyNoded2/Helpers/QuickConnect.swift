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
    // btcstandup://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233bygtrdertgfd.onion:1309/?label=Node%20Name
    // btcstandup://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233b.onion:1309/?
    // btcstandup://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233b.onion:1309?
    
    func addNode(vc: UIViewController, url: String, completion: @escaping ((success: Bool, errorDesc: String?)) -> Void) {
        
        var host = ""
        var rpcPassword = ""
        var rpcUser = ""
        var label = "StandUp"
        
        if let params = URLComponents(string: url)?.queryItems {
            
            if let hostCheck = URLComponents(string: url)?.host {
                
                if hostCheck != "" {
                    
                    let arr = hostCheck.split(separator: ".")
                    if arr[0].count == 56 {
                        
                        if isValidCharacters("\(arr[0])") {
                            
                            if let portCheck = URLComponents(string: url)?.port {
                                
                                if isValidCharacters(String(portCheck)) {
                                    
                                    host = hostCheck + ":" + String(portCheck)
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
            if let rpcPasswordCheck = URLComponents(string: url)?.password {
                
                if isValidCharacters(rpcPasswordCheck) {
                    
                    rpcPassword = rpcPasswordCheck
                    
                }
                
            }
            
            if let rpcUserCheck = URLComponents(string: url)?.user {
                
                if isValidCharacters(rpcUserCheck) {
                    
                    rpcUser = rpcUserCheck
                    
                }
                
            }
            
            
            if let check = URLComponents(string: url)?.queryItems {
                
                if let labelCheck = (check.first)?.value {
                    
                    var removeAllowedChars = label.replacingOccurrences(of: ".", with: "")
                    removeAllowedChars = removeAllowedChars.replacingOccurrences(of: "%", with: "")
                    removeAllowedChars = removeAllowedChars.replacingOccurrences(of: "-", with: "")
                    removeAllowedChars = removeAllowedChars.replacingOccurrences(of: "_", with: "")
                    
                    if isValidCharacters(removeAllowedChars) {
                        
                        label = labelCheck
                        
                    }
                    
                }
                
            }
            
            if rpcUser == "" && rpcPassword == "" {
                
                if params.count == 2 {
                    
                    rpcUser = (params[0].description).replacingOccurrences(of: "user=", with: "")
                    rpcPassword = (params[1].description).replacingOccurrences(of: "password=", with: "")
                    
                    if rpcPassword.contains("?label=") {
                        
                        let arr = rpcPassword.components(separatedBy: "?label=")
                        rpcPassword = arr[0]
                        
                        if arr.count > 1 {
                            
                            if isValidCharacters("\(arr[1])") {
                                
                                label = arr[1]
                                
                            }
                                                        
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            
            completion((false, "url error"))
            
        }
        
        guard host != "", rpcUser != "", rpcPassword != "" else {
            completion((false, "That is not a valid QuickConnect URI"))
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
                        
                        for node in nodes! {
                            
                            if node ["id"] as! UUID != newNodeID {
                                
                                CoreDataService.updateEntity(id: (node["id"] as! UUID), keyToUpdate: "isActive", newValue: false, entityName: .nodes) {_ in }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        // adding a new node
        if nodeToUpdate == nil {
            
            Encryption.saveNode(newNode: node) { (success, error) in
                
                if error == nil && success {
                    
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
