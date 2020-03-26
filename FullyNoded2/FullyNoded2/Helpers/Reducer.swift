//
//  Reducer.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class Reducer {
    
    lazy var session = URLSession(configuration: .default)
    let torRPC = MakeRPCCall.sharedInstance
    var dictToReturn:NSDictionary?
    var doubleToReturn:Double?
    var arrayToReturn:NSArray?
    var stringToReturn:String?
    var boolToReturn:Bool?
    var errorBool = Bool()
    var errorDescription = ""
    
    var method = ""
    
    func makeCommand(walletName: String, command: BTC_CLI_COMMAND, param: Any, completion: @escaping () -> Void) {
        
        method = command.rawValue
        
        func parseResponse(response: Any) {
            
            if let str = response as? String {
                
                self.stringToReturn = str
                completion()
                
            } else if let doub = response as? Double {
                
                self.doubleToReturn = doub
                completion()
                
            } else if let arr = response as? NSArray {
                
                self.arrayToReturn = arr
                completion()
                
            } else if let dic = response as? NSDictionary {
                
                self.dictToReturn = dic
                completion()
                
            } else {
                
                if command == .walletpassphrase {
                    
                    self.stringToReturn = "Wallet decrypted"
                    completion()
                    
                } else if command == .walletpassphrasechange {
                    
                    self.stringToReturn = "Passphrase updated"
                    completion()
                    
                } else if command == .encryptwallet || command == .walletlock {
                    
                    self.stringToReturn = "Wallet encrypted"
                    completion()
                    
                }
                
            }
            
        }
        
        func torCommand() {
            
            print("tor")
            
            func getResult() {
                
                if !torRPC.errorBool {
                    
                    let response = torRPC.objectToReturn
                    parseResponse(response: response as Any)
                    
                } else {
                    
                    print("torRPC.errorDescription = \(torRPC.errorDescription)")
                    
                    if torRPC.errorDescription.contains("Requested wallet does not exist or is not loaded") {
                        
                        errorDescription = ""
                        errorBool = false
                        
                        torRPC.executeRPCCommand(walletName: walletName, method: .loadwallet, param: "\"\(walletName)\"") {
                            
                            if !self.torRPC.errorBool {
                                
                                self.torRPC.executeRPCCommand(walletName: walletName, method: command,
                                                              param: param,
                                                              completion: getResult)
                                
                            } else {
                                
                                self.errorBool = true
                                self.errorDescription = "Wallet does not exist, maybe your node changed networks?"
                                completion()
                                
                            }
                            
                        }
                        
                    } else if torRPC.errorDescription.contains("Could not connect to server") {
                        
                        print("restarting tor")
                        
                        let mgr = TorClient.sharedInstance
                        mgr.resign()
                        
                        mgr.start(delegate: nil) {
                            
                            self.torRPC.executeRPCCommand(walletName: walletName, method: command,
                                                          param: param,
                                                          completion: getResult)
                            
                        }
                                                
                    } else {
                        
                        errorBool = true
                        errorDescription = torRPC.errorDescription
                        completion()
                        
                    }
                
                    
                }
                
            }
            
            if TorClient.sharedInstance.state == .connected {
                
                torRPC.executeRPCCommand(walletName: walletName, method: command,
                                         param: param,
                                         completion: getResult)
                
            } else {
                
                // this is for dev environment only... can be the begginings of mac app
                tryLocalHost(walletName: walletName, method: command, param: param, completion: completion)
                errorBool = true
                errorDescription = "tor not connected"
                
            }
            
        }
        
        func tryLocalHost(walletName: String, method: BTC_CLI_COMMAND, param: Any, completion: @escaping () -> Void) {
            print("tryLocalHost")
            
            // if you are a dev using this will require commenting out the SceneDelegate.swift tor connection code and
            // the if torConnected statement in didAppear() function on MainMenuViewConotroller.swift
            //
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
                self.errorBool = true
                self.errorDescription = "url error"
                completion()
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method)\",\"params\":[\(formattedParam)]}".data(using: .utf8)
            print("request = {\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method)\",\"params\":[\(formattedParam)]}")
            let queue = DispatchQueue(label: "com.FullyNoded.torQueue")
            queue.async {
                
                let task = self.session.dataTask(with: request as URLRequest) { (data, response, error) in
                    
                    do {
                        
                        if error != nil {
                            
                            self.errorBool = true
                            print("error description = \(error!.localizedDescription)")
                            self.errorDescription = error!.localizedDescription
                            completion()
                            
                        } else {
                            
                            if let urlContent = data {
                                
                                do {
                                    
                                    let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                    
                                    if let errorCheck = jsonAddressResult["error"] as? NSDictionary {
                                        
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
                                        parseResponse(response: jsonAddressResult["result"] as Any)
                                        
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
            
        }
        
        torRPC.errorBool = false
        torRPC.errorDescription = ""
        torCommand()
        
    }
    
}
