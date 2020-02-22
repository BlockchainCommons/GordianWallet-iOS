// TorRPC.swift
import Foundation

enum TorRPCError: LocalizedError {
    case urlError
    case credentialsError
    case requestError(localizedDescription: String)
    case jsonError(description: String)
    case jsonMessageError(message: String)
    case connectionError(description: String)
}

class TorRPC {
    
    static let instance = TorRPC()
    let queue = DispatchQueue(label: "com.FullyNoded.torQueue")
//    var attempts = 0
    
    private init() {}
    
    func executeRPCCommand(walletName: String, command: BTC_CLI_COMMAND, param: Any, completion: @escaping (Result<Any, TorRPCError>) -> ()) {
        print("executeTorRPCCommand")
        
        if !TorClient.sharedInstance.isOperational {
            completion(.failure(.connectionError(description: "TOR Not Connected")))
        }
            
//        attempts += 1
            
        let enc = Encryption()
        enc.getNode { (node, error) in
            if !error {
            
                let onionAddress = node!.onionAddress
                let rpcusername = node!.rpcuser
                let rpcpassword = node!.rpcpassword
                
                let walletUrl = "http://\(rpcusername):\(rpcpassword)@\(onionAddress)/wallet/\(walletName)"
                
                // Have to escape ' characters for certain rpc commands
                var formattedParam = (param as! String).replacingOccurrences(of: "''", with: "")
                formattedParam = formattedParam.replacingOccurrences(of: "'\"'\"'", with: "'")
                
                guard let url = URL(string: walletUrl) else {
                    completion(.failure(.urlError))
                    return
                }
                
                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(command)\",\"params\":[\(formattedParam)]}".data(using: .utf8)
                
                self.queue.async {
                    
                    let task = TorClient.sharedInstance.session.dataTask(with: request as URLRequest) { (data, response, error) in
                        if error != nil {
                            // attempt a node command 20 times to avoid user having to tap refresh button
//                            if self!.attempts < 20 { // TODO: Get rid of bang
//                                self?.executeRPCCommand(walletName: walletName, method: method, param: param) {}
//                            } else {
//                                self?.attempts = 0
//                                // TODO: Handle 'Requested wallet does not exist or is not loaded' error here (.requestError) or with .jsonMessageError?
//                                completion(.failure(.requestError(localizedDescription: error!.localizedDescription))) // TODO: Get rid of bang
//                            }
                        } else {
//                            self?.attempts = 0
                            
                            if let urlContent = data {
                                do {
                                    let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                                                        
                                    if let errorCheck = jsonAddressResult["error"] as? NSDictionary {
                                        if let errorMessage = errorCheck["message"] as? String {
                                            // TODO: Handle 'Requested wallet does not exist or is not loaded' error here (.jsonMessageError) or with .requestError?
                                            completion(.failure(.jsonMessageError(message: errorMessage)))
                                        } else {
                                            completion(.failure(.jsonError(description: "Unknown Error")))
                                        }
                                    } else {
                                        if let responseString = self.checkCommandForResponse(command: command) {
                                            completion(.success(responseString))
                                        } else {
                                            completion(.success(jsonAddressResult["result"] as Any))
                                        }
                                    }
                                } catch {
                                    completion(.failure(.jsonError(description: "Unknown Error")))
                                }
                            }
                        }
                    }
                    task.resume()
                }
            } else {
                completion(.failure(.credentialsError))
            }
        }
    }
    
    /// Called upon successful executeRPCCommand()
    private func checkCommandForResponse(command: BTC_CLI_COMMAND) -> String? {
        var returnString: String?
        switch command {
        case .unloadwallet:
            returnString = "Wallet Unloaded"
        case .importprivkey:
            returnString = "Import Key Success"
        case .walletpassphrase:
            returnString = "Wallet Decrypted"
        case .walletpassphrasechange:
            returnString = "Passphrase Updated"
        case .encryptwallet, .walletlock:
            returnString = "Wallet Encrypted"
        default:
            returnString = nil
        }
        return returnString
    }
    
//    // TODO: STILL NEED TO HANDLE THIS ERROR CASE
//    if torRPC.errorDescription.contains("Requested wallet does not exist or is not loaded") {
//        errorDescription = ""
//        errorBool = false
//        torRPC.executeRPCCommand(walletName: walletName, method: .loadwallet, param: "\"\(walletName)\"") {
//            if !self.torRPC.errorBool {
//                self.torRPC.executeRPCCommand(walletName: walletName, method: command,
//                                              param: param,
//                                              completion: getResult)
//            } else {
//                self.errorBool = true
//                self.errorDescription = "Wallet does not exist, maybe your node changed networks?"
//                completion()
//            }
//        }
//    } else {
//        errorBool = true
//        errorDescription = torRPC.errorDescription
//        completion()
//    }
}
