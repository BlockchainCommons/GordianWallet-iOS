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
    let tap = UITapGestureRecognizer()
    var wallet:WalletStruct!
    var onDoneBlock: (([String:String]) -> Void)?
    var isRecovering = Bool()
    var keys = [String]()
    var walletToRecover = [String:Any]()
    var name = ""
    var isRecoveringMulti = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        
        if isRecovering {
            textField.alpha = 0
            fingerprintLabel.alpha = 0
            xpubLabel.text = "xpub with path and fingerprint:"
            showAlert(vc: self, title: "Add your xpub", message: "When recovering a wallet with xpubs you need to paste in the xpub with its path and master key fingerprint.\n\nExample: \n\n[UTYR63H/84'/0'/0']xpub7dk20b5bs4...")
            
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
            processRecoveryXpub()
            
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
    
    private func processRecoveryXpub() {
        
        let key = textView.text!
        
        if key.contains("[") && key.contains("]") {
            
            let xpub = "\(key.split(separator: "]")[1])"
            let path = "\(key.split(separator: "]")[0])"
            let arr = path.split(separator: "/")
            var plainPath = "m"
            
            for (i, item) in arr.enumerated() {
                
                if i != 0 {
                    plainPath += "/" + "\(item)"
                    
                }
                
            }
            
            switch plainPath {
            case "m/48'/1'/0'/2'",
                 "m/48'/0'/0'/2'",
                 "m/48'/1'/0'/1'",
                 "m/48'/0'/0'/1'",
                 "m/48'/1'/0'/3'",
                 "m/48'/0'/0'/3'":
                
                if let _ = HDKey(xpub) {
                    ///Its a valid xpub
                    
                    if let _ = BIP32Path(plainPath) {
                        ///Its all good in the hood.
                        keys.append(key)
                        if !isRecoveringMulti {
                            recoveringSingleOrMulti()
                            
                        } else {
                            addMoreXpubs()
                            
                        }
                        
                    } else {
                        showAlert(vc: self, title: "Invalid path", message: TextBlurbs.invalidPathWarning())
                        
                    }
                    
                } else {
                    showAlert(vc: self, title: "Invalid xpub", message: TextBlurbs.invalidXpubWithPathWarning())
                    
                }
                
            default:
                showAlert(vc: self, title: "Unsupported path", message: TextBlurbs.unsupportedMultiSigPath())
                
            }
            
        } else {
            showAlert(vc: self, title: "Invalid recovery format", message: TextBlurbs.invalidRecoveryFormat())
            
        }
        
    }
    
    private func addAnotherXpub() {
        DispatchQueue.main.async { [unowned vc = self] in
                        
            let alert = UIAlertController(title: "You may add another xpub", message: "", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            vc.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    private func recoveringSingleOrMulti() {
        DispatchQueue.main.async { [unowned vc = self] in
                        
            let alert = UIAlertController(title: "That is a valid recovery xpub", message: "Are you recovering a multi-sig account or single-sig account?", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Single-sig", style: .default, handler: { action in
                /// We are done. Construct descriptors and import them.
                vc.recoverSingleSigWithJustanXpub()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Multi-sig", style: .default, handler: { action in
                /// Clear the textview and let them add another.
                vc.textView.text = ""
                vc.isRecoveringMulti = true
                vc.addAnotherXpub()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            vc.present(alert, animated: true, completion: nil)
            
        }
    }
    
    private func addMoreXpubs() {
        DispatchQueue.main.async { [unowned vc = self] in
                        
            let alert = UIAlertController(title: "Add another xpub?", message: "", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Add more", style: .default, handler: { action in
                vc.textView.text = ""
                vc.addAnotherXpub()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Recover now", style: .default, handler: { action in
                /// Clear the textview and let them add another.
                vc.recoverMultisigWithJustXpubsNow()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            vc.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    private func recoverMultisigWithJustXpubsNow() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToPublicKeyMultiSigSigners", sender: vc)
            
        }
        
    }
    
    private func recoverSingleSigWithJustanXpub() {
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
