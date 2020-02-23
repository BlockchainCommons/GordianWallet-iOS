//
//  GetPrivateKeys.swift
//  StandUp-Remote
//
//  Created by Peter on 20/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import LibWally

class GetPrivateKeys {
    
    var index = Int()
    //var indexarray = [Int]()
    var pathArray = [BIP32Path]()
    
    func getKeys(addresses: [String], completion: @escaping (([String]?)) -> Void) {
        
        func getAddressInfo(addresses: [String]) {
            
            let reducer = Reducer()
            var privkeyarray = [String]()
            
            func getinfo() {
                
                if !reducer.errorBool {
                    
                    //self.index += 1
                    let result = reducer.dictToReturn
                    
                    if let hdkeypath = result["hdkeypath"] as? String {
                        
                        //let arr = hdkeypath.components(separatedBy: "/")
                        //indexarray.append(Int(arr[1])!)
                        if let path = BIP32Path(hdkeypath) {
                            
                            pathArray.append(path)
                            getAddressInfo(addresses: addresses)
                            
                        } else {
                            
                            print("error converting path")
                            completion((nil))
                            
                        }
                        
                    } else {
                        
                        if let desc = result["desc"] as? String {
                            
//                            let arr = desc.components(separatedBy: "/")
//                            let index = (arr[1].components(separatedBy: "]"))[0]
//                            indexarray.append(Int(index)!)
//                            getAddressInfo(addresses: addresses)
                            print("getprivatekeys.swift what are we doing here??")
                            
                        }
                        
                    }
                        
                } else {
                    
                    print("error getting key path: \(reducer.errorDescription)")
                    completion(nil)
                    
                }
                
            }
            
            if addresses.count > self.index {
                
                getActiveWalletNow { (wallet, error) in
                    
                    if !error && wallet != nil {
                        
                        reducer.makeCommand(walletName: wallet!.name, command: .getaddressinfo, param: "\"\(addresses[self.index])\"", completion: getinfo)
                        
                    }
                    
                }
                
            } else {
                
                print("loop finished")
                // loop is finished get the private keys
                let keyfetcher = KeyFetcher()
                
                for (i, path) in pathArray.enumerated() {
                    
                    //let int = Int(keypathint)
                    
                    keyfetcher.privKey(path: path) { (privKey, error) in
                        
                        if !error {
                            
                            privkeyarray.append(privKey!)
                            
                            if i == self.pathArray.count - 1 {
                                
                                completion(privkeyarray)
                                
                            }
                            
                        } else {
                            
                            print("error getting private key")
                            completion(nil)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        getAddressInfo(addresses: addresses)
        
    }
    
}
