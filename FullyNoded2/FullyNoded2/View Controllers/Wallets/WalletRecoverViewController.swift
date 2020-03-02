//
//  WalletRecoverViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletRecoverViewController: UIViewController, UITextFieldDelegate {
    
    var onDoneBlock: ((Bool) -> Void)?
    let tap = UITapGestureRecognizer()
    @IBOutlet var textField: UITextField!
    @IBOutlet var scanButton: UIButton!
    @IBOutlet var wordsView: UIView!
    @IBOutlet var recoverNowOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recoverNowOutlet.alpha = 0
        textField.delegate = self
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        scanButton.layer.cornerRadius = 8
        recoverNowOutlet.layer.cornerRadius = 8
    }
    
    @objc func handleTap() {
        
        DispatchQueue.main.async {
            
            self.textField.resignFirstResponder()
            
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
        
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func scanAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "scanRecovery", sender: self)
            
        }
        
    }
    
    @IBAction func addWord(_ sender: Any) {
        
        displayAlert(viewController: self, isError: false, message: "Under construction, use the RecoveryQR only for now")
        
    }
    
    func validRecoveryScanned() {
        
        DispatchQueue.main.async {
            
            self.scanButton.setTitle("  RecoveryQR is Valid", for: .normal)
            self.scanButton.setTitleColor(.systemGreen, for: .normal)
            self.scanButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
            self.scanButton.tintColor = .systemGreen
            self.scanButton.isEnabled = false
            
        }
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "scanRecovery":
            
            if let vc = segue.destination as? ScannerViewController {
                
                vc.isRecovering = true
                vc.words = "vote night stuff fix journey simple super core accuse spell enlist produce"
                vc.onDoneRecoveringBlock = { result in
                    
                    DispatchQueue.main.async {
                        
                        self.dismiss(animated: true) {
                            
                            self.onDoneBlock!(true)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }
    

}
