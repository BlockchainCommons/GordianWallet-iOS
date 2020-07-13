//
//  AddExtendedKeyViewController.swift
//  FullyNoded2
//
//  Created by Peter on 22/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class AddExtendedKeyViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var xpubLabel: UILabel!
    @IBOutlet weak var fingerprintLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var nextOutlet: UIButton!
    @IBOutlet weak var textView: UITextView!
    var isPathless = Bool()
    let tap = UITapGestureRecognizer()
    var wallet:WalletStruct!
    var onDoneBlock: (([String:String]) -> Void)?
    var isRecovering = Bool()
    var keys = [String]()
    var walletToRecover = [String:Any]()
    var name = ""
    var isRecoveringMulti = false
    var cointType = "0"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        
        if isRecovering {
            textField.alpha = 0
            fingerprintLabel.alpha = 0
            xpubLabel.text = "extended key with optional path and fingerprint:"
            showAlert(vc: self, title: "Add your account xpub or xprv", message: "Ideally, when recovering a wallet with extended keys you can paste in the key with its path and master key fingerprint.\n\nExample: \n\n[UTYR63H/84'/0'/0']xpub7dk20b5bs4..., otherwise we will prompt you to choose a derivation scheme and assume the key is an account and utilize the fingerprint of the supplied key. You may add multiple sets of keys as long as they are comma seperated.")
            
        } else {
            formatLabel.alpha = 0
            textField.alpha = 1
            fingerprintLabel.alpha = 1
            xpubLabel.text = "xpub:"
            
        }
        
        textView.delegate = self
        nextOutlet.layer.cornerRadius = 8
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.darkGray.cgColor
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 4
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        
    }
        
    private func createDescriptors() {
        
        if textView.text != "" && textField.text != "" {
            
            if !isRecovering {
                
                if textField.text!.count == 8 {
                    
                    func checkKey(key: String) {
                        
                        if let _ = HDKey(key) {
                            let dict = ["key":key, "fingerprint":textField.text!]
                            DispatchQueue.main.async { [unowned vc = self] in
                                vc.onDoneBlock!((dict))
                                vc.navigationController!.popViewController(animated: true)
                                
                            }
                            
                        } else {
                            showAlert(vc: self, title: "Invalid xpub!", message: TextBlurbs.invalidXpubWarning())
                            
                        }
                    }
                    
                    if !textView.text.hasPrefix("tpub") && !textView.text.hasPrefix("xpub") {
                        
                        if let convertedKey = XpubConverter.convert(extendedKey: textView.text) {
                            checkKey(key: convertedKey)
                            
                        }
                        
                    } else {
                        checkKey(key: textView.text)
                        
                    }
                    
                } else {
                    showAlert(vc: self, title: "Only xpubs allowed here", message: TextBlurbs.onlyXpubsHereWarning())
                    
                }
            }
            
        } else if textView.text != "" && isRecovering {
            processRecoveryKey()
            
        } else {
            shakeAlert(viewToShake: textView)
            
        }
    }
    
    @objc func handleTap() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.textView.resignFirstResponder()
            
        }
    }
    
    @IBAction func nextAction(_ sender: Any) {
        createDescriptors()
        
    }
    
    private func processRecoveryKey() {
        var key = textView.text!
        key = key.condenseWhitespace()
        key = key.replacingOccurrences(of: "’", with: "'")
        if key.contains("tpub") || key.contains("tprv") {
            cointType = "1"
        }
        if key.contains("xpub") || key.contains("tpub") || key.contains("xprv") || key.contains("tprv") {
            processExtendedKey(key: key)
        } else {
            showAlert(vc: self, title: "Error", message: "That is not an xpub or xprv")
        }
    }
    
    private func processPath(key: String) -> Bool {
        let xpub = "\(key.split(separator: "]")[1])"
        let path = "\(key.split(separator: "]")[0])"
        let arr = path.split(separator: "/")
        var plainPath = "m"
        for (i, item) in arr.enumerated() {
            if i != 0 {
                plainPath += "/" + "\(item)"
            }
        }
        print("plainpath: \(plainPath)")
        print("xpub: \(xpub)")
        switch plainPath {
        case "m/48'/1'/0'/2'",
             "m/48'/0'/0'/2'",
             "m/48'/1'/0'/1'",
             "m/48'/0'/0'/1'",
             "m/48'/1'/0'/3'",
             "m/48'/0'/0'/3'",
             "m/84'/0'/0'",
             "m/84'/1'/0'",
             "m/44'/0'/0'",
             "m/44'/1'/0'",
             "m/49'/0'/0'",
             "m/49'/1'/0'":
            
            if let _ = HDKey(xpub) {
                ///Its a valid xpub
                
                if let _ = BIP32Path(plainPath) {
                    return true
                    
                } else {
                    showAlert(vc: self, title: "Invalid path", message: TextBlurbs.invalidPathWarning())
                    return false
                    
                }
                
            } else {
                showAlert(vc: self, title: "Invalid xpub", message: TextBlurbs.invalidXpubWithPathWarning())
                return false
                
            }
            
        default:
            showAlert(vc: self, title: "Unsupported path", message: TextBlurbs.unsupportedMultiSigPath())
            return false
            
        }
    }
    
    private func processExtendedKey(key: String) {
        keys.append(key)
        if key.contains("[") {
            isPathless = false
            if processPath(key: key) {
                if !isRecoveringMulti {
                    recoveringSingleOrMulti()
                } else {
                    addMoreExtendedKeys()
                }
            }
        } else {
            isPathless = true
            if !isRecoveringMulti {
                recoveringSingleOrMulti()
            } else {
                addMoreExtendedKeys()
            }
        }
    }
    
    private func processXprv(xprv: String) {
    
    }
    
    private func addAnotherExtendedKey() {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "You may add another xpub", message: "", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func recoveringSingleOrMulti() {
        DispatchQueue.main.async { [unowned vc = self] in
                        
            let alert = UIAlertController(title: "That is a valid extended key", message: "Are you recovering a multi-sig account or single-sig account?", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Single-sig", style: .default, handler: { action in
                if vc.isPathless {
                    vc.chooseDerivation()
                } else {
                    vc.recoverSingleSigNow()
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Multi-sig", style: .default, handler: { action in
                /// Clear the textview and let them add another.
                vc.textView.text = ""
                vc.isRecoveringMulti = true
                vc.addAnotherExtendedKey()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            vc.present(alert, animated: true, completion: nil)
            
        }
    }
    
    private func addMoreExtendedKeys() {
        DispatchQueue.main.async { [unowned vc = self] in
                        
            let alert = UIAlertController(title: "Add another xpub?", message: "", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Add more", style: .default, handler: { action in
                vc.textView.text = ""
                vc.addAnotherExtendedKey()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Recover now", style: .default, handler: { action in
                /// Clear the textview and let them add another.
                vc.recoverMultisigNow()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            vc.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    private func fingerprint(key: String) -> String? {
        if let hdKey = HDKey(key) {
            return hdKey.fingerprint.hexString
        } else {
            return nil
        }
    }
    
    private func chooseDerivation() {
        
        func addPath(deriv: String) {
            if fingerprint(key: keys[0]) != nil {
                let desc = "[\(fingerprint(key: "\(keys[0])")!)/\(deriv)'/\(cointType)'/0']\(keys[0])"
                keys[0] = desc
                recoverSingleSigNow()
            } else {
                showAlert(vc: self, title: "Error", message: "We could not derive a fingerprint from that extended key.")
            }
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Select a derivation to recover", message: "", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Segwit - BIP84", style: .default, handler: { action in
                addPath(deriv: "84")
            }))
            alert.addAction(UIAlertAction(title: "Nested Segwit - BIP49", style: .default, handler: { action in
                addPath(deriv: "49")
            }))
            alert.addAction(UIAlertAction(title: "Legacy - BIP44", style: .default, handler: { action in
                addPath(deriv: "44")
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func recoverMultisigNow() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToPublicKeyMultiSigSigners", sender: vc)
        }
    }
    
    private func recoverSingleSigNow() {
        let connectingView = ConnectingView()
        connectingView.addConnectingView(vc: self, description: "processing...")
        let key = keys[0]
        var prefix = ""
        
        if key.contains("/84'/") {
            prefix = "wpkh("
            
        } else if key.contains("/49'/") {
            prefix = "sh(wpkh("
            
        } else if key.contains("/44'/") {
            prefix = "pkh("
            
        }
        
        var bitcoinCoreDescriptor = prefix + key + "/0/*)"
        
        if prefix == "sh(wpkh(" {
            bitcoinCoreDescriptor += ")"
            
        }
        
        print("bitcoinCoreDescriptor: \(bitcoinCoreDescriptor)")
        
        Import.importDescriptor(descriptor: bitcoinCoreDescriptor) { [unowned vc = self] wallet in
            
            if wallet != nil {
                DispatchQueue.main.async { [unowned vc = self] in
                    connectingView.removeConnectingView()
                    vc.walletToRecover = wallet!
                    vc.name = wallet!["name"] as! String
                    vc.performSegue(withIdentifier: "goConfirmManualXpubRecovery", sender: vc)
                    
                }
                
            } else {
                connectingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "There was an error deriving your account")
                
            }
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "goConfirmManualXpubRecovery":
            
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                vc.isImporting = true
                vc.walletNameHash = name
                vc.walletDict = walletToRecover
                
            }
            
        case "segueToPublicKeyMultiSigSigners":
            
            if let vc = segue.destination as? ChooseNumberOfSignersViewController {
                
                vc.xpubArray = keys
                
            }
            
        default:
            break
            
        }
    }

}
