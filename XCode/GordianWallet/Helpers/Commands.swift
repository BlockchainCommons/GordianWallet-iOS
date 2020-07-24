//
//  Commands.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

public enum BTC_CLI_COMMAND: String {
    
    case getblockcount
    case getexternalwalletinfo
    case fetchexternalbalances
    case getsweeptoaddress
    case listlockunspent
    case lockunspent
    case getaddressinfo
    case createpsbt
    case getmempoolinfo
    case listwallets
    case rescanblockchain
    case listwalletdir
    case loadwallet
    case createwallet
    case finalizepsbt
    case walletprocesspsbt
    case decodepsbt
    case walletcreatefundedpsbt
    case fundrawtransaction
    case uptime
    case importmulti
    case getdescriptorinfo
    case deriveaddresses
    case getrawtransaction
    case decoderawtransaction
    case getnewaddress
    case gettransaction
    case getwalletinfo
    case getblockchaininfo
    case listtransactions
    case listunspent
    case getpeerinfo
    case getnetworkinfo
    case getmininginfo
    case estimatesmartfee
    case sendrawtransaction
    case encryptwallet
    case walletpassphrase
    case walletlock
    case walletpassphrasechange
    case abortrescan
    case converttopsbt
    
    var description: String {
        switch self {
            
        case .converttopsbt:
            return "converttopsbt"
            
        case .getblockcount:
            return "getblockcount"
            
        case .getexternalwalletinfo:
            return "getwalletinfo"
            
        case .fetchexternalbalances:
            return "listunspent"
            
        case .getsweeptoaddress:
            return "getnewaddress"
            
        case .getnewaddress:
            return "getnewaddress"
            
        case .listlockunspent:
            return "listlockunspent"
            
        case .lockunspent:
            return "lockunspent"
            
        case .getaddressinfo:
            return "getaddressinfo"
            
        case .createpsbt:
            return "createpsbt"
            
        case .getmempoolinfo:
            return "getmempoolinfo"
            
        case .listwallets:
            return "listwallets"
            
        case .rescanblockchain:
            return "rescanblockchain"
            
        case .listwalletdir:
            return "listwalletdir"
            
        case .loadwallet:
            return "loadwallet"
            
        case .createwallet:
            return "createwallet"
            
        case .finalizepsbt:
            return "finalizepsbt"
            
        case .walletprocesspsbt:
            return "walletprocesspsbt"
            
        case .decodepsbt:
            return "decodepsbt"
            
        case .walletcreatefundedpsbt:
            return "walletcreatefundedpsbt"
            
        case .fundrawtransaction:
            return "fundrawtransaction"
            
        case .uptime:
            return "uptime"
            
        case .importmulti:
            return "importmulti"
            
        case .getdescriptorinfo:
            return "getdescriptorinfo"
            
        case .deriveaddresses:
            return "deriveaddresses"
            
        case .getrawtransaction:
            return "getrawtransaction"
            
        case .decoderawtransaction:
            return "decoderawtransaction"
            
        case .gettransaction:
            return "gettransaction"
            
        case .getwalletinfo:
            return "getwalletinfo"
            
        case .getblockchaininfo:
            return "getblockchaininfo"
            
        case .listtransactions:
            return "listtransactions"
            
        case .listunspent:
            return "listunspent"
            
        case .getpeerinfo:
            return "getpeerinfo"
            
        case .getnetworkinfo:
            return "getnetworkinfo"
            
        case .getmininginfo:
            return "getmininginfo"
            
        case .estimatesmartfee:
            return "estimatesmartfee"
            
        case .sendrawtransaction:
            return "sendrawtransaction"
            
        case .encryptwallet:
            return "encryptwallet"
            
        case .walletpassphrase:
            return "walletpassphrase"
            
        case .walletlock:
            return "walletlock"
            
        case .walletpassphrasechange:
            return "walletpassphrasechange"
            
        case .abortrescan:
            return "abortrescan"
        }
    }
    
}
