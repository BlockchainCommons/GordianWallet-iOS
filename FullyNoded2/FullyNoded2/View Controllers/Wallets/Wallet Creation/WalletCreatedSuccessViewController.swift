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
    var recoveryQr = ""
    var w:WalletStruct!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        setTitleView()
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
            
            textView.text = "In order to recover your wallet there is some information you ought to save securely.\n\nYou will be presented with a RecoveryQR code (your devices seed) and a 12 word recovery phrase (the offline backup seed).\n\nIt is recommended you store these two items in different locations.\n\nSaving both the RecoveryQR and the 12 word recovery phrase will ensure you can fully recover your multi-signature wallet *even* if you lose your device *AND* your node."
            
        } else {
            
            textView.text = "In order to ensure you can recover your wallets there is some information you ought to record securely.\n\nYou will be presented with a RecoveryQR code and a 12 word recovery phrase.\n\nYou should make mutliple backups of each and store them in seperate locations."
            
        }
        
    }
    
    private func setTitleView() {
        
        let imageView = UIImageView(image: UIImage(named: "1024.png"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
        
    }
    
    private func hideBackButton() {
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
    }
    
    @objc func handleTap() {
        
        DispatchQueue.main.async {
            
            self.textField.resignFirstResponder()
            
        }
        
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        if textField.text != "" {
            
            let cd = CoreDataService()
            cd.updateEntity(id: w.id, keyToUpdate: "label", newValue: textField.text!, entityName: .wallets) {
                
                DispatchQueue.main.async {
                    
                    self.performSegue(withIdentifier: "toRecoveryQr", sender: self)
                    
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
            
            let cd = CoreDataService()
            cd.updateEntity(id: w.id, keyToUpdate: "label", newValue: textField.text!, entityName: .wallets) {
                
                if !cd.errorBool {
                    
                    displayAlert(viewController: self.navigationController!, isError: false, message: "Label saved")
                    
                } else {
                    
                    displayAlert(viewController: self.navigationController!, isError: true, message: "Label not saved")
                    
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
                
                vc.recoveryPhrase = self.recoveryPhrase
                vc.recoveryQr = self.recoveryQr.replacingOccurrences(of: "\"label\":\"\"", with: "\"label\":\"\(textField.text!)\"")
                vc.wallet = self.wallet
            }
            
        default:
            break
        }
    }
    

}
