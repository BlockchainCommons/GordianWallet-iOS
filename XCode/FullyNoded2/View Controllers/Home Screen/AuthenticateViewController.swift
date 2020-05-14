//
//  AuthenticateViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class AuthenticateViewController: UIViewController, UINavigationControllerDelegate {
    
    var pubkey = ""
    var tapQRGesture = UITapGestureRecognizer()
    var tapTextViewGesture = UITapGestureRecognizer()
    let displayer = RawDisplayer()
    let qrGenerator = QRGenerator()
    var isadding = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        configureDisplayer()
        
    }
    
    func getpubkey() {
        
        CoreDataService.retrieveEntity(entityName: .auth) { [unowned vc = self] (authKeys, errorDescription) in
            
            // add new authkeys incase none exist
            func addAuthKeys() {
                
                let keypair = KeyGen.generate()
                let pubkeyData = keypair.pubKey.dataUsingUTF8StringEncoding
                let privkeyData = keypair.privKey.dataUsingUTF8StringEncoding
                Encryption.encryptData(dataToEncrypt: privkeyData) { (encryptedPrivkey, error) in
                    
                    if !error {
                        
                        let dict = ["privkey":encryptedPrivkey!, "pubkey":pubkeyData]
                        CoreDataService.saveEntity(dict: dict, entityName: .auth) { [unowned vc = self] (success, errorDescription) in
                            
                            if success {
                                
                                vc.pubkey = "descriptor:x25519:" + vc.pubkey
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
        displayer.y = 100
        tapQRGesture = UITapGestureRecognizer(target: self,
                                              action: #selector(shareQRCode(_:)))
        
        displayer.qrView.addGestureRecognizer(tapQRGesture)
        
        tapTextViewGesture = UITapGestureRecognizer(target: self,
                                                    action: #selector(shareRawText(_:)))
        
        displayer.copyButton.addTarget(self, action: #selector(copyText), for: .touchUpInside)
        displayer.shareButton.addTarget(self, action: #selector(shareQRCode(_:)), for: .touchUpInside)
        
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
    
    @objc func copyText() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            let pasteboard = UIPasteboard.general
            pasteboard.string = vc.pubkey
            displayAlert(viewController: vc, isError: false, message: "authentication key copied to clipboard")
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
            
            let qrImage = vc.qrGenerator.getQRCode(textInput: vc.displayer.rawString).qr
            let objectsToShare = [qrImage]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = vc.view
            vc.present(activityController, animated: true) {}
            
        }
        
    }

}
