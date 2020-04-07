//
//  AuthenticateViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class AuthenticateViewController: UIViewController {
    
    let cd = CoreDataService.sharedInstance
    var pubkey = ""
    var tapQRGesture = UITapGestureRecognizer()
    var tapTextViewGesture = UITapGestureRecognizer()
    let displayer = RawDisplayer()
    let qrGenerator = QRGenerator()
    var isadding = Bool()
    @IBOutlet var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        configureDisplayer()
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
    func getpubkey() {
        
        cd.retrieveEntity(entityName: .auth) { [unowned vc = self] (authKeys, errorDescription) in
            
            // add new authkeys incase none exist
            func addAuthKeys() {
                
                let keygen = KeyGen()
                keygen.generate { (pubkey, privkey) in
                    
                    if pubkey != nil && privkey != nil {
                        
                        let pubkeyData = pubkey!.dataUsingUTF8StringEncoding
                        let privkeyData = privkey!.dataUsingUTF8StringEncoding
                        let enc = Encryption.sharedInstance
                        enc.encryptData(dataToEncrypt: privkeyData) { (encryptedPrivkey, error) in
                            
                            if !error {
                                
                                let dict = ["privkey":encryptedPrivkey!, "pubkey":pubkeyData]
                                vc.cd.saveEntity(dict: dict, entityName: .auth) { (success, errorDescription) in
                                    
                                    if success {
                                        
                                        vc.pubkey = "descriptor:x25519:" + pubkey!
                                        vc.showDescriptor()
                                        
                                    } else {
                                        
                                        displayAlert(viewController: vc, isError: true, message: "error saving auth keys")
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                displayAlert(viewController: vc, isError: true, message: "error encrypting your privkey")
                                
                            }
                            
                        }
                        
                        
                    }
                    
                }
                
            }
            
            if errorDescription == nil {
                
                if authKeys != nil {
                    
                    if authKeys!.count > 0 {
                        
                        let pubkey = authKeys![0]["pubkey"] as! Data
                        let str = String(bytes: pubkey, encoding: .utf8)!
                        vc.pubkey = "descriptor:x25519:" + str
                        vc.showDescriptor()
                        
                    } else {
                        
                        addAuthKeys()
                        
                    }
                    
                } else {
                    
                    addAuthKeys()
                    
                }
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: "error getting authkeys")
                
            }
            
        }
        
    }

    func configureDisplayer() {
                
        displayer.vc = self
        displayer.y = self.descriptionLabel.frame.maxY + 10
        tapQRGesture = UITapGestureRecognizer(target: self,
                                              action: #selector(shareQRCode(_:)))
        
        displayer.qrView.addGestureRecognizer(tapQRGesture)
        
        tapTextViewGesture = UITapGestureRecognizer(target: self,
                                                    action: #selector(shareRawText(_:)))
        
        displayer.textView.addGestureRecognizer(tapTextViewGesture)
        displayer.textView.isSelectable = true
        getpubkey()
        
    }
    
    func showDescriptor() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.displayer.rawString = vc.pubkey
            vc.displayer.addRawDisplay()
            
        }
        
    }
    
    @objc func shareRawText(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            UIView.animate(withDuration: 0.2, animations: {
                
                vc.displayer.textView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    vc.displayer.textView.alpha = 1
                    
                })
                
            }
                            
            let textToShare = [vc.pubkey]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = vc.view
            vc.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            UIView.animate(withDuration: 0.2, animations: {
                
                vc.displayer.qrView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    vc.displayer.qrView.alpha = 1
                    
                })
                
            }
            
            let qrImage = vc.qrGenerator.getQRCode(textInput: vc.displayer.rawString)
            let objectsToShare = [qrImage]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = vc.view
            vc.present(activityController, animated: true) {}
            
        }
        
    }

}
