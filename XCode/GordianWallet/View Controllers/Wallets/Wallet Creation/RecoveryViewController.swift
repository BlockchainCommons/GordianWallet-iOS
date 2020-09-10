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
        
        let isCaptured = UIScreen.main.isCaptured
        
        if !isCaptured {
            
            setUp()
            
        } else {
            
            DispatchQueue.main.async {
                            var alertStyle = UIAlertController.Style.actionSheet
                            if (UIDevice.current.userInterfaceIdiom == .pad) {
                              alertStyle = UIAlertController.Style.alert
                            }
                let alert = UIAlertController(title: "Security Alert!", message: "Your device is taking a screen recording, for security we can not display your recovery kit, please stop the recording.", preferredStyle: alertStyle)

                alert.addAction(UIAlertAction(title: "I stopped it", style: .default, handler: { [unowned vc = self] action in
                    
                    let isCaptured1 = UIScreen.main.isCaptured
                    
                    if !isCaptured1 {
                        
                        vc.setUp()
                        
                    } else {
                        
                        showAlert(vc: vc, title: "Still recording!", message: "You should delete this wallet and start over, your device may be compromised.")
                        
                    }
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        
                self.present(alert, animated: true, completion: nil)
                
            }
            
        }
        
    }
    
    func setUp() {
        
        nextButtonOutlet.clipsToBounds = true
        nextButtonOutlet.layer.cornerRadius = 10
        textView.isEditable = false
        textView.isSelectable = true
        
        var wordsToDisplay = ""
        let arr = recoveryPhrase.split(separator: " ")
        
        for (i, word) in arr.enumerated() {
            
            wordsToDisplay += "\(i + 1). \(word) "
        }
        
        textView.text = wordsToDisplay
        let qrGen = QRGenerator()
        let (qr, error) = qrGen.getQRCode(textInput: descriptor)
        imageView.image = qr
        
        if error {
            
            showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
            
        }
        
        tapQRGesture = UITapGestureRecognizer(target: self,
                                              action: #selector(shareQRCode(_:)))
        
        imageView.addGestureRecognizer(tapQRGesture)
        
        imageView.isUserInteractionEnabled = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        showAlert(vc: self, title: "Success!", message: "Multi signature wallet created successfully!\n\nEnsure you save BOTH THE RECOVERY PHRASE AND RecoveryQR Code which can be used to recover the 2 of 3 multi signature wallet in the event that you lose your device *AND* your node.")
    }
    
    @IBAction func moreInfo(_ sender: Any) {
        
        let url = URL(string: "https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Recovery.md")!
        UIApplication.shared.open(url) { (Bool) in }
        
    }
    
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        print("shareQRCode")
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                
                vc.imageView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                    
                    vc.imageView.alpha = 1
                    
                })
                
            }
            
            let objectsToShare = [self.imageView.image]
            let activityController = UIActivityViewController(activityItems: objectsToShare as [Any], applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = self.view
            activityController.popoverPresentationController?.sourceRect = self.view.bounds
            self.present(activityController, animated: true) {}
            
        }
        
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.onDoneBlock2!(true)
            self.dismiss(animated: true, completion: nil)
        }
                    
    }

}
