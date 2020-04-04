// RPCResponseHandler.swift

import Foundation

class RPCResponseHandler {
    
    static let instance = RPCResponseHandler()
    
    let dateFormatter = DateFormatter()
    
    private init() {}
    
    func getNetworkInfo(fromResponse responseDictionary: NSDictionary) -> [String:Any] {
        let subversion = (responseDictionary["subversion"] as! String).replacingOccurrences(of: "/", with: "")
        var dictToReturn: [String:Any] = [:]
        dictToReturn["subversion"] = subversion.replacingOccurrences(of: "Satoshi:", with: "")
        let localaddresses = responseDictionary["localaddresses"] as! NSArray
        
        if localaddresses.count > 0 {
            for address in localaddresses {
                let dict = address as! NSDictionary
                let p2pAddress = dict["address"] as! String
                let port = dict["port"] as! Int
                
                if p2pAddress.contains("onion") {
                    dictToReturn["p2pOnionAddress"] = p2pAddress + ":" + "\(port)"
                }
            }
        }
        
        let networks = responseDictionary["networks"] as! NSArray
        
        for network in networks {
            let dict = network as! NSDictionary
            let name = dict["name"] as! String
            
            if name == "onion" {
                let reachable = dict["reachable"] as! Bool
                dictToReturn["reachable"] = reachable
            }
        }
        return dictToReturn
    }
    
    func listUnspent(utxoArray: NSArray) -> [String:Any] {
        var amount = 0.0
        
        var dictToReturn: [String:Any] = [:]
        
        for utxo in utxoArray as! [NSDictionary] {
            let spendable = utxo["spendable"] as! Bool
            let confirmations = utxo["confirmations"] as! Int
            
            if !spendable {
                let balance = utxo["amount"] as! Double
                amount += balance
            }
            
            if confirmations < 1 {
                dictToReturn["unconfirmed"] = true
            }
        }
        
        if amount == 0.0 {
            dictToReturn["coldBalance"] = "0.0"
        } else {
            dictToReturn["coldBalance"] = "\((round(100000000*amount)/100000000).avoidNotation)"
        }
        return dictToReturn
    }
    
    func getMiningInfo(miningInfo: NSDictionary) -> [String : Any]{
                
        let hashesPerSecond = miningInfo["networkhashps"] as! Double
        let exahashesPerSecond = hashesPerSecond / 1000000000000000000
        
        return ["networkhashps" : Int(exahashesPerSecond).withCommas()]
    }
    
    func getBlockchainInfo(blockchainInfo: NSDictionary) -> [String : Any] {
    
        var dictToReturn: [String:Any] = [:]
        
        if let currentblockheight = blockchainInfo["blocks"] as? Int {
            dictToReturn["blocks"] = currentblockheight
        }
        
        if let difficultyCheck = blockchainInfo["difficulty"] as? Double {
            dictToReturn["difficulty"] = "\(Int(difficultyCheck / 1000000000000).withCommas()) trillion"
        }
        
        if let sizeCheck = blockchainInfo["size_on_disk"] as? Int {
            dictToReturn["size"] = "\(sizeCheck/1000000000) gb"
        }
        
        if let progressCheck = blockchainInfo["verificationprogress"] as? Double {
            dictToReturn["progress"] = "\(Int(progressCheck*100))%"
        }
        
        if let chain = blockchainInfo["chain"] as? String {
            dictToReturn["chain"] = chain
        }
        
        if let pruned = blockchainInfo["pruned"] as? Bool {
            dictToReturn["pruned"] = pruned
        }
        return dictToReturn
    }
    
    func getPeerInfo(peerInfo: NSArray) -> [String : Any] {
        var incomingCount = 0
        var outgoingCount = 0
        
        var dictToReturn: [String:Any] = [:]
        
        for peer in peerInfo {
            let peerDict = peer as! NSDictionary
            let incoming = peerDict["inbound"] as! Bool
            
            if incoming {
                incomingCount += 1
                dictToReturn["incomingCount"] = incomingCount
            } else {
                outgoingCount += 1
                dictToReturn["outgoingCount"] = outgoingCount
            }
        }
        return dictToReturn
    }
    
    func listTransactions(transactions: NSArray) -> [[String:Any]] {
        var transactionArray = [[String:Any]]()
        // Supplemental array
        var arrayToReturn = [[String:Any]]()
        
        for item in transactions {
            
            if let transaction = item as? NSDictionary {
                
                var label = String()
                var replaced_by_txid = String()
                var isCold = false
                
                let address = transaction["address"] as? String ?? ""
                let amount = transaction["amount"] as? Double ?? 0.0
                let amountString = amount.avoidNotation
                let confsCheck = transaction["confirmations"] as? Int ?? 0
                let confirmations = String(confsCheck)
                
                if let replaced_by_txid_check = transaction["replaced_by_txid"] as? String {
                    replaced_by_txid = replaced_by_txid_check
                }
                
                if let labelCheck = transaction["label"] as? String {
                    label = labelCheck
                    
                    if labelCheck == "" {
                        label = ""
                    }
                    
                    if labelCheck == "," {
                        label = ""
                    }
                    
                } else {
                    label = ""
                }
                
                let secondsSince = transaction["time"] as? Double ?? 0.0
                let rbf = transaction["bip125-replaceable"] as? String ?? ""
                let txID = transaction["txid"] as? String ?? ""
                
                let date = Date(timeIntervalSince1970: secondsSince)
                dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
                let dateString = dateFormatter.string(from: date)
                
                if let boolCheck = transaction["involvesWatchonly"] as? Bool {
                    isCold = boolCheck
                }
                                
                transactionArray.append(["address": address,
                                         "amount": amountString,
                                         "confirmations": confirmations,
                                         "label": label,
                                         "date": dateString,
                                         "rbf": rbf,
                                         "txID": txID,
                                         "replacedBy": replaced_by_txid,
                                         "involvesWatchonly":isCold,
                                         "selfTransfer":false,
                                         "remove":false])
                
            }
            
        }
        
        // process self transfers
        for (i, tx) in transactionArray.enumerated() {
            
            let amount = Double(tx["amount"] as! String)!
            let txID = tx["txID"] as! String
            
            for (x, transaction) in transactionArray.enumerated() {
                let amountToCompare = Double(transaction["amount"] as! String)!
                
                if x != i && txID == (transaction["txID"] as! String) {
                    if amount + amountToCompare == 0 && amount > 0 {
                        transactionArray[i]["selfTransfer"] = true
                    } else if amount + amountToCompare == 0 && amount < 0 {
                        transactionArray[i]["remove"] = true
                    }
                }
            }
        }
                    
        for tx in transactionArray {
            
            if !(tx["remove"] as! Bool) {
                arrayToReturn.append(tx)
            }
        }
        
        return arrayToReturn
    }
}
