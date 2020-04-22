//
//  NodeLogic.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

class NodeLogic {
    
    static let sharedInstance = NodeLogic()
    private init() {}
    
    func loadTorData(completion: @escaping ((success: Bool, dict: [String:Any]?, errorDescription: String?)) -> Void) {
        var dictToReturn = [String:Any]()
        Reducer.makeCommand(walletName: "", command: .getnetworkinfo, param: "") { (object, errorDesc) in
            if let networkInfo = object as? NSDictionary {
                if let subversionCheck = networkInfo["subversion"] as? String {
                    let subversion = subversionCheck.replacingOccurrences(of: "/", with: "")
                    dictToReturn["subversion"] = subversion.replacingOccurrences(of: "Satoshi:", with: "")
                    if let localaddresses = networkInfo["localaddresses"] as? NSArray {
                        if localaddresses.count > 0 {
                            for address in localaddresses {
                                if let dict = address as? NSDictionary {
                                    if let p2pAddress = dict["address"] as? String {
                                        if let port = dict["port"] as? Int {
                                            if p2pAddress.contains("onion") {
                                                dictToReturn["p2pOnionAddress"] = p2pAddress + ":" + "\(port)"
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if let networks = networkInfo["networks"] as? NSArray {
                        for network in networks {
                            if let dict = network as? NSDictionary {
                                if let name = dict["name"] as? String {
                                    if name == "onion" {
                                        if let reachable = dict["reachable"] as? Bool {
                                            dictToReturn["reachable"] = reachable
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    completion((true, dictToReturn, nil))
                    
                }
            } else {
                completion((false, nil, "error getting netowork info: \(errorDesc ?? "unknown error")"))
            }
        }
    }
    
    func loadExternalWalletData(wallet: WalletStruct, completion: @escaping ((success: Bool, dict: [String:Any]?, errorDescription: String?)) -> Void) {
        Reducer.makeCommand(walletName: wallet.name ?? "", command: .fetchexternalbalances, param: "0") { [unowned vc = self] (object, errorDesc) in
            if let utxos = object as? NSArray {
                vc.parseUtxos(wallet: wallet, utxos: utxos, completion: completion)
                
            } else {
                completion((false, nil, "returned object is nil"))
                
            }
        }
    }
    
    func loadWalletData(wallet: WalletStruct, completion: @escaping ((success: Bool, dict: [String:Any]?, errorDescription: String?)) -> Void) {
        Reducer.makeCommand(walletName: wallet.name!, command: .listunspent, param: "0") { [unowned vc = self] (object, errorDesc) in
            if let utxos = object as? NSArray {
                vc.parseUtxos(wallet: wallet, utxos: utxos, completion: completion)
                
            } else {
                completion((false, nil, "returned object is nil"))
                
            }
        }
    }
    
    func loadNodeData(node: NodeStruct, completion: @escaping ((success: Bool, dict: [String:Any]?, errorDescription: String?)) -> Void) {
        var dictToReturn = [String:Any]()
        func getBlockchainInfo() {
            Reducer.makeCommand(walletName: "", command: .getblockchaininfo, param: "") { (object, errorDescription) in
                if let blockchainInfo = object as? NSDictionary {
                    if let currentblockheight = blockchainInfo["blocks"] as? Int {
                        let halvingBlockTarget = 210000
                        let halvingsThatHaveOccured = Int(currentblockheight / halvingBlockTarget)
                        let nextHalvingTarget = (halvingsThatHaveOccured + 1) * halvingBlockTarget
                        let blocksTillNextHalving = Double(nextHalvingTarget - currentblockheight)
                        let secondsTillNextHalving = Double(blocksTillNextHalving * (600.0))
                        let halvingDate = Date(timeIntervalSinceNow: secondsTillNextHalving)
                        dictToReturn["halvingDate"] = halvingDate
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
                        if chain == "main" {
                            CoreDataService.updateEntity(id: node.id, keyToUpdate: "network", newValue: "mainnet", entityName: .nodes) {_ in }
                            
                        } else if chain == "test" {
                            CoreDataService.updateEntity(id: node.id, keyToUpdate: "network", newValue: "testnet", entityName: .nodes) {_ in }
                            
                        }                        
                    }
                    if let pruned = blockchainInfo["pruned"] as? Bool {
                        dictToReturn["pruned"] = pruned
                        
                    }
                    getPeerInfo()
                    
                }
            }
        }
        
        func getPeerInfo() {
            Reducer.makeCommand(walletName: "", command: .getpeerinfo, param: "") { (object, errorDescription) in
                if let peerInfo = object as? NSArray {
                    var incomingCount = 0
                    var outgoingCount = 0
                    for peer in peerInfo {
                        if let peerDict = peer as? NSDictionary {
                            if let incoming = peerDict["inbound"] as? Bool {
                                if incoming {
                                    incomingCount += 1
                                    dictToReturn["incomingCount"] = incomingCount
                                    
                                } else {
                                    outgoingCount += 1
                                    dictToReturn["outgoingCount"] = outgoingCount
                                    
                                }
                            }
                        }
                    }
                    getMiningInfo()
                } else {
                    completion((false, nil, "returned object is nil"))
                    
                }
            }
        }
        
        func getMiningInfo() {
            Reducer.makeCommand(walletName: "", command: .getmininginfo, param: "") { (object, errorDescription) in
                if let miningInfo = object as? NSDictionary {
                    if let hashesPerSecond = miningInfo["networkhashps"] as? Double {
                        let exahashesPerSecond = hashesPerSecond / 1000000000000000000
                        dictToReturn["networkhashps"] = Int(exahashesPerSecond).withCommas()
                        
                    }
                    getUptime()
                } else {
                    completion((false, nil, "returned object is nil"))
                    
                }
            }
        }
        
        func getUptime() {
            Reducer.makeCommand(walletName: "", command: .uptime, param: "") { (object, errorDesc) in
                if let doubleToReturn = object as? Double {
                    dictToReturn["uptime"] = Int(doubleToReturn)
                    getMempoolInfo()
                                            
                } else {
                    completion((false, nil, "returned object is nil"))
                    
                }
            }
        }
        
        func getMempoolInfo() {
            Reducer.makeCommand(walletName: "", command: .getmempoolinfo, param: "") { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    if let mempoolSize = dict["size"] as? Int {
                        dictToReturn["mempoolCount"] = mempoolSize
                        
                    } else {
                        dictToReturn["mempoolCount"] = 0
                        
                    }
                    let feeRate = UserDefaults.standard.integer(forKey: "feeTarget")
                    esitimateSmartFee(feeRate: feeRate)
                } else {
                    completion((false, nil, "returned object is nil"))
                    
                }
            }
        }
        
        func esitimateSmartFee(feeRate: Int) {
            Reducer.makeCommand(walletName: "", command: .estimatesmartfee, param: "\(feeRate)") { (object, errorDescription) in
                if let result = object as? NSDictionary {
                    if let feeRate = result["feerate"] as? Double {
                        let btcperbyte = feeRate / 1000
                        let satsperbyte = (btcperbyte * 100000000).avoidNotation
                        dictToReturn["feeRate"] = "\(satsperbyte) s/b"
                        
                    } else {
                        if let errors = result["errors"] as? NSArray {
                            dictToReturn["feeRate"] = "\(errors[0] as! String)"
                            
                        }
                    }
                    completion((true, dictToReturn, nil))
                    
                } else {
                    completion((false, nil, "returned object is nil"))
                    
                }
            }
        }
        getBlockchainInfo()
        
    }
    
    func loadTransactionData(wallet: WalletStruct, completion: @escaping ((success: Bool, array: [[String:Any]]?, errorDescription: String?)) -> Void) {
        Reducer.makeCommand(walletName: wallet.name!, command: .listtransactions, param: "\"*\", 50, 0, true") { [unowned vc = self] (object, errorDesc) in
            if let transactions = object as? NSArray {
                vc.parseTransactions(transactions: transactions, completion: completion)
                
            } else {
                completion((false, nil, errorDesc))
                
            }
        }
    }
    
    // MARK: Parsers
    func parseUtxos(wallet: WalletStruct, utxos: NSArray, completion: @escaping ((success: Bool, dict: [String:Any]?, errorDescription: String?)) -> Void) {
        var amount = 0.0
        var dictToReturn = [String:Any]()
        if utxos.count == 0 {
            dictToReturn["coldBalance"] = "0.0"
            dictToReturn["noUtxos"] = true
            if wallet.id != nil {
                CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "lastBalance", newValue: amount, entityName: .wallets) { _ in
                    CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "lastUsed", newValue: Date(), entityName: .wallets) { _ in
                        CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "lastUpdated", newValue: Date(), entityName: .wallets) { _ in
                            completion((true, dictToReturn, nil))
                            
                        }
                    }
                }
            } else {
                completion((true, dictToReturn, nil))
                
            }
            
        } else {
            dictToReturn["noUtxos"] = false
            
        }
        
        for (x, utxo) in utxos.enumerated() {
            if let utxoDict = utxo as? NSDictionary {
                
                /// Here we check the utxos descriptor to see what the path is for each pubkey.
                /// We take the highest index for each pubkey and compare it to the wallets index.
                /// If the wallets index is less than or equal to the highest utxo index we increase
                /// the wallets index to be greater then the highest utxo index. This way we avoid
                /// reusing an address in the scenario where a user may use external software to
                /// receive to the app or for example they export their keys within the app and use
                /// random addresses as invoices.
                
                if let desc = utxoDict["desc"] as? String {
                    let p = DescriptorParser()
                    let str = p.descriptor(desc)
                    var paths:[String]!
                    if str.isMulti {
                        paths = str.derivationArray
                        
                    } else {
                        paths = [str.derivation]
                        
                    }
                    
                    for path in paths {
                        let arr = path.split(separator: "/")
                        for (i, comp) in arr.enumerated() {
                            if i + 1 == arr.count {
                                if let int = Int(comp) {
                                    if wallet.id != nil {
                                        if wallet.index <= int {
                                            CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "index", newValue: int + 1, entityName: .wallets) { (success, errorDescription) in
                                                if success {
                                                    print("updated index from utxo")
                                                    
                                                } else {
                                                    print("failed to update index from utxo")
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let spendable = utxoDict["spendable"] as? Bool {
                    if let confirmations = utxoDict["confirmations"] as? Int {
                        if !spendable {
                            if let balance = utxoDict["amount"] as? Double {
                                amount += balance
                                
                            }
                        }
                        if confirmations < 1 {
                            dictToReturn["unconfirmed"] = true
                            
                        } else {
                            dictToReturn["unconfirmed"] = false
                            
                        }
                    }
                }
            }
            
            /// We fetch balances when we check for wallet recovery confirmation, therefore it does not have an ID yet if it has not been recovered
            func complete() {
                if wallet.id != nil {
                    CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "lastBalance", newValue: amount, entityName: .wallets) { _ in
                        CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "lastUsed", newValue: Date(), entityName: .wallets) { _ in
                            CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "lastUpdated", newValue: Date(), entityName: .wallets) { _ in
                                completion((true, dictToReturn, nil))
                                
                            }
                        }
                    }
                } else {
                    completion((true, dictToReturn, nil))
                    
                }
            }
            
            if x + 1 == utxos.count {
                if amount == 0.0 {
                    dictToReturn["coldBalance"] = "0.0"
                    complete()
                    
                } else {
                    dictToReturn["coldBalance"] = "\((round(100000000*amount)/100000000).avoidNotation)"
                    let fx = FiatConverter.sharedInstance
                    fx.getFxRate() { (fxRate) in
                        if fxRate != nil {
                            dictToReturn["fiatBalance"] = "$\(Int(amount * fxRate!).withCommas())"
                        }
                        complete()
                    }
                }
            }
        }
    }
    
    func parseTransactions(transactions: NSArray, completion: @escaping ((success: Bool, array: [[String:Any]]?, errorDescription: String?)) -> Void) {
        var arrayToReturn = [[String:Any]]()
        var transactionArray = [[String:Any]]()
        let dateFormatter = DateFormatter()
        if transactions.count > 0 {
            for item in transactions {
                if let transaction = item as? NSDictionary {
                    var label = String()
                    var replaced_by_txid = String()
                    var isCold = false
                    let address = transaction["address"] as? String ?? ""
                    let amount = transaction["amount"] as? Double ?? 0.0
                    if amount.avoidNotation != "" {
                        let amountString = amount.avoidNotation
                        let confsCheck = transaction["confirmations"] as? Int ?? 0
                        let confirmations = "\(confsCheck)"
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
            }
            
            for (i, tx) in transactionArray.enumerated() {
                if let _ = tx["amount"] as? String {
                    if let amount = Double(tx["amount"] as! String) {
                        if let txID = tx["txID"] as? String {
                            for (x, transaction) in transactionArray.enumerated() {
                                if let amountToCompare = Double(transaction["amount"] as! String) {
                                    if x != i && txID == (transaction["txID"] as! String) {
                                        if amount + amountToCompare == 0 && amount > 0 {
                                            transactionArray[i]["selfTransfer"] = true
                                            
                                        } else if amount + amountToCompare == 0 && amount < 0 {
                                            transactionArray[i]["remove"] = true
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            for (i, tx) in transactionArray.enumerated() {
                if let remove = tx["remove"] as? Bool {
                    if !remove {
                        arrayToReturn.append(tx)
                        
                    }
                }
                if i + 1 == transactionArray.count {
                    completion((true, arrayToReturn, nil))
                    
                }
            }
        } else {
            completion((true, arrayToReturn, nil))
            
        }
    }
}
