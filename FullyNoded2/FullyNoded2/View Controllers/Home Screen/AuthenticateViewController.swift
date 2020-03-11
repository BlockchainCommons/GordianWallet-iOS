//
//  AuthenticateViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class AuthenticateViewController: UIViewController {
    
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
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
    func getpubkey() {
        
        let cd = CoreDataService()
        cd.retrieveEntity(entityName: .auth) { (authKeys, errorDescription) in
            
            // add new authkeys incase none exist
            func addAuthKeys() {
                
                let keygen = KeyGen()
                keygen.generate { (pubkey, privkey) in
                    
                    if pubkey != nil && privkey != nil {
                        
                        let pubkeyData = pubkey!.dataUsingUTF8StringEncoding
                        let privkeyData = privkey!.dataUsingUTF8StringEncoding
                        let enc = Encryption()
                        enc.encryptData(dataToEncrypt: privkeyData) { (encryptedPrivkey, error) in
                            
                            if !error {
                                
                                let dict = ["privkey":encryptedPrivkey!, "pubkey":pubkeyData]
                                let cd = CoreDataService()
                                cd.saveEntity(dict: dict, entityName: .auth) {
                                    
                                    if !cd.errorBool {
                                        
                                        self.pubkey = "descriptor:x25519:" + pubkey!
                                        self.showDescriptor()
                                        
                                    } else {
                                        
                                        displayAlert(viewController: self, isError: true, message: "error saving auth keys")
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                displayAlert(viewController: self, isError: true, message: "error encrypting your privkey")
                                
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
                        self.pubkey = "descriptor:x25519:" + str
                        self.showDescriptor()
                        
                    } else {
                        
                        addAuthKeys()
                        
                    }
                    
                } else {
                    
                    addAuthKeys()
                    
                }
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "error getting authkeys")
                
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
        
        DispatchQueue.main.async {
            
            self.displayer.rawString = self.pubkey
            self.displayer.addRawDisplay()
            
        }
        
    }
    
    @objc func shareRawText(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.displayer.textView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.displayer.textView.alpha = 1
                    
                })
                
            }
                            
            let textToShare = [self.pubkey]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.displayer.qrView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.displayer.qrView.alpha = 1
                    
                })
                
            }
            
            self.qrGenerator.textInput = self.displayer.rawString
            let qrImage = self.qrGenerator.getQRCode()
            let objectsToShare = [qrImage]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = self.view
            self.present(activityController, animated: true) {}
            
        }
        
    }

}
