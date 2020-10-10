//
//  TransactionFetcher.swift
//  FullyNoded2
//
//  Created by Peter on 28/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class TransactionFetcher {
    
    static let sharedInstance = TransactionFetcher()
    lazy var torClient = TorClient.sharedInstance
    
    func fetch(txid: String, completion: @escaping ((String?)) -> Void) {
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            if node != nil {
                
                var blockstreamUrl = "http://explorerzydxu5ecjrkwceayqybizmpjjznk5izmitf2modhcusuqlid.onion/api/tx/\(txid)/hex"
                
                if node!.network == "testnet" {
                    blockstreamUrl = "http://explorerzydxu5ecjrkwceayqybizmpjjznk5izmitf2modhcusuqlid.onion/testnet/api/tx/\(txid)/hex"
                }
                
                guard let url = URL(string: blockstreamUrl) else {
                    completion((nil))
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                
                let task = vc.torClient.session.dataTask(with: request as URLRequest) { (data, response, error) in
                    if error != nil {
                        completion(nil)
                    } else {
                        guard let urlContent = data, let hex = String(bytes: urlContent, encoding: .utf8) else {
                            completion(nil)
                            return
                        }
                        completion(hex)
                    }
                }
                
                task.resume()
            } else {
                completion(nil)
            }
        }
    }
}
