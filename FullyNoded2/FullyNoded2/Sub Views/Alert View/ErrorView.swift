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
    //let upSwipe = UISwipeGestureRecognizer()
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let tap = UITapGestureRecognizer()
    let infoButton = UIButton()
    let infoTitle = ""
    let infoDetail = ""
    var action = {}
    
    
    @objc func handleTap(_ sender: UIGestureRecognizer) {
        
        hide()
        
    }
    
//    @objc func handleSwipes(_ sender: UIGestureRecognizer) {
//
//        print("handleSwipes")
//
//        hide()
//
//    }
    
    func hide() {
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.backgroundView.frame = CGRect(x: 0,
                                          y: 0,
                                          width: self.backgroundView.frame.width,
                                          height: 61)
            
            self.errorLabel.frame = CGRect(x: 16,
                                           y: -61,
                                           width: self.backgroundView.frame.width,
                                           height: 61)
            
        }) { _ in
            
            UIView.animate(withDuration: 0.2, animations: {
                
                
            }, completion: { _ in
                
                self.backgroundView.removeFromSuperview()
                
            })
            
        }
        
    }
    
    @objc func showInfo() {
        print("show info")
        
        action()
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        return !(touch.view is UIButton)
        
    }

    
    func showErrorView(vc: UIViewController, text: String, isError: Bool) {
        
        tap.delegate = self
        //tap.cancelsTouchesInView = false
        self.isUserInteractionEnabled = true
        //upSwipe.direction = .up
        //upSwipe.addTarget(self, action: #selector(handleSwipes(_:)))
        tap.addTarget(self, action: #selector(self.handleTap(_:)))
        backgroundView.addGestureRecognizer(self.tap)
        
        let width = vc.view.frame.width - 32
        
        backgroundView.frame = CGRect(x: 0,
                                      y: -61,
                                      width: vc.view.frame.width,
                                      height: 61)
        
        backgroundView.alpha = 0
        
        if isError {
            
            errorLabel.textColor = .red
            
        } else {
            
            errorLabel.textColor = .green
            
        }
        
        errorLabel.frame = CGRect(x: 16,
                                  y: -61,
                                  width: width,
                                  height: 61)
        
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
        
        //errorLabel.addSubview(infoButton)
        
        backgroundView.contentView.addSubview(errorLabel)
        backgroundView.contentView.addSubview(infoButton)
        
        vc.view.addSubview(backgroundView)
        
        var y = CGFloat()
        
        if vc.navigationController != nil {
            
            y = vc.navigationController!.navigationBar.frame.maxY
            
        } else {
            
            y = 0
            
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.backgroundView.alpha = 1
            
            self.backgroundView.frame = CGRect(x: 0,
                                               y: y,
                                               width: vc.view.frame.width,
                                               height: 61)
            
            self.errorLabel.frame = CGRect(x: 16,
                                           y: 0,
                                           width: width,
                                           height: 61)
            
        }) { _ in
            
            DispatchQueue.main.async {
                
                self.impact.impactOccurred()
                
            }
            
            let deadlineTime = 8.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + deadlineTime, execute: {
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    self.backgroundView.frame = CGRect(x: 0,
                                                       y: -61,
                                                       width: width,
                                                       height: 61)
                    
                    self.errorLabel.frame = CGRect(x: 16,
                                                   y: -61,
                                                   width: width,
                                                   height: 61)
                    
                }) { _ in
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        
                        
                    }, completion: { _ in
                        
                        self.backgroundView.removeFromSuperview()
             
                    })
                    
                }
                
            })
            
        }
        
    }
    
}
