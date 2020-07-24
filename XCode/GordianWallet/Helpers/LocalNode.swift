//
//  LocalNode.swift
//  FullyNoded2
//
//  Created by Peter on 27/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class LocalNode {
    
    static let sharedInstance = LocalNode()
    lazy var session = URLSession(configuration: .default)
    
    func command(walletName: String, method: BTC_CLI_COMMAND, param: Any, completion: @escaping ((success: Bool, errorDescription: String?, result: Any?)) -> Void) {
        
        // if you are a dev using this will require commenting out the SceneDelegate.swift tor connection code and
        // the if torConnected statement in didAppear() function on MainMenuViewConotroller.swift
        // You will also need to hardcode in your nodes IP if its a machine name, and rpc creds here
        let nodeIp = "127.0.0.1:18443"
        let rpcusername = "user"
        let rpcpassword = "password"
        var walletUrl = "http://\(rpcusername):\(rpcpassword)@\(nodeIp)"
        
        // no need to add wallet url for non wallet rpc calls
        if isWalletRPC(command: method) {
            
            walletUrl += "/wallet/\(walletName)"
            
        }
        
        // Have to escape ' characters for certain rpc commands
        var formattedParam = (param as! String).replacingOccurrences(of: "''", with: "")
        formattedParam = formattedParam.replacingOccurrences(of: "'\"'\"'", with: "'")
        
        guard let url = URL(string: walletUrl) else {
            completion((false, "url error", nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method)\",\"params\":[\(formattedParam)]}".data(using: .utf8)
        print("request = {\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method)\",\"params\":[\(formattedParam)]}")
        
        let task = self.session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            do {
                
                if error != nil {
                    
                    completion((false, error!.localizedDescription, nil))
                    
                } else {
                    
                    if let urlContent = data {
                        
                        do {
                            
                            let json = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                            
                            if let errorCheck = json["error"] as? NSDictionary {
                                
                                var err = ""
                                
                                if let errorMessage = errorCheck["message"] as? String {
                                    
                                    err = errorMessage
                                    
                                } else {
                                    
                                    err = "Uknown error"
                                    
                                }
                                
                                completion((false, err, nil))
                                
                                
                            } else {
                                
                                completion((true, nil, (json["result"] as Any)))
                                
                            }
                            
                        } catch {
                            
                            completion((false, "error processing json", nil))
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        task.resume()
        
    }
    
}
