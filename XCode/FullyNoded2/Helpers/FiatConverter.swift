//
//  FiatConverter.swift
//  FullyNoded2
//
//  Created by Peter on 20/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class FiatConverter {
        
    // MARK: TODO Find an onion api that returns bitcoin price data, not so easy... Using ExcludeExitNodes or OnionTrafficOnly prevents the below method from working.
    
    static let sharedInstance = FiatConverter()
    private init() {}
    
    func getFxRate(completion: @escaping ((Double?)) -> Void) {
        
        let torClient = TorClient.sharedInstance
        let url = NSURL(string: "https://blockchain.info/ticker")
        
        let task = torClient.session.dataTask(with: url! as URL) { (data, response, error) -> Void in
            
            do {
                
                if error != nil {
                    
                    completion(nil)
                    
                } else {
                    
                    if let urlContent = data {
                                                
                        do {
                            
                            if let json = try JSONSerialization.jsonObject(with: urlContent, options: [.mutableContainers]) as? [String : Any] {
                                
                                print("json = \(json)")
                             
                                if let data = json["USD"] as? NSDictionary {
                                    
                                    if let rateCheck = data["15m"] as? Double {
                                            
                                            completion(rateCheck)
                                                                                
                                    }
                                    
                                }
                                
                            }
                            
                        } catch {
                            
                            print("JSon processing failed")
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        task.resume()
        
    }
    
}
