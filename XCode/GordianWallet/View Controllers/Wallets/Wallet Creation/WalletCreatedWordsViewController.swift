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
    var isColdcard = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        savedOutlet.layer.cornerRadius = 8
        
        w = WalletStruct(dictionary: wallet)
        
        if w.type == "MULTI" {
            
            if isColdcard {
                textView.text = TextBlurbs.coldCardMultiSigCreatedSeedWarning()
                
            } else {
                textView.text = TextBlurbs.multiSigCreatedSeedWarning()
                
            }
            
        } else {
            
            textView.text = TextBlurbs.singleSigCreatedSeedWarning()
            
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
                vc.isColdcard = isColdcard
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
