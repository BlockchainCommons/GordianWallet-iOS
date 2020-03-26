//
//  HowToUseFN2ViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class HowToUseFN2ViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet var nextOutlet: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    
    let standupAppLink = "https://drive.google.com/open?id=1lXyl_zO6WPJN5tzWAVV3p42WPFtyesCR"
    let scriptLink = "https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/Scripts"
    let myNodeLink = "http://www.mynodebtc.com"
    let raspiBlitzLink = "https://raspiblitz.com"
    let nodlLink = "https://www.nodl.it"
    let btcpayLink = "https://btcpayserver.org"
    let quickConnectLink = "https://github.com/BlockchainCommons/Bitcoin-Standup#quick-connect-url-using-btcstandup"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nextOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["StandUp.app": standupAppLink, "StandUp.sh scripts": scriptLink, "MyNode": myNodeLink, "RaspiBlitz": raspiBlitzLink, "Nodl": nodlLink, "BTCPay": btcpayLink, "QuickConnect QR": quickConnectLink])
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "next4", sender: self)
            
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if (URL.absoluteString == standupAppLink) || (URL.absoluteString == scriptLink) || (URL.absoluteString == myNodeLink) || (URL.absoluteString == raspiBlitzLink) || (URL.absoluteString == nodlLink) || (URL.absoluteString == btcpayLink) || (URL.absoluteString == quickConnectLink) {
            UIApplication.shared.open(URL) { (Bool) in

            }
        }
        return false
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
