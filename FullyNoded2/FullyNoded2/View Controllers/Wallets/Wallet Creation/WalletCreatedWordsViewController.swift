//
//  WalletCreatedWordsViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletCreatedWordsViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var savedOutlet: UIButton!
    var recoverPhrase = ""
    var wallet = [String:Any]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        titleLabel.adjustsFontSizeToFitWidth = true
        setTitleView()
        savedOutlet.layer.cornerRadius = 8
        
        let w = WalletStruct(dictionary: wallet)
        
        if w.type == "MULTI" {
            
            textView.text = """
            On the next screen we will display 12 very important words.

            You *MUST* write these 12 words down and save them seperately from the RecoveryQR, *THEY ARE REQUIRED* to recover a multi-signature wallet if you lose your node.

            These words **WILL BE DELETED FOREVER** once you tap the "I saved them" button!

            At a minimum we recommend writing these words down on water proof paper with a permanent marker.
            """
            
        } else {
            
            textView.text = """
            On the next screen we will display your devices seed as a 12 word BIP39 mnemonic.

            You should write these 12 words down and save them seperately from the Recovery QR.
            
            The seed is also included in the Recovery QR so these words act as a redundant back up that can be used with other apps.

            At a minimum we recommend writing these words down on water proof paper with a permanent marker.
            """
            
        }
        
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
            
            self.performSegue(withIdentifier: "goSaveWords", sender: self)
            
        }
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "goSaveWords":
            
            if let vc = segue.destination as? WalletCreatedSaveWordsViewController {
                
                vc.wallet = wallet
                vc.words = recoverPhrase
                
            }
            
        default:
            break
        }
    }
    

}
