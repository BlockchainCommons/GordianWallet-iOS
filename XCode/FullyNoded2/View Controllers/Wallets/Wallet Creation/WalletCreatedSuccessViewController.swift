//
//  WalletCreatedSuccessViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletCreatedSuccessViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate {

    @IBOutlet var textView: UITextView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var nextOutlet: UIButton!
    
    let tap = UITapGestureRecognizer()
    var wallet = [String:Any]()
    var recoveryPhrase = ""
    var nodesWords = ""
    var recoveryQr = ""
    var isColdcard = Bool()
    var w:WalletStruct!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        hideBackButton()
        textView.delegate = self
        textField.delegate = self
        textView.isEditable = false
        textView.isSelectable = false
        nextOutlet.layer.cornerRadius = 8
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        
        w = WalletStruct(dictionary: wallet)
        
        if w.type == "MULTI" {
            
            textView.text = "In order to recover your account there is some information you ought to save securely.\n\nYou will be presented with an \"Account Map\" QR code (the account public keys) and two 12 word seed phrases.\n\nIt is recommended you store the seed phrases in different locations, if they are stored together a thief may be able to access your funds.\n\nSaving both the \"Account Map QR\" and the two seed phrase's will ensure you can fully recover your multi-signature account if this device were to be lost or stolen."
            
        } else {
            
            textView.text = "In order to ensure you can recover your account there is some information you ought to record securely.\n\nYou will be presented with an \"Account Map\" QR code and a 12 word seed phrase.\n\nYou should make multiple backups of each and store them securely."
            
        }
        
        if isColdcard {
            textField.text = "COLDCARD 2 OF 3"
            
        } else {
            textField.text = ""
            
        }
        
    }
    
    private func hideBackButton() {
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
    }
    
    @objc func handleTap() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.textField.resignFirstResponder()
            
        }
        
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        if textField.text != "" {
            
            if textField.text!.count > 50 {
                
                showAlert(vc: self, title: "That label is too long", message: "Please keep it short and memorable, less than 50 characters")
                
            } else {
                
                CoreDataService.updateEntity(id: w.id!, keyToUpdate: "label", newValue: textField.text!, entityName: .wallets) { [unowned vc = self] (success, errorDesc) in
                    
                    if success {
                        
                        DispatchQueue.main.async {
                            
                            vc.performSegue(withIdentifier: "toRecoveryQr", sender: vc)
                            
                        }
                        
                    } else {
                        
                        showAlert(vc: vc, title: "Error", message: errorDesc ?? "error saving label")
                        
                    }
                    
                }
                
            }
            
        } else {
            
            shakeAlert(viewToShake: textField)
            
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.text != "" {
            
            saveLabel()
            
        }
        
        textField.resignFirstResponder()
                
        return true
        
    }
    
    @objc func saveLabel() {
        
        if textField.text != "" {
            
            if textField.text!.count > 50 {
                
                showAlert(vc: self, title: "That label is too long", message: "Please keep it short and memorable, less then 50 characters")
                
            } else {
                
                CoreDataService.updateEntity(id: w.id!, keyToUpdate: "label", newValue: textField.text!, entityName: .wallets) { [unowned vc = self] (success, errorDesc) in
                    
                    if success {
                        
                        displayAlert(viewController: vc, isError: false, message: "Label saved")
                        
                    } else {
                        
                        displayAlert(viewController: vc, isError: true, message: "Label not saved")
                        
                    }
                    
                }
                
            }
            
        } else {
            
            shakeAlert(viewToShake: textField)
            
        }
        
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "toRecoveryQr":
            
            if let vc = segue.destination as? WalletCreatedQRViewController {
                vc.isColdcard = isColdcard
                vc.nodesWords = self.nodesWords
                vc.recoveryPhrase = self.recoveryPhrase
                vc.recoveryQr = self.recoveryQr.replacingOccurrences(of: "\"label\":\"\"", with: "\"label\":\"\(textField.text!)\"")
                vc.wallet = self.wallet
            }
            
        default:
            break
        }
    }
    

}
