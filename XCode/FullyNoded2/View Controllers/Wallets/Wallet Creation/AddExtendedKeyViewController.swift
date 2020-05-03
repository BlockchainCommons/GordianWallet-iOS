//
//  AddExtendedKeyViewController.swift
//  FullyNoded2
//
//  Created by Peter on 22/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class AddExtendedKeyViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var nextOutlet: UIButton!
    @IBOutlet weak var textView: UITextView!
    let tap = UITapGestureRecognizer()
    var wallet:WalletStruct!
    var onDoneBlock: (([String:String]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        textView.delegate = self
        nextOutlet.layer.cornerRadius = 8
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.darkGray.cgColor
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 4
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        
    }
    
    private func createDescriptors() {
        if textView.text != "" && textField.text != "" {
            
            if textView.text.hasPrefix("xpub") || textView.text.hasPrefix("tpub") && textField.text!.count == 8 {
                
                if let _ = HDKey(textView.text!) {
                    let dict = ["key":textView.text!, "fingerprint":textField.text!]
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.onDoneBlock!((dict))
                        vc.navigationController!.popViewController(animated: true)
                        
                    }
                } else {
                    showAlert(vc: self, title: "Invalid xpub!", message: "That is not a valid xpub or tpub. FullyNoded 2 is powered by Bitcoin Core which is only compatible with xpub's and tpub's. You will need to use this tool to convert other types of extended keys to xpubs/tpubs: https://jlopp.github.io/xpub-converter/")
                }
                
            } else {
                showAlert(vc: self, title: "Only xpubs allowed here", message: "This option is only for creating watch-only wallets with user supplied xpub's. If you would like to supply a seed tap the \"add BIP39 words\" button below.")
                
            }
        }
    }
    
    @objc func handleTap() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.textView.resignFirstResponder()
            
        }
    }
    
    @IBAction func nextAction(_ sender: Any) {
        createDescriptors()
        
    }

}
