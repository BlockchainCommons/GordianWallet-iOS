//
//  IntroductionViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class IntroductionViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var nextOutlet: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    
    let donationLinkUrl = "https://btcpay.blockchaincommons.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nextOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        hideBackButton()
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["BTCPayServer": donationLinkUrl])
    }
    
    private func hideBackButton() {
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if (URL.absoluteString == donationLinkUrl) {
            UIApplication.shared.open(URL) { (Bool) in

            }
        }
        return false
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "next1", sender: self)
            
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
