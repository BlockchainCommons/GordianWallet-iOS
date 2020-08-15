//
//  LocaleConfig.swift
//  FullyNoded2
//
//  Created by Gautham Ganesh Elango on 10/8/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import UIKit

class PriceServer {
    
    let localeConfig = LocaleConfig()
    
    let defaultServerString: String = "km3danfmt7aiqylbq5lhyn53zhv2hhbmkr6q5pjc64juiyuxuhcsjwyd.onion"
    let defaultServerIndex: Int = 0
    let defaultServers: [String] = ["km3danfmt7aiqylbq5lhyn53zhv2hhbmkr6q5pjc64juiyuxuhcsjwyd.onion"]
    let exchangeList: [String] = ["acx","anxpro","aofex","bcex","bequant","bibox","bigone","binance","bit2c","bitbank","bitbay","bitfinex","bitflyer","bitforex","bithumb","bitkk","bitmart","bitmax","bitstamp","bittrex","bitz","bl3p","bleutrade","braziliex","btcalpha","btcbox","btcmarkets","btctradeua","btcturk","buda","bw","bybit","bytetrade","cex","chilebit","coinbase","coincheck","coinegg","coinex","coinfalcon","coinfloor","coingi","coinmarketcap","coinmate","coinone","coinspot","coolcoin","coss","crex24","currencycom","deribit","digifinex","dsx","eterbase","exmo","exx","fcoin","fcoinjp","flowbtc","foxbit","ftx","fybse","gateio","gemini","hbtc","hitbtc","hollaex","huobipro","ice3x","idex","independentreserve","indodax","itbit","kraken","kucoin","kuna","lakebtc","latoken","lbank","liquid","livecoin","luno","lykke","mercado","mixcoins","oceanex","okcoin","okex","paymium","poloniex","probit","qtrade","rightbtc","southxchange","stex","stronghold","surbitcoin","therock","tidebit","tidex","upbit","vbtc","wavesexchange","whitebit","xbtce","yobit","zaif","zb"]
    let defaultExchange: String = "coinbase"
    
    func getServers() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "priceServers") ?? defaultServers
    }
    
    func onStartup() -> Void {
        if UserDefaults.standard.stringArray(forKey: "priceServers") == nil {
            UserDefaults.standard.set(defaultServers, forKey: "priceServers")
        }
        if (UserDefaults.standard.string(forKey: "currentServer") == nil) || (UserDefaults.standard.string(forKey: "currentServerIndex") == nil) {
            UserDefaults.standard.set(defaultServerString, forKey: "currentServer")
            UserDefaults.standard.set(defaultServerIndex, forKey: "currentServerIndex")
        }
        if UserDefaults.standard.string(forKey: "currentExchange") == nil {
            UserDefaults.standard.set(defaultExchange, forKey: "currentExchange")
        }
    }
    
    func changeServers(newServers: [String]) -> Void {
        UserDefaults.standard.set(newServers, forKey: "priceServers")
    }
    
    func setCurrentServer(server: String, index: Int) -> Void {
        UserDefaults.standard.set(server, forKey: "currentServer")
        UserDefaults.standard.set(index, forKey: "currentServerIndex")
    }
    
    func getCurrentServerString() -> String {
        return UserDefaults.standard.string(forKey: "currentServer") ?? defaultServerString
    }
    
    func getCurrentServerIndex() -> Int {
        return UserDefaults.standard.integer(forKey: "currentServerIndex")
    }
    
    func addServer(server: String) -> Void {
        var currentServers = self.getServers()
        currentServers.append(server)
        self.changeServers(newServers: currentServers)
    }
    
    func removeServerByString(server: String) -> Void {
        var currentServers = self.getServers()
        if let index = currentServers.firstIndex(of: server) {
            currentServers.remove(at: index)
            self.changeServers(newServers: currentServers)
        }
    }
    
    func removeServerByIndex(index: Int) -> Void {
        var currentServers = self.getServers()
        currentServers.remove(at: index)
        self.changeServers(newServers: currentServers)
    }
    
    func getCurrentExchange() -> String {
        return UserDefaults.standard.string(forKey: "currentExchange") ?? defaultExchange
    }
    
    func changeExchange(newExchange: String) -> Void {
        UserDefaults.standard.set(newExchange, forKey: "currentExchange")
    }
    
    func getExchangeList() -> [String] {
        return exchangeList
    }
    
    func createSpotBitURL() -> String {
        return "http://" + self.getCurrentServerString() + "/now/" + localeConfig.getSavedLocale() + "/" + self.getCurrentExchange()
    }
}
