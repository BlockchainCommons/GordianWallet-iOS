//
//  FiatConverter.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class FiatConverter {
    
    var torClient:TorClient!
    var fxRate = Double()
    var errorBool = Bool()
    
    // MARK: TODO Find an onion api that returns bitcoin price data, not so easy... Using ExcludeExitNodes prevents the below method from working.
    
    func getFxRate(completion: @escaping () -> Void) {
        
        torClient = TorClient.sharedInstance
        
        var url:NSURL!
        url = NSURL(string: "http://blkchairbknpn73cfjhevhla7rkp4ed5gg2knctvv7it4lioy22defid.onion/www/bitcoin/stats")
        //url = NSURL(string: "http://blockchairt5d4pj.onion/www/bitcoin/stats")
        
        let task = torClient.session.dataTask(with: url! as URL) { (data, response, error) -> Void in
            
            do {
                
                if error != nil {
                    
                    self.errorBool = true
                    completion()
                    
                } else {
                    
                    if let urlContent = data {
                                                
                        do {
                            
                            if let json = try JSONSerialization.jsonObject(with: urlContent, options: [.mutableContainers]) as? [String : Any] {
                             
                                if let data = json["data"] as? NSDictionary {
                                    
                                    if let rateCheck = data["market_price_usd"] as? Double {
                                            
                                            self.errorBool = false
                                            self.fxRate = rateCheck
                                            completion()
                                                                                
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
