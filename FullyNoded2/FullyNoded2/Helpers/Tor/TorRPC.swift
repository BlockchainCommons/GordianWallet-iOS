// TorRPC.swift

import Foundation

/**
Tor network singleton.
*/
class TorRPC {
    
    static let sharedInstance = TorRPC()
    var attempts = 0
    
    private init() {}
    
    func executeRPCCommand(walletName: String, command: BTC_CLI_COMMAND, parameters: Any, completion: @escaping (Result<Any, TorRPCError>) -> ()) {
        print("executeTorRPCCommand")
        
        if !TorClient.sharedInstance.isOperational {
            // Tor not connected
            completion(.failure(.OperationalError))
        }
        
        self.attempts += 1
        
        let enc = Encryption()
        enc.getNode { (node, error) in
            
            if !error {
                
                let onionAddress = node!.onionAddress
                let rpcusername = node!.rpcuser
                let rpcpassword = node!.rpcpassword
                var walletUrl = "http://\(rpcusername):\(rpcpassword)@\(onionAddress)"
                
                // No need to add wallet url for non wallet rpc calls
                if isWalletRPC(command: command) {
                    walletUrl += "/wallet/\(walletName)"
                }
                
                // Escape apostrophe characters for certain rpc commands
                var formattedParam = (parameters as! String).replacingOccurrences(of: "''", with: "")
                formattedParam = formattedParam.replacingOccurrences(of: "'\"'\"'", with: "'")
                
               guard let url = URL(string: walletUrl) else {
                    completion(.failure(.URLError))
                    return
                }
                
                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = "{\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(command)\",\"params\":[\(formattedParam)]}".data(using: .utf8)
                print("request = {\"jsonrpc\":\"1.0\",\"id\":\"curltest\",\"method\":\"\(command)\",\"params\":[\(formattedParam)]}")
                let queue = DispatchQueue(label: "com.FullyNoded.torQueue")
                queue.async {
                    
                    let task = TorClient.sharedInstance.session.dataTask(with: request as URLRequest) { (data, response, error) in
                        do {
                            if error != nil {
                                // Attempt a node command 20 times to avoid user having to tap refresh button
                                if self.attempts < 20 {
                                    self.executeRPCCommand(walletName: walletName, command: command, parameters: parameters) { (result) in
                                        if case .success(let response) = result {
                                            self.attempts = 0
                                            completion(.success(response))
                                        }
                                    }
                                } else {
                                    self.attempts = 0
                                    print("localizedDescription = \(error!.localizedDescription)")
                                    completion(.failure(.RequestError)) // More info in error.localizedDescription if necessary
                                }
                            } else {
                                self.attempts = 0
                                        if let urlContent = data {
                                    do {
                                        let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                                                            
                                        if let errorCheck = jsonResult["error"] as? NSDictionary {
                                            if let errorMessage = errorCheck["message"] as? String {
                                                // TODO: Handle 'Requested wallet does not exist or is not loaded' error here (.jsonMessageError) or with .requestError?
                                                print("errorMessage = \(errorMessage)")
                                                completion(.failure(.JSONError(message: errorMessage)))
                                            } else {
                                                completion(.failure(.JSONError(message: "Unknown Error")))
                                            }
                                        } else {
                                            if let responseString = self.checkCommandForResponse(command: command) {
                                                completion(.success(responseString))
                                            } else {
                                                completion(.success(jsonResult["result"]!))
                                            }
                                        }
                                    } catch {
                                        completion(.failure(.JSONError(message: "Serialization error")))
                                    }
                                }
                            }
                        }
                    }
                    task.resume()
                }
            } else {
                completion(.failure(.JSONError(message: "Data error")))
            }
        }
    }
    
    /**
     Helper function that returns a String for a given command.
     
     If not one of the explicit commands, returns nil.
     */
    private func checkCommandForResponse(command: BTC_CLI_COMMAND) -> String? {
        var returnString: String?
        switch command {
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
}

/**
 
 */
enum TorRPCError: LocalizedError, Equatable {
    case URLError
    case CredentialsError
    case RequestError
    case JSONError(message: String)
    case OperationalError
    case UnknownError
    case LoadWalletError
    
    var errorDescription: String? {
        switch self {
        case let .JSONError(message):
            return message
        default:
            return nil
        }
    }
}
