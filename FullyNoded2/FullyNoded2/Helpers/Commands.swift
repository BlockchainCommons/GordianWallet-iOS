//
//  Commands.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation

public enum BTC_CLI_COMMAND: String {
    
    case listlockunspent = "listlockunspent"
    case lockunspent = "lockunspent"
    case getaddressinfo = "getaddressinfo"
    case createpsbt = "createpsbt"
    case getmempoolinfo = "getmempoolinfo"
    case listwallets = "listwallets"
    case rescanblockchain = "rescanblockchain"
    case listwalletdir = "listwalletdir"
    case loadwallet = "loadwallet"
    case createwallet = "createwallet"
    case finalizepsbt = "finalizepsbt"
    case walletprocesspsbt = "walletprocesspsbt"
    case decodepsbt = "decodepsbt"
    case walletcreatefundedpsbt = "walletcreatefundedpsbt"
    case fundrawtransaction = "fundrawtransaction"
    case uptime = "uptime"
    case importmulti = "importmulti"
    case getdescriptorinfo = "getdescriptorinfo"
    case deriveaddresses = "deriveaddresses"
    case getrawtransaction = "getrawtransaction"
    case decoderawtransaction = "decoderawtransaction"
    case getnewaddress = "getnewaddress"
    case gettransaction = "gettransaction"
    case getwalletinfo = "getwalletinfo"
    case getblockchaininfo = "getblockchaininfo"
    case listtransactions = "listtransactions"
    case listunspent = "listunspent"
    case getpeerinfo = "getpeerinfo"
    case getnetworkinfo = "getnetworkinfo"
    case getmininginfo = "getmininginfo"
    case estimatesmartfee = "estimatesmartfee"
    case sendrawtransaction = "sendrawtransaction"
    case encryptwallet = "encryptwallet"
    case walletpassphrase = "walletpassphrase"
    case walletlock = "walletlock"
    case walletpassphrasechange = "walletpassphrasechange"
    
}
