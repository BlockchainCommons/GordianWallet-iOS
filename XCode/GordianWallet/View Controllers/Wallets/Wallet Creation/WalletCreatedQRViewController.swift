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
    @IBOutlet weak var accountMapLabel: UITextView!
    
    var isColdcard = Bool()
    var nodesWords = ""
    var wallet = [String:Any]()
    var recoveryPhrase = ""
    var recoveryQr = ""
    var tapQRGesture = UITapGestureRecognizer()
    let qrGenerator = QRGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        nextOutlet.layer.cornerRadius = 8
        qrView.isUserInteractionEnabled = true
        tapQRGesture = UITapGestureRecognizer(target: self, action: #selector(self.shareQRCode(_:)))
        qrView.addGestureRecognizer(tapQRGesture)
        
        if wallet["type"] as! String == "MULTI" {
            accountMapLabel.text = TextBlurbs.accountMapMultiSigCreated()
            
            
        } else {
            accountMapLabel.text = TextBlurbs.accountMapSingleSigCreated()
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let (qr, error) = qrGenerator.getQRCode(textInput: recoveryQr)
        qrView.image = qr
        
        if error {
            showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that sized image")
            
        } else {
            addButtons()
            
        }
                
    }
    
    private func addButtons() {
        
        let copyButton = UIButton()
        let copyImage = UIImage(systemName: "doc.on.doc")!
        copyButton.tintColor = .systemTeal
        copyButton.setImage(copyImage, for: .normal)
        copyButton.addTarget(self, action: #selector(copyQR), for: .touchUpInside)
        copyButton.frame = CGRect(x: qrView.frame.maxX - 25, y: qrView.frame.minY - 30, width: 25, height: 25)
        view.addSubview(copyButton)
        
        let shareButton = UIButton()
        let shareImage = UIImage(systemName: "arrowshape.turn.up.right")!
        shareButton.tintColor = .systemTeal
        shareButton.setImage(shareImage, for: .normal)
        shareButton.addTarget(self, action: #selector(shareQRCode(_:)), for: .touchUpInside)
        shareButton.frame = CGRect(x: copyButton.frame.minX - 35, y: qrView.frame.minY - 30, width: 25, height: 25)
        view.addSubview(shareButton)
        
    }
    
    @objc func copyQR() {
        DispatchQueue.main.async { [unowned vc = self] in
            let pasteboard = UIPasteboard.general
            pasteboard.image = vc.qrView.image
            displayAlert(viewController: vc, isError: false, message: "QR copied to clipboard")
        }
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "goWords", sender: vc)
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                
                vc.qrView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                    
                    vc.qrView.alpha = 1
                    
                })
                
            }
            
            let objectsToShare = [vc.qrView.image!]
            let activityController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = vc.view
            activityController.popoverPresentationController?.sourceRect = vc.view.bounds
            vc.present(activityController, animated: true) {}
            
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
                vc.isColdcard = isColdcard
                vc.nodesWords = nodesWords
                vc.recoverPhrase = self.recoveryPhrase
                vc.wallet = wallet
                
            }
            
        default:
            break
        }
    }
    

}
