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
    
    let localeToCurrency = [
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
        "JP": "JPY"
    ]
    let currencyList = ["USD", "USDT", "CAD", "BRL", "ARS", "GBP", "EUR", "TRY", "ZAR", "INR", "CNY", "KRW", "JPY", "AUD"]
    
    func getNewLocale() -> String {
        let locale = localeToCurrency[Locale.current.regionCode ?? "US"] ?? "USD"
        if UserDefaults.standard.string(forKey: "currentLocale") == nil {
            UserDefaults.standard.set(locale, forKey: "currentLocale")
        }
        return locale
    }
    
    func getSavedLocale() -> String {
        let locale = localeToCurrency[Locale.current.regionCode ?? "US"] ?? "USD"
        if UserDefaults.standard.string(forKey: "currentLocale") == nil {
            UserDefaults.standard.set(locale, forKey: "currentLocale")
        }
        return UserDefaults.standard.string(forKey: "currentLocale") ?? "USD"
    }
    
    func changeLocale(newLocale: String) -> Void {
        UserDefaults.standard.set(newLocale, forKey: "currentLocale")
    }
}
