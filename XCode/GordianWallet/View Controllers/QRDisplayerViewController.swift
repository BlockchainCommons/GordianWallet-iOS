//
//  QRDisplayerViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 27/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class QRDisplayerViewController: UIViewController {
    
    var address = ""
    let qrGenerator = QRGenerator()
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showQR()
    }
    
    @IBAction func closeAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    
    func showQR() {
        
        let (qr, error) = qrGenerator.getQRCode(textInput: address)
        
        if error {
            
            showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
            
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.imageView.image = qr
            
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
