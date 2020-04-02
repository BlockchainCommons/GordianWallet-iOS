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
    let torClient = TorClient.sharedInstance
    let ud = UserDefaults.standard
    var errorBool = Bool()
    var errorDescription = String()
    var objectToReturn:Any!
    var attempts = 0
    
    func executeRPCCommand(walletName: String, method: BTC_CLI_COMMAND, param: Any, completion: @escaping () -> Void) {
        
        attempts += 1
        let enc = Encryption()
        enc.getNode { (node, error) in
            
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
                    self.errorBool = true
                    self.errorDescription = "url error"
                    completion()
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
                    
                    let task = self.torClient.session.dataTask(with: request as URLRequest) { (data, response, error) in
                        
                        do {
                            
                            if error != nil {
                                
                                // attempt a node command 20 times to avoid user having to tap refresh button
                                if self.attempts < 20 {
                                        
                                    self.executeRPCCommand(walletName: walletName, method: method, param: param, completion: completion)
                                                                            
                                } else {
                                    
                                    self.attempts = 0
                                    self.errorBool = true
                                    #if DEBUG
                                    print("error description = \(error!.localizedDescription)")
                                    #endif
                                    self.errorDescription = error!.localizedDescription
                                    completion()
                                    
                                }
                                
                            } else {
                                
                                self.attempts = 0
                                
                                if let urlContent = data {
                                    
                                    do {
                                        
                                        let json = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                        
                                        #if DEBUG
                                        print("response = \(json)")
                                        #endif
                                                                                
                                        if let errorCheck = json["error"] as? NSDictionary {
                                            
                                            if let errorMessage = errorCheck["message"] as? String {
                                                
                                                self.errorDescription = errorMessage
                                                
                                            } else {
                                                
                                                self.errorDescription = "Uknown error"
                                                
                                            }
                                            
                                            self.errorBool = true
                                            completion()
                                            
                                            
                                        } else {
                                            
                                            self.errorBool = false
                                            self.errorDescription = ""
                                            self.objectToReturn = json["result"]
                                            completion()
                                            
                                        }
                                        
                                    } catch {
                                        
                                        self.errorBool = true
                                        self.errorDescription = "Uknown Error"
                                        completion()
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                    task.resume()
                    
                }
                
            } else {
                
                self.errorBool = true
                self.errorDescription = "error fetching node credentials"
                completion()
                
            }
            
        }
        
    }
    
    private init() {}
    
}
