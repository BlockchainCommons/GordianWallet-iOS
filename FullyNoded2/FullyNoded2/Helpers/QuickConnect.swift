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
    
    let enc = Encryption()
    var errorBool = Bool()
    var errorDescription = ""
    
    // MARK: QuickConnect uri examples
    // btcstandup://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233bygtrdertgfd.onion:1309/?label=Node%20Name
    // btcstandup://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233b.onion:1309/?
    // btcstandup://rpcuser:rpcpassword@uhqefiu873h827h3ufnjecnkajbciw7bui3hbuf233b.onion:1309?
    
    func addNode(vc: UIViewController, url: String, completion: @escaping () -> Void) {
        
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
                
            } else {
                
                let url = URL(string: url)
                
                if let labelCheck = url?.value(for: "label") {
                    
                    var removeAllowedChars = labelCheck.replacingOccurrences(of: ".", with: "")
                    removeAllowedChars = removeAllowedChars.replacingOccurrences(of: "-", with: "")
                    removeAllowedChars = removeAllowedChars.replacingOccurrences(of: "_", with: "")
                    
                    if isValidCharacters(removeAllowedChars) {
                        
                        label = labelCheck
                        
                    }
                    
                }
                
            }
            
        } else {
            
            self.errorBool = true
            completion()
            
        }
        
        guard host != "", rpcUser != "", rpcPassword != "" else {
            self.errorBool = true
            self.errorDescription = "That is not a valid QuickConnect URI"
            completion()
            return
        }
        
        var node = [String:Any]()
        node["onionAddress"] = host
        node["label"] = label
        node["rpcuser"] = rpcUser
        node["rpcpassword"] = rpcPassword
        node["id"] = UUID()
        node["isActive"] = true
        
        func deactivate(newNodeID: UUID) {
            
            let cd = CoreDataService()
            cd.retrieveEntity(entityName: .nodes) { (nodes, errorDescription) in
                
                if errorDescription == nil {
                    
                    if nodes!.count > 0 {
                        
                        for node in nodes! {
                            
                            if node ["id"] as! UUID != newNodeID {
                                
                                cd.updateEntity(id: (node["id"] as! UUID), keyToUpdate: "isActive", newValue: false, entityName: .nodes) {}
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
                    
        self.enc.saveNode(newNode: node) { (success, error) in
            
            if error == nil && success {
                
                print("standup node added")
                self.errorBool = false
                deactivate(newNodeID: node["id"] as! UUID)
                node.removeAll()
                completion()
                
            } else {
                
                self.errorBool = true
                
                if error != nil {
                    
                    self.errorDescription = "Error adding QuickConnect node: \(error!)"
                    completion()
                    
                } else {
                    
                    self.errorDescription = "Error adding QuickConnect node"
                    completion()
                    
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
