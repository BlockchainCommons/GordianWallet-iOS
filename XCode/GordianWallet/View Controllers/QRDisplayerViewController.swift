//
//  QRDisplayerViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 27/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import URKit

class QRDisplayerViewController: UIViewController {
    
    var parts = [String]()
    var text = ""
    private var encoder:UREncoder!
    private var timer: Timer?
    private var ur: UR!
    private var partIndex = 0
    private let qrGenerator = QRGenerator()
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    @IBOutlet weak private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showQR()
    }
    
    @IBAction func closeAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func animateNow() {
        encoder = UREncoder(ur, maxFragmentLen: 250)
        setTimer()
    }
    
    private func setTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(automaticRefresh), userInfo: nil, repeats: true)
    }

    @objc func automaticRefresh() {
        nextPart()
    }
    
    func showQR() {
        if parts.count > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
                
                let (qr, error) = self.qrGenerator.getQRCode(textInput: self.parts[self.partIndex])
                
                if error {
                    showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.imageView.image = qr
                    
                    if self.partIndex < self.parts.count - 1 {
                        self.partIndex += 1
                    } else {
                        self.partIndex = 0
                    }
                }
                
            }
            
        } else {
            let (qr, error) = qrGenerator.getQRCode(textInput: text)
            if error {
                showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.imageView.image = qr
            }
        }
    }
    
    private func nextPart() {
        let part = encoder.nextPart()
        let index = encoder.seqNum
        
        if index <= encoder.seqLen {
            parts.append(part.uppercased())
        } else {
            timer?.invalidate()
            timer = nil
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(animate), userInfo: nil, repeats: true)
        }
    }
    
    @objc func animate() {
        showQR()
        
        if partIndex < parts.count - 1 {
            partIndex += 1
        } else {
            partIndex = 0
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
