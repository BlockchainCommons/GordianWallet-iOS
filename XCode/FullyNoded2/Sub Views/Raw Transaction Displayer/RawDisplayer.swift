//
//  RawDisplayer.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import UIKit

class RawDisplayer {
    
    var y = CGFloat()
    let textView = UITextView()
    var qrView = UIImageView()
    let qrGenerator = QRGenerator()
    let copiedLabel = UILabel()
    var vc = UIViewController()
    var rawString = ""
    let copyButton = UIButton()
    let shareButton = UIButton()
    
    func addButtons() {
        
        let copyImage = UIImage(systemName: "doc.on.doc")!
        copyButton.tintColor = .systemTeal
        copyButton.setImage(copyImage, for: .normal)
        copyButton.frame = CGRect(x: qrView.frame.maxX - 25, y: qrView.frame.minY - 30, width: 25, height: 25)
        vc.view.addSubview(copyButton)
        
        let shareImage = UIImage(systemName: "arrowshape.turn.up.right")!
        shareButton.tintColor = .systemTeal
        shareButton.setImage(shareImage, for: .normal)
        shareButton.frame = CGRect(x: copyButton.frame.minX - 35, y: qrView.frame.minY - 30, width: 25, height: 25)
        vc.view.addSubview(shareButton)
        
    }
    
    func addRawDisplay() {
        
        configureQrView()
        configureTextView()
        configureCopiedLabel()
        
        let (qr, error) = qrGenerator.getQRCode(textInput: rawString)
        qrView.image = qr
        if error {
            showAlert(vc: vc, title: "QR Error", message: "That is too much data to fit into that sized image")
        }
        
        textView.text = rawString
        UIPasteboard.general.string = rawString
        
        vc.view.addSubview(qrView)
        vc.view.addSubview(textView)
        
        UIView.animate(withDuration: 0.4, animations: { [unowned thisClass = self] in
            
            thisClass.qrView.frame = CGRect(x: 10,
                                       y: thisClass.y,
                                       width: thisClass.vc.view.frame.width - 20,
                                       height: thisClass.vc.view.frame.width - 20)
            
        }, completion: { _ in
            
            UIView.animate(withDuration: 0.4, animations: { [unowned thisClass = self] in
                
                let qrHeight = thisClass.vc.view.frame.width - 20
                let totalViewHeight = thisClass.vc.view.frame.height

                
                thisClass.textView.frame = CGRect(x: 10,
                                             y: thisClass.qrView.frame.maxY,
                                             width: thisClass.vc.view.frame.width - 20,
                                             height: totalViewHeight - qrHeight)
                
            }, completion: { _ in
                                
                DispatchQueue.main.async { [unowned thisClass = self] in
                    
                    thisClass.addCopiedLabel()
                    thisClass.addButtons()
                    
                }
                
            })
            
        })
        
    }
    
    func addCopiedLabel() {
        
        vc.view.addSubview(copiedLabel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            
            UIView.animate(withDuration: 0.3, animations: { [unowned thisClass = self] in
                
                thisClass.copiedLabel.frame = CGRect(x: 0,
                                                y: thisClass.vc.view.frame.maxY - 50,
                                                width: thisClass.vc.view.frame.width,
                                                height: 50)
                
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: { [unowned thisClass = self] in
                
                UIView.animate(withDuration: 0.3, animations: { [unowned thisClass = self] in
                    
                    thisClass.copiedLabel.frame = CGRect(x: 0,
                                                    y: thisClass.vc.view.frame.maxY + 100,
                                                    width: thisClass.vc.view.frame.width,
                                                    height: 50)
                    
                }, completion: { _ in
                    
                    thisClass.copiedLabel.removeFromSuperview()
                    
                })
                
            })
            
        }
        
    }
    
    func configureCopiedLabel() {
        
        copiedLabel.text = "copied to clipboard ✓"
        
        copiedLabel.frame = CGRect(x: 0,
                                   y: vc.view.frame.maxY + 100,
                                   width: vc.view.frame.width,
                                   height: 50)
        
        copiedLabel.textColor = UIColor.darkGray
        copiedLabel.font = UIFont.init(name: "HiraginoSans-W3", size: 17)
        copiedLabel.backgroundColor = UIColor.black
        copiedLabel.textAlignment = .center
        
    }
    
    func configureQrView() {
        
        qrView.isUserInteractionEnabled = true
        
        qrView.frame = CGRect(x: 10,
                              y: vc.view.frame.maxY + 200,
                              width: vc.view.frame.width - 20,
                              height: vc.view.frame.width - 20)
        
    }
    
    func configureTextView() {
        
        textView.textColor = UIColor.white
        textView.backgroundColor = UIColor.clear
        textView.textAlignment = .natural
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.adjustsFontForContentSizeCategory = true
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        
        let qrHeight = vc.view.frame.width - 20
        let totalViewHeight = vc.view.frame.height
        
        textView.frame = CGRect(x: 10,
                                y: vc.view.frame.maxY + 170,
                                width: vc.view.frame.width - 20,
                                height: totalViewHeight - qrHeight)
        
    }
    
}
