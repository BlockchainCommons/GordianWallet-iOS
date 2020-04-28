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
    @IBOutlet var savedOutlet: UIButton!
    var recoverPhrase = ""
    var wallet = [String:Any]()
    var nodesWords = ""
    var w:WalletStruct!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        savedOutlet.layer.cornerRadius = 8
        
        w = WalletStruct(dictionary: wallet)
        
        if w.type == "MULTI" {
            
            textView.text = """
            On the next two screens we will display two master seeds.

            You *MUST* save them seperately from each other! *THEY ARE REQUIRED* to fully recover a multi-signature wallet.
            
            The first one represents your nodes master seed, it is important to note your node does not hold this seed, it only holds a key set that is derived from this seed. If you lose your node you will want to be able to use these words to recover your nodes private keys.
            
            The second master seed is your offline recovery words, these words will be need to fully recover this multi-sig wallet.
            
            These words **WILL BE DELETED FOREVER** from this device once you tap the "I saved them" button!

            At a minimum we recommend writing these words down on water proof paper with a permanent marker, ideally engrave them on titanium if you are going to store larger amounts.
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
    
    @IBAction func savedAction(_ sender: Any) {
        
        var segueString = "goSaveWords"
        
        if w.type == "MULTI" {
            segueString = "showNodesSeed"
            
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: segueString, sender: vc)
            
        }
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "showNodesSeed":
            
            if let vc = segue.destination as? WalletCreatedNodesSeedViewController {
                
                vc.wallet = wallet
                vc.recoverPhrase = recoverPhrase
                vc.nodeWords = nodesWords
            }
            
        case "goSaveWords":
            
            if let vc = segue.destination as? WalletCreatedSaveWordsViewController {
                
                vc.wallet = wallet
                vc.recoverPhrase = recoverPhrase
                
            }
            
        default:
            break
        }
    }
    

}
