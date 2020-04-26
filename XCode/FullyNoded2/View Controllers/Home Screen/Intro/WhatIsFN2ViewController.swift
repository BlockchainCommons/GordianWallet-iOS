//
//  WhatIsFN2ViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WhatIsFN2ViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate {

    @IBOutlet var nextOutlet: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    
    let recoveryUrl = "https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Recovery.md"
    let libwallyLink = "https://github.com/blockchain/libwally-swift/blob/master/README.md"
    let fullynoded1Link = "https://apps.apple.com/us/app/fully-noded/id1436425586"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        setTitleView()
        nextOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        
        textView.text = """
        FullyNoded 2 is a professional mobile wallet built using the most up-to-date technologies for Bitcoin. It's focused on three goals that together demonstrate some of the best practices for modern mobile-wallet design:

        1. **Self-sovereign Interactions.** Classic mobile wallets usually talked to a full node chosen by the wallet developer and owned/controlled by someone else. FullyNoded 2 instead allows you to choose a full node, either one created using a setup process such as #BitcoinStandup and run by yourself, or a service offered by a provider that you select: self-sovereign means you get to decide. (You can use Blockchain Commons' full-node server for beta testing, but you should migrate to a protected server for real money transactions.)

        2. **Protected Communications.** All of the communications in FullyNoded 2 are protected by the latest version of Tor, which provides two-way authentication of both the server and your wallet. Unlike traditional use of the soon to be deprecated SPV protocol, which reveals that you're accessing the Bitcoin network, Tor simply shows that you're engaging in private onion communications. It's safer when you're in a hostile state, and it's safer in your local coffee shop.

        3. **Multi-sig Protections.** Finally, FullyNoded 2 ensures that your private keys are protected from the most common adversary: loss. Its 2-of-3 multi-sig system leaves one key on the server, one on your mobile wallet, and one in safe off-line storage. If you lose your phone or your server, you can still rebuild from the other two. (The Blockchain Commons #SmartCustody system talks more about how to protect off-line keys.)

        FullyNoded 2 is intended for a sophisticated power user. It's a leading-edge platform that experiments with modern Bitcoin technologies to create a powerful new architecture with features not found in other mobile wallets. It's intended as a professional wallet for your use and also as a demonstration of functionality that other companies can integrate into their own apps as an open source reference implementation of functionality.

        Even more cutting-edge technology is planned for the future, including collaborative custody models, airgapped technologies such as Blockchain Commons' #LetheKit for offline signing using QR codes, and methodologies for social-key recovery.
        """
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["Recovery.md": recoveryUrl, "LibWally": libwallyLink, "FullyNoded 1": fullynoded1Link])
        
    }
    
    private func setTitleView() {
        
        let imageView = UIImageView(image: UIImage(named: "1024.jpg"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        imageView.isUserInteractionEnabled = true
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
        
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
