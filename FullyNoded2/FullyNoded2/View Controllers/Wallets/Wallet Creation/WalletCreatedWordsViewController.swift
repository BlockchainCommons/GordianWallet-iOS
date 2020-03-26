//
//  WalletCreatedWordsViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletCreatedWordsViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var savedOutlet: UIButton!
    @IBOutlet var wordsLabel: UILabel!
    @IBOutlet var textView: UITextView!
    
    var tapTextViewGesture = UITapGestureRecognizer()
    var recoverPhrase = ""
    var wallet:WalletStruct!
    var mnemonic = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        setTitleView()
        savedOutlet.layer.cornerRadius = 8
        wordsLabel.isUserInteractionEnabled = true
        wordsLabel.sizeToFit()
        tapTextViewGesture = UITapGestureRecognizer(target: self,
                                                    action: #selector(shareRawText(_:)))
        
        wordsLabel.addGestureRecognizer(tapTextViewGesture)
        
        let wordArray = recoverPhrase.split(separator: " ")
        
        mnemonic = "Derivation: \(wallet.derivation + "/0")\n\n"
        
        for (i, word) in wordArray.enumerated() {
            
            mnemonic += "\(i + 1). \(word)     "
            
        }
        
        wordsLabel.text = mnemonic
        
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
    
    @IBAction func savedAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.savedOutlet.alpha = 0
            self.wordsLabel.alpha = 0
            
            var message = ""
            
            if self.wallet.type == "MULTI" {
                
                message = "Once you tap \"Yes, I saved them\" the backup words will be gone forever! If you tap \"Oops, I forgot\" we will show them to you again so you may save them."
                
            } else {
                
                message = ""
                
            }
            
            let alert = UIAlertController(title: "Are you sure you saved the recovery items?", message: message, preferredStyle: .actionSheet)
            
            alert.view.superview?.subviews[0].isUserInteractionEnabled = false

            alert.addAction(UIAlertAction(title: "Yes, I saved them", style: .default, handler: { action in
                                
                DispatchQueue.main.async {
                    
                    self.navigationController?.popToRootViewController(animated: true)

                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Oops, I forgot", style: .default, handler: { action in
                                
                DispatchQueue.main.async {
                    
                    self.savedOutlet.alpha = 1
                    self.wordsLabel.alpha = 1
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                                
                DispatchQueue.main.async {
                    
                    self.savedOutlet.alpha = 1
                    self.wordsLabel.alpha = 1
                    
                }
                
            }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    @objc func shareRawText(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.wordsLabel.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.wordsLabel.alpha = 1
                    
                })
                
            }
                            
            let textToShare = [self.mnemonic + "\n\n" + "birthdate unix: \(self.wallet.birthdate)"]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    @IBAction func exportAsQR(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            let qrGen = QRGenerator()
            qrGen.textInput = self.mnemonic + "\n\n" + "birthdate unix: \(self.wallet.birthdate)"
            let image = qrGen.getQRCode()
            let objectsToShare = [image]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = self.view
            self.present(activityController, animated: true) {}
            
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
