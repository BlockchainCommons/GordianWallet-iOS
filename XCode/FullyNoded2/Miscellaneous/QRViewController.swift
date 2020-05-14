//
//  QRViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class QRViewController: UIViewController, UINavigationControllerDelegate {

    var tapQRGesture = UITapGestureRecognizer()
    var tapTextViewGesture = UITapGestureRecognizer()
    let displayer = RawDisplayer()
    let qrGenerator = QRGenerator()
    var itemToDisplay = ""
    var infoText = ""
    var barTitle = ""
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        descriptionLabel.text = infoText
        descriptionLabel.sizeToFit()
        configureDisplayer()
        showQR(string: itemToDisplay)
        
    }
    
    func showQR(string: String) {
        
        displayer.rawString = string
        displayer.addRawDisplay()
        navigationItem.title = barTitle
        
    }
    
    func configureDisplayer() {
        
        displayer.vc = self
        displayer.y = self.descriptionLabel.frame.maxY + 10
        
        tapQRGesture = UITapGestureRecognizer(target: self,
                                              action: #selector(shareQRCode(_:)))
        
        displayer.qrView.addGestureRecognizer(tapQRGesture)
        
        tapTextViewGesture = UITapGestureRecognizer(target: self,
                                                    action: #selector(shareRawText(_:)))
        
        displayer.copyButton.addTarget(self, action: #selector(copyText), for: .touchUpInside)
        displayer.shareButton.addTarget(self, action: #selector(shareQRCode(_:)), for: .touchUpInside)
        
        displayer.textView.addGestureRecognizer(tapTextViewGesture)
        displayer.textView.isSelectable = true
        
    }
    
    @objc func copyText() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            let pasteboard = UIPasteboard.general
            pasteboard.string = vc.itemToDisplay
            displayAlert(viewController: vc, isError: false, message: "\(vc.barTitle) copied to clipboard")
        }
    }
    
    @objc func shareRawText(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                
                vc.displayer.textView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                    
                    vc.displayer.textView.alpha = 1
                    
                })
                
            }
                            
            let textToShare = [vc.itemToDisplay]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = vc.view
            vc.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        print("shareQRCode")
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                
                vc.displayer.qrView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                    
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
