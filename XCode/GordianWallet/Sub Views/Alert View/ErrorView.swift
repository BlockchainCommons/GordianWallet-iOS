//
//  ErrorView.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import UIKit

class ErrorView: UIView, UIGestureRecognizerDelegate {
    
    let errorLabel = UILabel()
    let impact = UIImpactFeedbackGenerator()
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let tap = UITapGestureRecognizer()
    let infoButton = UIButton()
    let infoTitle = ""
    let infoDetail = ""
    var action = {}
    
    
    @objc func handleTap(_ sender: UIGestureRecognizer) {
        hide()
    }
    
    func hide() {
        
        UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
            
            vc.errorLabel.frame.origin.y = -30
            
        }) { [unowned vc = self] _ in
            
            vc.backgroundView.removeFromSuperview()
            
        }
        
    }
    
    @objc func showInfo() {
        action()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIButton)
    }

    
    func showErrorView(vc: UIViewController, text: String, isError: Bool) {
        
        tap.delegate = self
        isUserInteractionEnabled = true
        tap.addTarget(self, action: #selector(handleTap(_:)))
        backgroundView.addGestureRecognizer(tap)
        
        let width = vc.view.frame.width - 32
        
        backgroundView.frame = CGRect(x: 0,
                                      y: -30,
                                      width: vc.view.frame.width,
                                      height: 30)
        
        backgroundView.alpha = 0
        
        if isError {
            
            errorLabel.textColor = .red
            
        } else {
            
            errorLabel.textColor = .green
            
        }
        
        errorLabel.frame = CGRect(x: 8,
                                  y: -30,
                                  width: width,
                                  height: 30)
        
        errorLabel.font = UIFont.systemFont(ofSize: 12)
        errorLabel.text = text.lowercased()
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .left
        
        infoButton.frame = CGRect(x: backgroundView.frame.maxX - 30, y: (backgroundView.frame.height / 2) - 10, width: 20, height: 20)
        infoButton.target(forAction: #selector(showInfo), withSender: self)
        
        if isError {
            let infoImage = UIImage(systemName: "exclamationmark.circle")!
            infoButton.setImage(infoImage, for: .normal)
            infoButton.tintColor = .systemRed
        } else {
            let infoImage = UIImage(systemName: "checkmark.circle")!
            infoButton.setImage(infoImage, for: .normal)
            infoButton.tintColor = .systemGreen
        }
        
        backgroundView.contentView.addSubview(errorLabel)
        backgroundView.contentView.addSubview(infoButton)
        vc.view.addSubview(backgroundView)
        var y = CGFloat()
        
        if vc.navigationController != nil {
            y = vc.navigationController!.navigationBar.frame.maxY
        } else {
            y = 0
        }
        
        UIView.animate(withDuration: 0.3, animations: { [unowned thisVc = self] in
            
            thisVc.backgroundView.alpha = 1
            
            thisVc.backgroundView.frame = CGRect(x: 0,
                                                 y: y,
                                                 width: vc.view.frame.width,
                                                 height: 30)
            
            thisVc.errorLabel.frame = CGRect(x: 8,
                                             y: 0,
                                             width: width,
                                             height: 30)
            
        }) { _ in
            
            DispatchQueue.main.async { [unowned thisVc = self] in
                
                thisVc.impact.impactOccurred()
                
            }
            
            let deadlineTime = 8.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + deadlineTime, execute: {
                
                UIView.animate(withDuration: 0.3, animations: { [unowned thisVc = self] in
                    
                    thisVc.backgroundView.frame = CGRect(x: 0,
                                                       y: -30,
                                                       width: width,
                                                       height: 30)
                    
                    thisVc.errorLabel.frame = CGRect(x: 8,
                                                   y: -30,
                                                   width: width,
                                                   height: 30)
                    
                })
                
            })
            
        }
        
    }
    
}
