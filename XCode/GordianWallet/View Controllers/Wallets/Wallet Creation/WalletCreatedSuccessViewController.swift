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
    @IBOutlet weak var imageView: UIImageView!
    
    let tap = UITapGestureRecognizer()
    var wallet = [String:Any]()
    var recoveryPhrase = ""
    var nodesWords = ""
    var recoveryQr = ""
    var isColdcard = Bool()
    var w:WalletStruct!
    var isOnlyAddingLabel = Bool()
    
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
        imageView.layer.magnificationFilter = .nearest
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        
        w = WalletStruct(dictionary: wallet)
        
        if isColdcard {
            textField.text = "COLDCARD 2 OF 3"
            
        } else {
            textField.text = ""
            
        }
        if !isOnlyAddingLabel {
            if w.type == "MULTI" {
                
                textView.text = TextBlurbs.multiSigWalletCreatedSuccess()
                
            } else {
                
                textView.text = TextBlurbs.singleSigWalletCreatedSuccess()
                
            }
            deactivateAllAccountsAndActivateNewAccount()
        } else {
            textView.text = "Please add a label so you can easily differentiate this account from others."
            nextOutlet.setTitle("Done", for: .normal)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        imageView.image = LifeHash.image(w.descriptor)
    }
    
    private func deactivateAllAccountsAndActivateNewAccount() {
        CoreDataService.retrieveEntity(entityName: .wallets) { [unowned vc = self] (wallets, errorDescription) in
            if wallets != nil {
                if wallets!.count > 0 {
                    for (i, wallet) in wallets!.enumerated() {
                        let walletStruct = WalletStruct(dictionary: wallet)
                        if walletStruct.id != nil {
                            if walletStruct.id != vc.w.id! {
                                CoreDataService.updateEntity(id: walletStruct.id!, keyToUpdate: "isActive", newValue: false, entityName: .wallets) { _ in }
                            } else {
                                CoreDataService.updateEntity(id: vc.w.id!, keyToUpdate: "isActive", newValue: true, entityName: .wallets) { _ in }
                            }
                            if i + 1 == wallets!.count {
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .didCreateAccount, object: nil, userInfo: nil)
                                }
                            }
                        }
                    }
                }
            }
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
                        
                        if vc.isOnlyAddingLabel {
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .didUpdateLabel, object: nil, userInfo: nil)
                                vc.navigationController?.popToRootViewController(animated: true)
                            }
                        } else {
                            DispatchQueue.main.async {
                                vc.performSegue(withIdentifier: "toRecoveryQr", sender: vc)
                            }
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
