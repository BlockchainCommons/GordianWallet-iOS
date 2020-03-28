//
//  WalletCreatedSaveWordsViewController.swift
//  FullyNoded2
//
//  Created by Peter on 28/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletCreatedSaveWordsViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var saveOutlet: UIButton!
    @IBOutlet var derivationLabel: UILabel!
    @IBOutlet var birthdateLabel: UILabel!
    
    var wallet:WalletStruct!
    var words = ""
    var mnemonic = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        titleLabel.adjustsFontSizeToFitWidth = true
        setTitleView()
        saveOutlet.layer.cornerRadius = 8
        textView.layer.cornerRadius = 8
        let wordArray = words.split(separator: " ")
        
        for (i, word) in wordArray.enumerated() {
            
            mnemonic += "\(i + 1). \(word)\n"
            
        }
        
        textView.text = mnemonic
        mnemonic += "\nDerivation: \(wallet.derivation + "/0")\n"
        mnemonic += "Birthdate unix: \(wallet.birthdate)"
        birthdateLabel.text = "\(wallet.birthdate)"
        derivationLabel.text = wallet.derivation + "/0"
        
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
    
    @IBAction func saveAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.textView.alpha = 0
            
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
                    
                    self.textView.alpha = 1
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                                
                DispatchQueue.main.async {
                    
                    self.textView.alpha = 1
                    
                }
                
            }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    private func impact() {
        
        DispatchQueue.main.async {
            
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            
        }
        
    }
    
    
    @IBAction func copyText(_ sender: Any) {
        
        impact()
        
        UIPasteboard.general.string = mnemonic
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            
            UIPasteboard.general.string = ""
            
        }
        
        displayAlert(viewController: self.navigationController!, isError: false, message: "text copied to clipboard for 60 seconds")
        
    }
    
    @IBAction func exportQr(_ sender: Any) {
        
        impact()
        
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Choose an option", message: "You can either export the QR or simply display it for scanning.", preferredStyle: .actionSheet)
            

            alert.addAction(UIAlertAction(title: "Export", style: .default, handler: { action in
                                
                self.exportAsQr()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Display QR", style: .default, handler: { action in
                                
                DispatchQueue.main.async {
                    
                    self.performSegue(withIdentifier: "mnemonicQr", sender: self)
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func shareAction(_ sender: Any) {
        
        impact()
        
        DispatchQueue.main.async {
            
            let textToShare = [self.mnemonic]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    private func exportAsQr() {
        
        DispatchQueue.main.async {
            
            let qrGen = QRGenerator()
            qrGen.textInput = self.mnemonic
            let image = qrGen.getQRCode()
            let objectsToShare = [image]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = self.view
            self.present(activityController, animated: true) {}
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "mnemonicQr":
            
            if let vc = segue.destination as? QRDisplayerViewController {
                
                vc.address = mnemonic
                
            }
            
        default:
            break
        }
    }

}
