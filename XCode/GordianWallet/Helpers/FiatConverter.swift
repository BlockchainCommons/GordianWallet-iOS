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
    private init() {}
    
    func getFxRate(completion: @escaping ((Double?)) -> Void) {
        
        UserDefaults.standard.set("http://km3danfmt7aiqylbq5lhyn53zhv2hhbmkr6q5pjc64juiyuxuhcsjwyd.onion/now/", forKey: "spotbitURL")
        UserDefaults.standard.set("AUD", forKey: "currentCurrency")
        UserDefaults.standard.set("binance", forKey: "currentExchange")
        
        let spotbitURL = UserDefaults.standard.string(forKey: "spotbitURL")! + UserDefaults.standard.string(forKey: "currentCurrency")! + "/" + UserDefaults.standard.string(forKey: "currentExchange")!
        
        let torClient = TorClient.sharedInstance
        let url = NSURL(string: spotbitURL)
        
        let task = torClient.session.dataTask(with: url! as URL) { (data, response, error) -> Void in
            
            do {
                
                if error != nil {
                    
                    completion(nil)
                    
                } else {
                    
                    if let urlContent = data {
                                                
                        do {
                            
                            if let json = try JSONSerialization.jsonObject(with: urlContent, options: [.mutableContainers]) as? [String : Any] {
                                
                                #if DEBUG
                                print("json = \(json)")
                                #endif
                             
                                if let data = json["close"] as? Double {
                                    
                                            completion(data)
                                    
                                }
                                
                            }
                            
                        } catch {
                            
                            print("JSon processing failed")
                            completion(nil)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        task.resume()
        
    }
    
}
