//
//  FiatConverter.swift
//  FullyNoded2
//
//  Created by Peter on 20/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class FiatConverter {
    
    static let sharedInstance = FiatConverter()
    let priceServer = PriceServer()
    
    private init() {}
    
    func getFxRate(completion: @escaping ((Double?)) -> Void) {
        let spotbitURL = priceServer.createSpotBitURL()
        let torClient = TorClient.sharedInstance
        let url = NSURL(string: spotbitURL)
        
        let task = torClient.session.dataTask(with: url! as URL) { (data, response, error) -> Void in
            do {
                
                guard let urlContent = data,
                    let json = try? JSONSerialization.jsonObject(with: urlContent, options: [.mutableContainers]) as? [String : Any] else {
                        completion(nil)
                        return
                }
                
                #if DEBUG
                print("json = \(json)")
                #endif
                
                if let data = json["close"] as? Double {
                    completion(data)
                    
                } else if let data = json["USD"] as? NSDictionary {
                    if let rateCheck = data["15m"] as? Double {
                        completion(rateCheck)
                    }
                    
                } else {
                    completion(nil)
                }
                
            }
            
        }
        
        task.resume()
        
    }
    
}
