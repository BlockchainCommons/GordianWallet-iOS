//
//  WalletCreatedQRViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletCreatedQRViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var qrView: UIImageView!
    @IBOutlet var nextOutlet: UIButton!
    
    var nodesWords = ""
    var wallet = [String:Any]()
    var recoveryPhrase = ""
    var recoveryQr = ""
    var tapQRGesture = UITapGestureRecognizer()
    
    let qrGenerator = QRGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        let (qr, error) = qrGenerator.getQRCode(textInput: recoveryQr)
        qrView.image = qr
        
        if error {
            showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that sized image")
            
        }
        
        nextOutlet.layer.cornerRadius = 8
        qrView.isUserInteractionEnabled = true
        tapQRGesture = UITapGestureRecognizer(target: self, action: #selector(self.shareQRCode(_:)))
        qrView.addGestureRecognizer(tapQRGesture)
        
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "goWords", sender: vc)
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                
                vc.qrView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                    
                    vc.qrView.alpha = 1
                    
                })
                
            }
            
            let objectsToShare = [self.qrView.image!]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = self.view
            self.present(activityController, animated: true) {}
            
        }
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "goWords":
            
            if let vc = segue.destination as? WalletCreatedWordsViewController {
                
                vc.nodesWords = nodesWords
                vc.recoverPhrase = self.recoveryPhrase
                vc.wallet = wallet
                
            }
            
        default:
            break
        }
    }
    

}
