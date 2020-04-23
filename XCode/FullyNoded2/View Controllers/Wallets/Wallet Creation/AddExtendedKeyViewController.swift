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
    var onSeedDoneBlock: ((String) -> Void)?

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
        textView.text = "tpubDFN5nxFeBN7v6yriSeMk1AkYBQvxxXHMw2nA7UTYhXiGECmzPC4KyigkVvgMf1g726SEZwGFs8hnKmwtNszQ915oT6bB2SvgZ8CaQoDHmTm"
        textField.text = "490ff801"
        
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
    
    @IBAction func addWordsAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "segueToUserSuppliedWords", sender: vc)
            
        }
        
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "segueToUserSuppliedWords":
            
            if let vc = segue.destination as? WordRecoveryViewController {
                
                vc.addingSeed = true
                vc.onAddSeedDoneBlock = { mnemonic in
                    
                    DispatchQueue.main.async { [unowned thisVc = self] in
                        thisVc.onSeedDoneBlock!(mnemonic)
                        thisVc.navigationController!.popViewController(animated: true)
                        
                    }
                    
                }
                
            }
            
            
        default:
            
            break
            
        }
    
        
    }
    

}
