//
//  Broadcast.swift
//  FullyNoded2
//
//  Created by Peter on 03/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class Broadcaster {
    
    static let sharedInstance = Broadcaster()
    lazy var torClient = TorClient.sharedInstance
    
    func send(rawTx: String, completion: @escaping ((String?)) -> Void) {
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if node != nil {
                var blockstreamUrl = "http://explorerzydxu5ecjrkwceayqybizmpjjznk5izmitf2modhcusuqlid.onion/api/tx"
                
                if node!.network == "testnet" {
                    blockstreamUrl = "http://explorerzydxu5ecjrkwceayqybizmpjjznk5izmitf2modhcusuqlid.onion/testnet/api/tx"
                    
                }
                guard let url = URL(string: blockstreamUrl) else {
                    completion((nil))
                    return
                    
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = rawTx.data(using: .utf8)
                let task = vc.torClient.session.dataTask(with: request as URLRequest) { (data, response, error) in
                    
                    if error != nil {
                        completion(nil)
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            if let txid = String(bytes: urlContent, encoding: .utf8) {
                                completion(txid)
                                
                            }
                        }
                    }
                }
                task.resume()
                
            } else {
                completion(nil)
                
            }
        }
    }
}
