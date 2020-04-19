//
//  Utilities.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import UIKit
import LibWally

public extension UITextView {

  func addHyperLinksToText(originalText: String, hyperLinks: [String: String]) {
    let style = NSMutableParagraphStyle()
    style.alignment = .left
    let attributedOriginalText = NSMutableAttributedString(string: originalText)
    for (hyperLink, urlString) in hyperLinks {
        let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
        let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
        attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
        attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
        attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 17), range: fullRange)
        attributedOriginalText.addAttribute(.foregroundColor, value: UIColor.lightGray, range: fullRange)
    }

    self.linkTextAttributes = [
        NSAttributedString.Key.foregroundColor: UIColor.systemTeal
    ]
    self.attributedText = attributedOriginalText
  }
}

public extension String {
    static let numberFormatter = NumberFormatter()
    var doubleValue: Double {
        String.numberFormatter.decimalSeparator = "."
        if let result =  String.numberFormatter.number(from: self) {
            return result.doubleValue
        } else {
            String.numberFormatter.decimalSeparator = ","
            if let result = String.numberFormatter.number(from: self) {
                return result.doubleValue
            }
        }
        return 0
    }
}

public extension Dictionary {
    func json() -> String? {
        if let json = try? JSONSerialization.data(withJSONObject: self, options: []) {
            if let jsonString = String(data: json, encoding: .utf8) {
                return jsonString
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

public extension UIButton {
    func loadingIndicator(show: Bool) {
        if show {
            let indicator = UIActivityIndicatorView()
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            self.addSubview(indicator)
            indicator.startAnimating()
        } else {
            for view in self.subviews {
                if let indicator = view as? UIActivityIndicatorView {
                    indicator.stopAnimating()
                    indicator.removeFromSuperview()
                }
            }
        }
    }
}

extension Notification.Name {
    //public static let torConnecting = Notification.Name(rawValue: "torConnecting")
    //public static let didEnterForeground = Notification.Name(rawValue: "enteredForeground")
    public static let didStartBootstrappingTor = Notification.Name(rawValue: "didStartBootstrappingTor")
    public static let didCompleteOnboarding = Notification.Name(rawValue: "didCompleteOnboarding")
    //public static let didEstablishTorConnection = Notification.Name(rawValue: "didEstablishTorConnection")
}

public extension Int {
    func withCommas() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return numberFormatter.string(from: NSNumber(value:self))!
    }
}

public func isValidCharacters(_ string: String) -> Bool {
    let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    if string.rangeOfCharacter(from: characterset.inverted) != nil {
        return false
    } else {
        return true
    }
}

public func getActiveWalletNow(completion: @escaping ((wallet: WalletStruct?, error: Bool)) -> Void) {
    
    CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
        
        if errorDescription == nil {
            
            if wallets!.count > 0 {
                
                var walletToReturn:WalletStruct!
                
                Encryption.getNode { (node, error) in
                    
                    if !error && node != nil {
                        
                        for (i, wallet) in wallets!.enumerated() {
                            
                            let w = WalletStruct(dictionary: wallet)
                            
                            if w.isActive && !w.isArchived && node!.id == w.nodeId && w.name != nil && w.id != nil {
                                
                                walletToReturn = w
                                
                            }
                            
                            if i + 1 == wallets!.count {
                                
                                if walletToReturn != nil {
                                    
                                    completion((walletToReturn, false))
                                    
                                } else {
                                    
                                    completion((nil, true))
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        print("error getting active wallet: no active node")
                        completion((nil, true))
                        
                    }
                    
                }
                
            } else {
                
                print("error getting active wallet: wallets count = 0")
                completion((nil, true))
                
            }
            
        } else {
            
            print("error getting active wallet: \(errorDescription!)")
            completion((nil,true))
            
        }
        
    }
    
}

public func dateToUnix(inputdate: Date) -> Int {
    
    let unixTime = inputdate.timeIntervalSince1970
    return Int(unixTime)
    
}

public func keyBirthday() -> Int32 {
    
    let date = Date()
    return Int32(date.timeIntervalSince1970)
    
}

public func showAlert(vc: UIViewController, title: String, message: String) {
    
    DispatchQueue.main.async {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in }))
        vc.present(alert, animated: true, completion: nil)
        
    }
    
}

public func randomString(length: Int) -> String {
    
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0...length-1).map{ _ in letters.randomElement()! })
    
}

public func rounded(number: Double) -> Double {
    
    return Double(round(100000000*number)/100000000)
    
}

public func displayAlert(viewController: UIViewController, isError: Bool, message: String) {
    
    DispatchQueue.main.async {
        
        let errorView = ErrorView()
        
        errorView.isUserInteractionEnabled = true
        
        errorView.showErrorView(vc: viewController,
                                text: message,
                                isError: isError)
        
    }
    
}

public func network(path: String) -> Network {
    
    var network:Network!
    
    if path.contains("/1'") {
        
        network = .testnet
        
    } else {
        
        network = .mainnet
        
    }
    
    return network
    
}

public func isWalletRPC(command: BTC_CLI_COMMAND) -> Bool {
    
    var boolToReturn = Bool()
    
    switch command {
        
    case .listtransactions,
         .getnewaddress,
         .getwalletinfo,
         .importmulti,
         .rescanblockchain,
         .fundrawtransaction,
         .listunspent,
         .walletprocesspsbt,
         .gettransaction,
         .getaddressinfo,
         .listlockunspent,
         .lockunspent,
         .walletcreatefundedpsbt,
         .encryptwallet,
         .walletpassphrase,
         .walletpassphrasechange,
         .walletlock,
         .abortrescan,
         .fetchexternalbalances,
         .getsweeptoaddress,
         .getexternalwalletinfo:
        
        boolToReturn = true
        
    default:
        
        boolToReturn = false
        
    }
    
    return boolToReturn
    
}

public func shakeAlert(viewToShake: UIView) {
    print("shakeAlert")
    
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x - 10, y: viewToShake.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x + 10, y: viewToShake.center.y))
    
    DispatchQueue.main.async {
        
        viewToShake.layer.add(animation, forKey: "position")
        
    }
}

public func getDocumentsDirectory() -> URL {
    print("getDocumentsDirectory")
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

public extension Double {
    
    var avoidNotation: String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(for: self) ?? ""
        
    }
}

public extension UIDevice {
    
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 pro max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
    
}



