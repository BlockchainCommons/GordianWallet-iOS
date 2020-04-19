//
//  WalletCreatedQRViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletCreatedQRViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var qrView: UIImageView!
    @IBOutlet var nextOutlet: UIButton!
    
    var wallet = [String:Any]()
    var recoveryPhrase = ""
    var recoveryQr = ""
    var tapQRGesture = UITapGestureRecognizer()
    
    let qrGenerator = QRGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
<<<<<<< HEAD:XCode/FullyNoded2/View Controllers/Wallets/Wallet Creation/WalletCreatedQRViewController.swift
        let (qr, error) = qrGenerator.getQRCode(textInput: recoveryQr)
        qrView.image = qr
        
        if error {
            
            showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
            
        }
=======
        setTitleView()
        qrView.image = qrGenerator.getQRCode(textInput: recoveryQr)
>>>>>>> parent of 2848fdb... - feat: new UI and flow for recovering wallets where we deduce what is needed by what the user supplies us with and what we find to be present or missing on the node and device - fix: fix coredata crashes where saving a wallet may have caused a crash which resulted in a possible zombie wallet, - fix: we now completely reset the app instead of just deleting all the apps data when utilizing the kill switch - fix: we now only refresh wallet data when needed in the wallets tab (e.g. when a wallet is activated, sweeped, recovered or refreshed) - docs: add a docs folder for all doc related stuff, remove Doffing's cla, rename FullyNoded2 folder to XCode to avoid confusion when building from source - fix: fix any possibility of a zombie wallet being created or displayed to the user - fix: check the hash of the wallet name manually and ensure it matches the expected hash of the public key descriptor for each wallet rpc call to ensure beyond a reasonable doubt that the intended wallet rpc call is to the wallet we expect - fix: fix a bug where the input amount for transactions which had a sub satoshi amount was being rounded and resulted in an error when broadcasting single sig native segwit transactions, this was fixed by converting the amount to a float and then a UInt64 before signing the input - fix: made the UI more consistent - fix: use common terms for the wallet types when creating wallets - fix: add more verbose status when creating wallets - fix: convert simple classes to static classes - fix: remove import button:FullyNoded2/FullyNoded2/View Controllers/Wallets/Wallet Creation/WalletCreatedQRViewController.swift
        nextOutlet.layer.cornerRadius = 8
        qrView.isUserInteractionEnabled = true
        tapQRGesture = UITapGestureRecognizer(target: self, action: #selector(self.shareQRCode(_:)))
        qrView.addGestureRecognizer(tapQRGesture)
        
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
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "goWords", sender: self)
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                
                vc.qrView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                    
                    vc.qrView.alpha = 1
                    
                })
                
            }
            
            let objectsToShare = [self.qrView.image!]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = self.view
            self.present(activityController, animated: true) {}
            
        }
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "goWords":
            
            if let vc = segue.destination as? WalletCreatedWordsViewController {
                
                vc.recoverPhrase = self.recoveryPhrase
                vc.wallet = wallet
                
            }
            
        default:
            break
        }
    }
    

}
