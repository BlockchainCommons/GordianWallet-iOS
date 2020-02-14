//
//  RecoveryViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 15/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class RecoveryViewController: UIViewController {
    
    var tapQRGesture = UITapGestureRecognizer()
    var recoveryPhrase = ""
    var descriptor = ""
    var onDoneBlock2 : ((Bool) -> Void)?
    var recoveryPubkey = ""
    @IBOutlet var textView: UITextView!
    @IBOutlet var nextButtonOutlet: UIButton!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButtonOutlet.clipsToBounds = true
        nextButtonOutlet.layer.cornerRadius = 10
        textView.isEditable = false
        textView.isSelectable = true
        textView.text = recoveryPhrase
        let qrGen = QRGenerator()
        qrGen.textInput = descriptor
        imageView.image = qrGen.getQRCode()
        
        tapQRGesture = UITapGestureRecognizer(target: self,
                                              action: #selector(shareQRCode(_:)))
        
        imageView.addGestureRecognizer(tapQRGesture)
        
        imageView.isUserInteractionEnabled = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        showAlert(vc: self, title: "Success!", message: "Multi signature wallet created successfully!\n\nEnsure you save BOTH THE RECOVERY PHRASE AND DESCRIPTOR which can be used to recover the 2 of 3 multi signature wallet in the event that you lose your device or your node.")
    }
    
//    func createRecoveryKey() {
//
//        let keychainCreator = KeychainCreator()
//        keychainCreator.createKeyChain { (mnemonic, error) in
//
//            if !error {
//
//                DispatchQueue.main.async {
//
//                    self.textView.text = mnemonic!
//
//                }
//
//                self.getMnemonic(words: mnemonic!)
//
//            } else {
//
//                displayAlert(viewController: self, isError: true, message: "error creating your recovery key")
//
//            }
//
//        }
//
//    }
//
//    func getMnemonic(words: String) {
//
//        let mnemonicCreator = MnemonicCreator()
//        mnemonicCreator.convert(words: words) { (mnemonic, error) in
//
//            if !error {
//
//                self.getXpub(mnemonic: mnemonic!)
//
//            } else {
//
//                displayAlert(viewController: self, isError: true, message: "error getting xpub from your recovery key")
//
//            }
//
//        }
//
//    }
//
//    func getXpub(mnemonic: BIP39Mnemonic) {
//
//        if let masterKey = HDKey((mnemonic.seedHex("")), self.network(path: "m/84'/1'/0'/0")) {
//
//            if let path = BIP32Path("m/84'/1'/0'/0") {
//
//                do {
//
//                    let account = try masterKey.derive(path)
//                    self.recoveryPubkey = account.xpub
//
//                } catch {
//
//                    displayAlert(viewController: self, isError: true, message: "failed deriving xpub")
//
//                }
//
//            } else {
//
//                displayAlert(viewController: self, isError: true, message: "failed initiating bip32 path")
//
//            }
//
//        } else {
//
//            displayAlert(viewController: self, isError: true, message: "failed creating masterkey")
//
//        }
//
//
//    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        print("shareQRCode")
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.imageView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.imageView.alpha = 1
                    
                })
                
            }
            
            let objectsToShare = [self.imageView.image]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare as [Any],
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = self.view
            self.present(activityController, animated: true) {}
            
        }
        
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        //if self.recoveryPubkey != "" {
            
            DispatchQueue.main.async {
                
                //self.performSegue(withIdentifier: "descriptor", sender: self)
                self.onDoneBlock2!(true)
                self.dismiss(animated: true, completion: nil)
            }
            
        //}
        
    }
    
//    private func network(path: String) -> Network {
//
//        var network:Network!
//
//        if path.contains("/1'") {
//
//            network = .testnet
//
//        } else {
//
//            network = .mainnet
//
//        }
//
//        return network
//
//    }
    
    
    // MARK: - Navigation

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        let id = segue.identifier
//
//        switch id {
//
//        case "descriptor":
//
//            if let vc = segue.destination as? MultiSigDescriptorViewController {
//
//                vc.recoveryPubkey = recoveryPubkey
//
//                vc.onDoneBlock3 = { result in
//
//                    DispatchQueue.main.async {
//                        self.view.alpha = 0
//                        self.onDoneBlock2!(true)
//                        self.dismiss(animated: false, completion: nil)
//
//                    }
//
//                }
//
//            }
//
//        default:
//
//            break
//
//        }
//
//    }
    

}
