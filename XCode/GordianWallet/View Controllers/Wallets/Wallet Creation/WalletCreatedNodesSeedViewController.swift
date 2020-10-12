//
//  WalletCreatedNodesSeedViewController.swift
//  FullyNoded2
//
//  Created by Peter on 28/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletCreatedNodesSeedViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var savedOutlet: UIButton!
    @IBOutlet weak var derivationLabel: UILabel!
    @IBOutlet weak var birthdateLabel: UILabel!
    
    var isColdcard = Bool()
    var wallet = [String:Any]()
    var w:WalletStruct!
    var nodeWords = ""
    var nodesMnemonic = ""
    var recoverPhrase = ""
    var alertStyle = UIAlertController.Style.actionSheet
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        savedOutlet.layer.cornerRadius = 8
        textView.layer.cornerRadius = 8
        w = WalletStruct(dictionary: wallet)
        let wordArray = nodeWords.split(separator: " ")
        
        for (i, word) in wordArray.enumerated() {
            
            nodesMnemonic += "\(i + 1). \(word)\n"
            
        }
        
        if isColdcard {
            navigationItem.title = "Device Seed"
            
        } else {
            navigationItem.title = "Node's Seed"
            
        }
        
        textView.text = nodesMnemonic
        nodesMnemonic += "\nDerivation: \(w.derivation + "/0")\n"
        nodesMnemonic += "Birthblock: \(w.blockheight)"
        birthdateLabel.text = "\(w.blockheight)"
        derivationLabel.text = w.derivation + "/0"
        
        if (UIDevice.current.userInterfaceIdiom == .pad) {
          alertStyle = UIAlertController.Style.alert
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.textView.alpha = 0
            
            let message = "Once you tap \"Yes, I saved them\" the backup words will be gone forever! If you tap \"Oops, I forgot\" we will show them to you again so you may save them."
            
            let alert = UIAlertController(title: "Are you sure you saved the seed?", message: message, preferredStyle: vc.alertStyle)
            
            alert.view.superview?.subviews[0].isUserInteractionEnabled = false

            alert.addAction(UIAlertAction(title: "Yes, I saved it", style: .default, handler: { [unowned vc = self] action in
                                
                DispatchQueue.main.async {
                    
                    vc.performSegue(withIdentifier: "showOfflineSeed", sender: vc)

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
            
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func copyText(_ sender: Any) {
        
        UIPasteboard.general.string = nodesMnemonic
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            
            UIPasteboard.general.string = ""
            
        }
        
        displayAlert(viewController: self, isError: false, message: "text copied to clipboard for 60 seconds")
        
    }
    
    @IBAction func exportQr(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            let alert = UIAlertController(title: "Choose an option", message: "You can either export the QR or simply display it for scanning.", preferredStyle: vc.alertStyle)

            alert.addAction(UIAlertAction(title: "Export", style: .default, handler: { [unowned vc = self] action in
                                
                vc.exportAsQr()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Display QR", style: .default, handler: { [unowned vc = self] action in
                                
                DispatchQueue.main.async {
                    
                    vc.performSegue(withIdentifier: "nodeSeedQr", sender: vc)
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func shareAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            let textToShare = [vc.nodesMnemonic]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = vc.view
            activityViewController.popoverPresentationController?.sourceRect = vc.view.bounds
            vc.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    private func exportAsQr() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            let qrGen = QRGenerator()
            let image = qrGen.getQRCode(textInput: vc.nodesMnemonic).qr
            let objectsToShare = [image]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityController.popoverPresentationController?.sourceView = vc.view
            activityController.popoverPresentationController?.sourceRect = vc.view.bounds
            vc.present(activityController, animated: true) {}
            
        }
        
    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "showOfflineSeed":
            
            if let vc = segue.destination as? WalletCreatedSaveWordsViewController {
                
                vc.wallet = wallet
                vc.recoverPhrase = recoverPhrase
                
            }
            
        case "nodeSeedQr":
            
            if let vc = segue.destination as? QRDisplayerViewController {
                
                vc.text = nodesMnemonic
                
            }
            
        default:
            break
        }
    }

}
