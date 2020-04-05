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
    
    var wallet = [String:Any]()
    var w:WalletStruct!
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
        w = WalletStruct(dictionary: wallet)
        let wordArray = words.split(separator: " ")
        
        for (i, word) in wordArray.enumerated() {
            
            mnemonic += "\(i + 1). \(word)\n"
            
        }
        
        textView.text = mnemonic
        mnemonic += "\nDerivation: \(w.derivation + "/0")\n"
        mnemonic += "Birthdate unix: \(w.birthdate)"
        birthdateLabel.text = "\(w.birthdate)"
        derivationLabel.text = w.derivation + "/0"
        
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
            
            if self.w.type == "MULTI" {
                
                message = "Once you tap \"Yes, I saved them\" the backup words will be gone forever! If you tap \"Oops, I forgot\" we will show them to you again so you may save them."
                
            } else {
                
                message = ""
                
            }
            
            let alert = UIAlertController(title: "Are you sure you saved the recovery items?", message: message, preferredStyle: .actionSheet)
            
            alert.view.superview?.subviews[0].isUserInteractionEnabled = false

            alert.addAction(UIAlertAction(title: "Yes, I saved them", style: .default, handler: { [unowned vc = self] action in
                                
                DispatchQueue.main.async {
                    
                    vc.navigationController?.popToRootViewController(animated: true)

                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Oops, I forgot", style: .default, handler: { [unowned vc = self] action in
                                
                DispatchQueue.main.async {
                    
                    vc.textView.alpha = 1
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned vc = self] action in
                                
                DispatchQueue.main.async {
                    
                    vc.textView.alpha = 1
                    
                }
                
            }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func copyText(_ sender: Any) {
        
        UIPasteboard.general.string = mnemonic
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            
            UIPasteboard.general.string = ""
            
        }
        
        displayAlert(viewController: self, isError: false, message: "text copied to clipboard for 60 seconds")
        
    }
    
    @IBAction func exportQr(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Choose an option", message: "You can either export the QR or simply display it for scanning.", preferredStyle: .actionSheet)
            

            alert.addAction(UIAlertAction(title: "Export", style: .default, handler: { [unowned vc = self] action in
                                
                vc.exportAsQr()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Display QR", style: .default, handler: { [unowned vc = self] action in
                                
                DispatchQueue.main.async {
                    
                    vc.performSegue(withIdentifier: "mnemonicQr", sender: vc)
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func shareAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            let textToShare = [self.mnemonic]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    private func exportAsQr() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            let qrGen = QRGenerator()
            let image = qrGen.getQRCode(textInput: vc.mnemonic)
            let objectsToShare = [image]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = vc.view
            vc.present(activityController, animated: true) {}
            
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
