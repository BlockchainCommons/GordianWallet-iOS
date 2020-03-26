//
//  WhatIsFN2ViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WhatIsFN2ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var nextOutlet: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    
    let recoveryUrl = "https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Recovery.md"
    let libwallyLink = "https://github.com/blockchain/libwally-swift/blob/master/README.md"
    let fullynoded1Link = "https://apps.apple.com/us/app/fully-noded/id1436425586"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nextOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["Recovery.md": recoveryUrl, "LibWally": libwallyLink, "FullyNoded 1": fullynoded1Link])
        
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if (URL.absoluteString == recoveryUrl) || (URL.absoluteString == libwallyLink) || (URL.absoluteString == fullynoded1Link) {
            UIApplication.shared.open(URL) { (Bool) in

            }
        }
        return false
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "next2", sender: self)
            
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
