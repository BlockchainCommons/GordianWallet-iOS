//
//  HowToSupportFN2ViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class HowToSupportFN2ViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var nextOutlet: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    
    let donationLinkUrl = "https://btcpay.blockchaincommons.com"
    let homePageUrl = "www.blockchaincommons.com"
    let repoLink = "https://github.com/BlockchainCommons/FullyNoded-2"
    let sponsorLink = "https://github.com/sponsors/BlockchainCommons"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        setTitleView()
        nextOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        
        textView.text = """
        FullyNoded 2 is a project of Blockchain Commons. We are proudly a "not-for-profit" social benefit corporation committed to open source & open development. Our work is focused on building open tools, technologies, and techniques that sustain and advance blockchain and internet security infrastructure and promote an open web. It's funded entirely by donations and collaborative partnerships with people like you.

        For the FullyNoded 2 source code and detailed information about how the app works, please visit the GitHub repo.

        If you find this project useful, and would like to learn more about Blockchain Commons, click the Blockchain Commons logo within the app. You can become a Blockchain Commons patron and support projects like this!
        """
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["BTCPayServer": donationLinkUrl, "Blockchain Commons": homePageUrl, "GitHub repo": repoLink, "Blockchain Commons patron": sponsorLink])
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
        if (URL.absoluteString == donationLinkUrl) || (URL.absoluteString == homePageUrl) || (URL.absoluteString == repoLink) || (URL.absoluteString == sponsorLink) {
            UIApplication.shared.open(URL) { (Bool) in

            }
        }
        return false
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "next3", sender: self)
            
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
