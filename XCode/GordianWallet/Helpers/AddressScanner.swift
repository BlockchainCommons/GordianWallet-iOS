//
//  AddressScanner.swift
//  GordianWallet
//
//  Created by Peter on 28/07/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class AddressScanner {
    static let sharedInstance = AddressScanner()
    lazy var torClient = TorClient.sharedInstance

     func scan(address: String, completion: @escaping ((Bool?)) -> Void) {
        Encryption.getNode { [unowned vc = self] (node, error) in
            if node != nil {
                var blockstreamUrl = "http://explorerzydxu5ecjrkwceayqybizmpjjznk5izmitf2modhcusuqlid.onion/api/address/"
                if node!.network == "testnet" {
                    blockstreamUrl = "http://explorerzydxu5ecjrkwceayqybizmpjjznk5izmitf2modhcusuqlid.onion/testnet/api/address/"
                }
                blockstreamUrl += address
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
                        if let urlContent = data {
                            do {
                                let dict = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                if let chainStats = dict["chain_stats"] as? NSDictionary {
                                    if let txCount = chainStats["tx_count"] as? Int {
                                        if txCount > 0 {
                                            completion(true)
                                        } else {
                                            completion(false)
                                        }
                                    }
                                }
                            } catch {
                                completion(nil)
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
