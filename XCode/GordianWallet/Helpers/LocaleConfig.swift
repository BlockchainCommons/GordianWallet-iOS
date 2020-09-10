//
//  LocaleConfig.swift
//  FullyNoded2
//
//  Created by Gautham Ganesh Elango on 21/7/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import UIKit

class LocaleConfig {
    
    let localeToCurrency: [String: String] = [
        "US": "USD",
        "AU": "AUD",
        "CA": "CAD",
        "BR": "BRL",
        "AR": "ARS",
        "GB": "GBP",
        "AT": "EUR",
        "BE": "EUR",
        "CY": "EUR",
        "EE": "EUR",
        "FI": "EUR",
        "FR": "EUR",
        "DE": "EUR",
        "GR": "EUR",
        "IE": "EUR",
        "IT": "EUR",
        "LV": "EUR",
        "LT": "EUR",
        "LU": "EUR",
        "MT": "EUR",
        "NL": "EUR",
        "PT": "EUR",
        "SK": "EUR",
        "SI": "EUR",
        "ES": "EUR",
        "TR": "TRY",
        "ZA": "ZAR",
        "IN": "INR",
        "CN": "CNY",
        "KR": "KRW",
        "JP": "JPY",
        "ID": "IDR"
    ]
    let currencyList: [String] = ["USD","GBP","JPY","AUD","USDT","BRL","EUR","KRW","ZAR","TRY","USDC","INR","CAD","IDR"]
    let currencySymbolDict: [String: String] = [
        "USD": "$",
        "CAD": "C$",
        "BRL": "R$",
        "ARS": "$",
        "GBP": "£",
        "EUR": "€",
        "TRY": "₺",
        "ZAR": "R",
        "INR": "₹",
        "CNY": "¥",
        "KRW": "₩",
        "JPY": "¥",
        "AUD": "A$",
        "IDR": "Rp"
    ]
    let defaultLocale: String = "US"
    let defaultCurrency: String = "USD"
    
    func getSavedLocale() -> String {
        return UserDefaults.standard.string(forKey: "currentLocale") ?? defaultCurrency
    }
    
    func onStartup() -> Void {
        let locale = localeToCurrency[Locale.current.regionCode ?? defaultLocale] ?? defaultCurrency
        if UserDefaults.standard.string(forKey: "currentLocale") == nil {
            UserDefaults.standard.set(locale, forKey: "currentLocale")
        }
    }
    
    func changeLocale(newLocale: String) -> Void {
        UserDefaults.standard.set(newLocale, forKey: "currentLocale")
    }
    
    func getCurrencyList() -> [String] {
        return currencyList
    }
    
    func convertLocaleToCurrency(locale: String) -> String {
        return localeToCurrency[locale] ?? defaultCurrency
    }
    
    func currencySymbol() -> String {
        return currencySymbolDict[self.getSavedLocale()] ?? "$"
    }
}
