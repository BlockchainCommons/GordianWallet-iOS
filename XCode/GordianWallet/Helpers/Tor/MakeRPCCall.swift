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
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if !error {
                
                let onionAddress = node!.onionAddress
                let rpcusername = node!.rpcuser
                let rpcpassword = node!.rpcpassword
                var walletUrl = "http://\(rpcusername):\(rpcpassword)@\(onionAddress)"
                
                func makeCommand() {
                    
                    /// Have to escape ' characters for certain rpc commands
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
                    request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method.description)\",\"params\":[\(formattedParam)]}".data(using: .utf8)
                    
                    #if DEBUG
                    print("request = {\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method.description)\",\"params\":[\(formattedParam)]}")
                    #endif
                        
                    let task = vc.torClient.session.dataTask(with: request as URLRequest) { (data, response, error) in
                        
                        do {
                            
                            if error != nil {
                                
                                /// attempt a node command 20 times to avoid user having to tap refresh button
                                if vc.attempts < 20 && method != .listunspent {
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
                
                /// We check to make sure the wallet we are making a command to is the one we are expecting, if not ALL STOP.
                
                /// no need to add wallet url for non wallet rpc calls
                if isWalletRPC(command: method) {
                    walletUrl += "/wallet/\(walletName)"
                    
                    getActiveWalletNow { (wallet, error) in
                        
                        if wallet != nil {
                            
                            /// This method (for sweeping to) gets a receive address from one of the inactive wallets so we bypass the active wallet name hash
                            /// and instead check it against itself using the wallet name as the wallet identifier
                            if method == .getsweeptoaddress {
                                
                                CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                                    
                                    if wallets != nil {
                                        
                                        var hash = ""
                                        
                                        for (i, w) in wallets!.enumerated() {
                                            
                                            let str = WalletStruct(dictionary: w)
                                            
                                            if w["name"] != nil && w["id"] != nil && w["isArchived"] != nil {
                                                
                                                if str.name! == walletName {
                                                    
                                                    hash = Encryption.sha256hash(str.descriptor)
                                                    
                                                }
                                            }
                                            
                                            if i + 1 == wallets!.count {
                                                
                                                guard hash == walletName else {
                                                    completion((false, nil, "the hash of your descriptor does not match the wallet name!"))
                                                    return
                                                    
                                                }
                                                
                                                makeCommand()
                                                
                                            }
                                        }
                                    }
                                }
                                
                                /// These commands are only ever used to fetch balances of inactive wallets on the wallets view table, it is safe to just fetch them
                            } else if method == .fetchexternalbalances || method == .getexternalwalletinfo || method == .importmulti || method == .rescanblockchain || method == .abortrescan {
                                makeCommand()
                                
                            } else {
                                
                                /// These are normal commands to the active wallet
                                let expectedSha = Encryption.sha256hash(wallet!.descriptor)
                                
                                guard expectedSha == walletName else {
                                    completion((false, nil, "the hash of your descriptor does not match the wallet name!"))
                                    return
                                    
                                }
                                
                                makeCommand()
                                
                            }
                            
                        } else {
                            
                            /// These are the possible wallet commands with no active wallet (e.g. recovery and wallet creation)
                            if method == .fetchexternalbalances || method == .getexternalwalletinfo || method == .importmulti || method == .rescanblockchain  {
                                makeCommand()
                                
                            } else {
                                completion((false, nil, "we could not get the active wallet, something unexpected went wrong"))
                                
                            }                            
                        }
                    }
                    
                } else {
                    makeCommand()
                    
                }
                                    
            } else {
                completion((false, nil, "error fetching node credentials"))
                
            }
            
        }
        
    }
    
    /// this command exists for the exlicit purpose of sweeping a wallet to a wallet that does not extist on the current active node
    func externalNodeCommand(node: [String:Any], walletName: String, method: BTC_CLI_COMMAND, param: Any, completion: @escaping ((success: Bool, objectToReturn: Any?, errorDesc: String?)) -> Void) {
        print("externalNodeCommand")
        
        attempts += 1
                            
        let encryptedOnionAddress = node["onionAddress"] as! Data
        let encryptedRpcUsername = node["rpcuser"] as! Data
        let encryptedRpcPassword = node["rpcpassword"] as! Data
        
        Encryption.decryptData(dataToDecrypt: encryptedOnionAddress) { onionAddress in
            Encryption.decryptData(dataToDecrypt: encryptedRpcUsername) { rpcUsername in
                Encryption.decryptData(dataToDecrypt: encryptedRpcPassword) { [unowned vc = self] rpcPassword in
                    
                    if onionAddress != nil && rpcUsername != nil && rpcPassword != nil {
                        
                        let rpcuser = String(data: rpcUsername!, encoding: .utf8) ?? ""
                        let rpcpass = String(data: rpcPassword!, encoding: .utf8) ?? ""
                        let onion = String(data: onionAddress!, encoding: .utf8) ?? ""
                        
                        var walletUrl = "http://\(rpcuser):\(rpcpass)@\(onion)"
                        
                        func makeCommand() {
                            
                            guard let url = URL(string: walletUrl) else {
                                completion((false, nil, "url error"))
                                return
                            }
                            
                            #if DEBUG
                            print("url = \(url)")
                            #endif
                            
                            var request = URLRequest(url: url)
                            request.timeoutInterval = 10.0
                            request.httpMethod = "POST"
                            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                            request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method.description)\",\"params\":[\(param)]}".data(using: .utf8)
                            
                            #if DEBUG
                            print("request = {\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(method.description)\",\"params\":[\(param)]}")
                            #endif
                                
                            let task = vc.torClient.session.dataTask(with: request as URLRequest) { (data, response, error) in
                                
                                do {
                                    
                                    if error != nil {
                                        
                                        /// attempt a node command 20 times to avoid user having to tap refresh button
                                        if vc.attempts < 20 {
                                            
                                            vc.externalNodeCommand(node: node, walletName: walletName, method: method, param: param, completion: completion)
                                            
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
                        
                        /// no need to add wallet url for non wallet rpc calls
                        if isWalletRPC(command: method) {
                            walletUrl += "/wallet/\(walletName)"
                            
                            getActiveWalletNow { (wallet, error) in
                                
                                if wallet != nil {
                                    
                                    /// We check to make sure the wallet we are making a command to is the one we are expecting, if not ALL STOP.
                                    if method == .getsweeptoaddress {
                                        
                                        /// This method (for sweeping to) gets a receive address from one of the inactive wallets so we bypass the active wallet name hash
                                        /// and instead check it against itself using the wallet name as the wallet identifier
                                        CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                                            
                                            if wallets != nil {
                                                
                                                for (i, w) in wallets!.enumerated() {
                                                    
                                                    var hash = ""
                                                    let str = WalletStruct(dictionary: w)
                                                    
                                                    if str.name != nil {
                                                        
                                                        if str.name! == walletName {
                                                            
                                                            hash = Encryption.sha256hash(str.descriptor)
                                                            
                                                        }
                                                    }
                                                    
                                                    if i + 1 == wallets!.count {
                                                        
                                                        guard hash == walletName else {
                                                            completion((false, nil, "the hash of your descriptor does not match the wallet name!"))
                                                            return
                                                            
                                                        }
                                                        
                                                        makeCommand()
                                                        
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } else {
                            makeCommand()
                            
                        }
                    } else {
                        completion((false, nil, "there was an error decrypting that nodes credentials"))
                        
                    }
                }
            }
        }
    }
    
}
