//
//  ChooseNumberOfSignersViewController.swift
//  FullyNoded2
//
//  Created by Peter on 04/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class ChooseNumberOfSignersViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate {
    
    var xpubArray = [String]()
    var walletName = ""
    var keys = ""
    var seedArray = [String]()
    var recoveryDict = [String:Any]()
    var requiredSigs = Int()
    var network:Network!
    var alertStyle = UIAlertController.Style.actionSheet
    @IBOutlet weak var picker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        picker.delegate = self
        picker.dataSource = self
        if (UIDevice.current.userInterfaceIdiom == .pad) {
          alertStyle = UIAlertController.Style.alert
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if seedArray.count > 0 {
            return seedArray.count
            
        } else {
            return xpubArray.count
            
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requiredSigs = row + 1
        
        if xpubArray.count == 0 {
            DispatchQueue.main.async { [unowned vc = self] in
                
                let alert = UIAlertController(title: "Recover \(vc.requiredSigs) of \(vc.seedArray.count) now?", message: "", preferredStyle: vc.alertStyle)
                alert.addAction(UIAlertAction(title: "Recover now", style: .default, handler: { action in
                    vc.buildWallet()
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                alert.popoverPresentationController?.sourceView = self.view
                vc.present(alert, animated: true, completion: nil)
                
            }
            
        } else {
            DispatchQueue.main.async { [unowned vc = self] in
                
                let alert = UIAlertController(title: "Recover \(vc.requiredSigs) of \(vc.xpubArray.count) now?", message: "", preferredStyle: vc.alertStyle)
                alert.addAction(UIAlertAction(title: "Recover now", style: .default, handler: { action in
                    vc.buildDescriptorFromXpubs()
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                alert.popoverPresentationController?.sourceView = self.view
                vc.present(alert, animated: true, completion: nil)
                
            }
            
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributedString = NSAttributedString(string: "\(row + 1)", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        return attributedString
        
    }
    
    private func buildWallet() {
        func getKeys(network: Network) {
            for (i, seed) in seedArray.enumerated() {
                if let mnemonic = try? BIP39Mnemonic(words: seed) {
                    var pathString = "m/48'/0'/0'/2'"
                    if network == .testnet {
                        pathString = "m/48'/1'/0'/2'"
                    }
                    if let path = try? BIP32Path(string: pathString) {
                        let seed = mnemonic.seedHex(passphrase: "")
                        if let mk = try? HDKey(seed: seed, network: network) {
                            let fingerprint = mk.fingerprint.hexString
                            do {
                                let account = try mk.derive(using: path)
                                let pathWithFingerprint = pathString.replacingOccurrences(of: "m", with: fingerprint)
                                if i + 1 == seedArray.count {
                                    recoveryDict["derivation"] = pathString
                                    recoveryDict["id"] = UUID()
                                    recoveryDict["isActive"] = false
                                    recoveryDict["lastUsed"] = Date()
                                    recoveryDict["lastBalance"] = 0.0
                                    recoveryDict["isArchived"] = false
                                    recoveryDict["nodeIsSigner"] = false
                                    let key = "[\(pathWithFingerprint)]\(account.xpub)/0/*"
                                    keys += key
                                    buildDescriptors()
                                } else {
                                    let key = "[\(pathWithFingerprint)]\(account.xpub)/0/*,"
                                    keys += key
                                }
                            } catch {
                                showAlert(vc: self, title: "Error", message: "error setting up your multisig descriptor key array")
                            }
                        }
                    }
                }
            }
        }
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            if node != nil {
                vc.recoveryDict["nodeId"] = node!.id
                let chain = node!.network
                vc.network = Network.mainnet
                if chain == "testnet" {
                    vc.network = .testnet
                }
                getKeys(network: vc.network)
            } else {
                showAlert(vc: vc, title: "No node!", message: "You need to have an active node in order to recover.")
            }
        }
    }
    
    private func buildDescriptors() {
        let creatingView = ConnectingView()
        creatingView.addConnectingView(vc: self, description: "processing your descriptors...")
        let primaryDesc = "wsh(sortedmulti(\(requiredSigs),\(keys)))"
        let changeDesc = primaryDesc.replacingOccurrences(of: "/0/*", with: "/1/*")
        Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryDesc)\"") { [unowned vc = self] (object, errorDescription) in
            if let dict = object as? NSDictionary {
                if let primaryDescriptor = dict["descriptor"] as? String {
                    vc.recoveryDict["descriptor"] = primaryDescriptor
                    Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") { [unowned vc = self] (object, errorDescription) in
                        if let dict = object as? NSDictionary {
                            if let changeDescriptor = dict["descriptor"] as? String {
                                var encryptedXprvs:[Data] = []
                                for (i, seed) in vc.seedArray.enumerated() {
                                    if let mnemonic = try? BIP39Mnemonic(words: seed) {
                                        if let derivation = vc.recoveryDict["derivation"] as? String {
                                            let seed = mnemonic.seedHex(passphrase: "")
                                            if let mk = try? HDKey(seed: seed, network: vc.network) {
                                                if let path = try? BIP32Path(string: derivation) {
                                                    do {
                                                        if let xprv = try mk.derive(using: path).xpriv {
                                                            Encryption.encryptData(dataToEncrypt: xprv.dataUsingUTF8StringEncoding) { [unowned vc = self] (encryptedData, error) in
                                                                if encryptedData != nil {
                                                                    encryptedXprvs.append(encryptedData!)
                                                                    if i + 1 == vc.seedArray.count {
                                                                        vc.recoveryDict["xprvs"] = encryptedXprvs
                                                                        vc.recoveryDict["changeDescriptor"] = changeDescriptor
                                                                        vc.recoveryDict["birthdate"] = keyBirthday()
                                                                        vc.recoveryDict["type"] = "MULTI"
                                                                        vc.recoveryDict["blockheight"] = Int32(1)
                                                                        vc.recoveryDict["maxRange"] = 2500
                                                                        vc.recoveryDict["nodeIsSigner"] = false
                                                                        vc.walletName = Encryption.sha256hash(primaryDescriptor)
                                                                        vc.recoveryDict["name"] = vc.walletName
                                                                        DispatchQueue.main.async { [unowned vc = self] in
                                                                            vc.performSegue(withIdentifier: "segueConfirmMultiSigFromWords", sender: vc)
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } catch {
                                                        creatingView.removeConnectingView()
                                                        showAlert(vc: vc, title: "Error", message: "error encrypting your xprv")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            creatingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: "error getting primary descriptor: \(errorDescription ?? "unknown")")
                        }
                    }
                }
            } else {
                creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "error getting primary descriptor: \(errorDescription ?? "unknown")")
            }
        }
    }
    
    private func buildDescriptorFromXpubs() {
        
        var prefix = ""
        var xpubsWithChildKeys = ""
        
        for (i, xpub) in xpubArray.enumerated() {
            
            if xpub.contains("/48'/1'/0'/2'") || xpub.contains("/48'/0'/0'/2'") {
                prefix = "wsh(sortedmulti(\(requiredSigs),"
                
            } else if xpub.contains("/48'/1'/0'/1'") || xpub.contains("/48'/0'/0'/1'") {
                prefix = "sh(sortedmulti(\(requiredSigs),"
                
            } else if xpub.contains("/48'/1'/0'/3'") || xpub.contains("/48'/0'/0'/3'") {
                prefix = "sh(wsh(sortedmulti(\(requiredSigs),"
                
            }
            
            if i + 1 < xpubArray.count {
                xpubsWithChildKeys += xpub + "/0/*,"
                
            } else {
                xpubsWithChildKeys += xpub + "/0/*"
                
            }
                        
        }
        
        var primDesc = prefix + xpubsWithChildKeys
        
        if prefix == "sh(wsh(sortedmulti(\(requiredSigs)," {
            primDesc += ")))"
            
        } else {
            primDesc += "))"
            
        }
        
        let connectingView = ConnectingView()
        connectingView.addConnectingView(vc: self, description: "processing...")
        
        Import.importDescriptor(descriptor: primDesc) { [unowned vc = self] wallet in
            
            if wallet != nil {
                vc.walletName = wallet!["name"] as! String
                vc.recoveryDict = wallet!
                DispatchQueue.main.async { [unowned vc = self] in
                    connectingView.removeConnectingView()
                    vc.performSegue(withIdentifier: "segueConfirmMultiSigFromWords", sender: vc)
                    
                }
                
            } else {
                connectingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "error processing your xpub's")
                
            }
            
        }
        
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "segueConfirmMultiSigFromWords":
            
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                vc.walletDict = recoveryDict
                vc.isImporting = true
                vc.walletNameHash = walletName
                
            }
            
        default:
            break
            
        }
        
     }
    
}
