//
//  MakeRPCCall.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class MakeRPCCall {
    
    static let sharedInstance = MakeRPCCall()
    lazy var torClient = TorClient.sharedInstance
    lazy var ud = UserDefaults.standard
    lazy var attempts = 0
    
    private init() {}
    
    func executeRPCCommand(walletName: String, method: BTC_CLI_COMMAND, param: Any, completion: @escaping ((success: Bool, objectToReturn: Any?, errorDesc: String?)) -> Void) {
        
        attempts += 1
        let enc = Encryption.sharedInstance
        enc.getNode { [unowned vc = self] (node, error) in
            
            if !error {
                
                let onionAddress = node!.onionAddress
                let rpcusername = node!.rpcuser
                let rpcpassword = node!.rpcpassword
                var walletUrl = "http://\(rpcusername):\(rpcpassword)@\(onionAddress)"
                
                // no need to add wallet url for non wallet rpc calls
                if isWalletRPC(command: method) {
                    
                    walletUrl += "/wallet/\(walletName)"
                    
                }
                
                // Have to escape ' characters for certain rpc commands
                var formattedParam = (param as! String).replacingOccurrences(of: "''", with: "")
                formattedParam = formattedParam.replacingOccurrences(of: "'\"'\"'", with: "'")
                
                guard let url = URL(string: walletUrl) else {
                    completion((false, nil, "url error"))
                    return
                }
                
                #if DEBUG
                print("url = \(url)")
                #endif
                
                var request = URLRequest(url: url)
                var timeout = 10.0
                if method == .importmulti {
                    timeout = 100.0
                }
                request.timeoutInterval = timeout
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method)\",\"params\":[\(formattedParam)]}".data(using: .utf8)
                #if DEBUG
                print("request = {\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method)\",\"params\":[\(formattedParam)]}")
                #endif
                let queue = DispatchQueue(label: "com.FullyNoded.torQueue")
                queue.async {
                    
                    let task = vc.torClient.session.dataTask(with: request as URLRequest) { (data, response, error) in
                        
                        do {
                            
                            if error != nil {
                                
                                // attempt a node command 20 times to avoid user having to tap refresh button
                                if vc.attempts < 20 {
                                        
                                    vc.executeRPCCommand(walletName: walletName, method: method, param: param, completion: completion)
                                                                            
                                } else {
                                    
                                    vc.attempts = 0
                                    #if DEBUG
                                    print("error description = \(error!.localizedDescription)")
                                    #endif
                                    completion((false, nil, error!.localizedDescription))
                                    
                                }
                                
                            } else {
                                
                                vc.attempts = 0
                                
                                if let urlContent = data {
                                    
                                    do {
                                        
                                        let json = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                        
                                        #if DEBUG
                                        print("response = \(json)")
                                        #endif
                                                                                
                                        if let errorCheck = json["error"] as? NSDictionary {
                                            
                                            completion((false, nil, errorCheck["message"] as? String ?? "unknown error"))
                                            
                                        } else {
                                            
                                            completion((true, json["result"], nil))
                                            
                                        }
                                        
                                    } catch {
                                        
                                        completion((false, nil, "unknown error"))
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                    task.resume()
                    
                }
                
            } else {
                
                completion((false, nil, "error fetching node credentials"))
                
            }
            
        }
        
    }
    
}
