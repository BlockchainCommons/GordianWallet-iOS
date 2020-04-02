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
    
    var wallet = [String:Any]()
    var recoveryPhrase = ""
    var recoveryQr = ""
    var tapQRGesture = UITapGestureRecognizer()
    
    let qrGenerator = QRGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        setTitleView()
        qrGenerator.textInput = recoveryQr
        qrView.image = qrGenerator.getQRCode()
        nextOutlet.layer.cornerRadius = 8
        qrView.isUserInteractionEnabled = true
        tapQRGesture = UITapGestureRecognizer(target: self, action: #selector(self.shareQRCode(_:)))
        qrView.addGestureRecognizer(tapQRGesture)
        
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
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "goWords", sender: self)
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.qrView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.qrView.alpha = 1
                    
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
                
                vc.recoverPhrase = self.recoveryPhrase
                vc.wallet = wallet
                
            }
            
        default:
            break
        }
    }
    

}
