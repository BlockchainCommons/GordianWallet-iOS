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
    @IBOutlet weak var picker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        picker.delegate = self
        picker.dataSource = self
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return seedArray.count
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requiredSigs = row + 1
        
        if xpubArray.count == 0 {
            DispatchQueue.main.async { [unowned vc = self] in
                
                let alert = UIAlertController(title: "Recover \(vc.requiredSigs) of \(vc.seedArray.count) now?", message: "", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Recover now", style: .default, handler: { action in
                    vc.buildWallet()
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                alert.popoverPresentationController?.sourceView = self.view
                vc.present(alert, animated: true, completion: nil)
                
            }
            
        } else {
            DispatchQueue.main.async { [unowned vc = self] in
                
                let alert = UIAlertController(title: "Recover \(vc.requiredSigs) of \(vc.xpubArray.count) now?", message: "", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Recover now", style: .default, handler: { action in
                    vc.buildWalletFromXpubs()
                    
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
                
                MnemonicCreator.convert(words: seed) { [unowned vc = self] (mnemonic, error) in
                    
                    if mnemonic != nil {
                        var pathString = "m/48'/0'/0'/2'"
                        
                        if network == .testnet {
                            pathString = "m/48'/1'/0'/2'"
                        }
                        
                        vc.recoveryDict["derivation"] = pathString
                        vc.recoveryDict["id"] = UUID()
                        vc.recoveryDict["isActive"] = false
                        vc.recoveryDict["lastUsed"] = Date()
                        vc.recoveryDict["lastBalance"] = 0.0
                        vc.recoveryDict["isArchived"] = false
                        
                        if let path = BIP32Path(pathString) {
                            
                            let seed = mnemonic!.seedHex("")
                            
                            if let mk = HDKey(seed, network) {
                                let fingerprint = mk.fingerprint.hexString
                                
                                do {
                                    
                                    let account = try mk.derive(path)
                                    let pathWithFingerprint = pathString.replacingOccurrences(of: "m", with: fingerprint)
                                    
                                    
                                    if i + 1 == vc.seedArray.count {
                                        let key = "[\(pathWithFingerprint)]\(account.xpub)/0/*"
                                        vc.keys += key
                                        vc.buildDescriptors()
                                        
                                    } else {
                                        let key = "[\(pathWithFingerprint)]\(account.xpub)/0/*,"
                                        vc.keys += key
                                        
                                    }
                                    
                                } catch {
                                    
                                }
                                
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
                var network = Network.mainnet
                
                if chain == "testnet" {
                    network = .testnet
                    
                }
                
                getKeys(network: network)
                
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
                                vc.recoveryDict["changeDescriptor"] = changeDescriptor
                                vc.recoveryDict["birthdate"] = keyBirthday()
                                vc.recoveryDict["type"] = "MULTI"
                                vc.recoveryDict["blockheight"] = Int32(1)
                                vc.recoveryDict["maxRange"] = 2500
                                vc.walletName = Encryption.sha256hash(primaryDescriptor)
                                vc.recoveryDict["name"] = vc.walletName
                                
                                for (i, seed) in vc.seedArray.enumerated() {
                                    let seedData = seed.dataUsingUTF8StringEncoding
                                    
                                    Encryption.encryptData(dataToEncrypt: seedData) { (encryptedData, error) in
                                        
                                        if encryptedData != nil {
                                            let dict = ["seed":encryptedData!,"id":UUID(), "birthdate": Date()] as [String : Any]
                                            
                                            CoreDataService.saveEntity(dict: dict, entityName: .seeds) { (success, errorDescription) in
                                                
                                                if success {
                                                    
                                                    if i + 1 == vc.seedArray.count {
                                                        DispatchQueue.main.async { [unowned vc = self] in
                                                            vc.performSegue(withIdentifier: "segueConfirmMultiSigFromWords", sender: vc)
                                                            
                                                        }
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
    
    private func buildWalletFromXpubs() {
        
        
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
