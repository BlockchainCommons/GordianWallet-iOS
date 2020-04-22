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
    
    @IBOutlet weak var nextOutlet: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    let tap = UITapGestureRecognizer()
    var wallet:WalletStruct!
    var onDoneBlock: (([String:String]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        textView.delegate = self
        textField.delegate = self
        nextOutlet.layer.cornerRadius = 8
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.darkGray.cgColor
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 4
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        textField.text = "c5dd2547"
        textView.text = "tpubDFN5nxFeBN7v6yriSeMk1AkYBQvxxXHMw2nA7UTYhXiGECmzPC4KyigkVvgMf1g726SEZwGFs8hnKmwtNszQ915oT6bB2SvgZ8CaQoDHmTm"
        
//        wsh(sortedmulti(2,[c5dd2547/48'/1'/0'/2']tpubDFN5nxFeBN7v6yriSeMk1AkYBQvxxXHMw2nA7UTYhXiGECmzPC4KyigkVvgMf1g726SEZwGFs8hnKmwtNszQ915oT6bB2SvgZ8CaQoDHmTm/0/*,[82c02cb3/48'/1'/0'/2']tpubDETxF1YqAjD3aTedjXWuXkT81khJwACZuBL8awvP6aySKp6ucGjxWrsZbkqjpCv5crSTkZUpa5vDMTeFsu5iiSuKSjnmmxRqwY9r3F9Ha9M/0/*,[f79a13c1/48'/1'/0'/2']tpubDFd47XkzbMAMuXJF47rcpXNoYWYdMLZNWohrzFaWg2mTsbgWDvCQ522hzQKphuLKR8dDpriKVShNvqYjwiWoQUgG83EJYmYHkekJuPw4LSf/0/*))#anyn49nd
//
//         wsh(sortedmulti(2,[c5dd2547/48'/1'/0'/2']tpubDFN5nxFeBN7v6yriSeMk1AkYBQvxxXHMw2nA7UTYhXiGECmzPC4KyigkVvgMf1g726SEZwGFs8hnKmwtNszQ915oT6bB2SvgZ8CaQoDHmTm/1/*,[82c02cb3/48'/1'/0'/2']tpubDETxF1YqAjD3aTedjXWuXkT81khJwACZuBL8awvP6aySKp6ucGjxWrsZbkqjpCv5crSTkZUpa5vDMTeFsu5iiSuKSjnmmxRqwY9r3F9Ha9M/1/*,[f79a13c1/48'/1'/0'/2']tpubDFd47XkzbMAMuXJF47rcpXNoYWYdMLZNWohrzFaWg2mTsbgWDvCQ522hzQKphuLKR8dDpriKVShNvqYjwiWoQUgG83EJYmYHkekJuPw4LSf/1/*))#cx0ftrr9
         
        
    }
    
    private func createDescriptors() {
        if textField.text != "" && textView.text != "" {
            if textField.text!.count == 8 {
                let fingerprint = textField.text!
                if let _ = HDKey(textView.text!) {
                    let dict = ["key":textView.text!, "fingerprint":fingerprint]
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.onDoneBlock!((dict))
                        vc.navigationController!.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    @objc func handleTap() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.textField.resignFirstResponder()
            vc.textView.resignFirstResponder()
            
        }
        
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        createDescriptors()
        
    }
    
    @IBAction func addWordsAction(_ sender: Any) {
        
        
        
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
