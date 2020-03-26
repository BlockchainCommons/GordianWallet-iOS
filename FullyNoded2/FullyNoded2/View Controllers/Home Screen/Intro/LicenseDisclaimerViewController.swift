//
//  LicenseDisclaimerViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class LicenseDisclaimerViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var textView: UITextView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var declineOutlet: UIButton!
    @IBOutlet var acceptOutlet: UIButton!
    
    let licenseLink = "https://spdx.org/licenses/BSD-2-Clause-Patent.html"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        declineOutlet.layer.cornerRadius = 8
        acceptOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["https://spdx.org/licenses/BSD-2-Clause-Patent.html": licenseLink])
        
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if (URL.absoluteString == licenseLink) {
            UIApplication.shared.open(URL) { (Bool) in

            }
        }
        return false
    }
    
    @IBAction func acceptAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            UserDefaults.standard.set(true, forKey: "acceptedDisclaimer1")
            self.performSegue(withIdentifier: "next6", sender: self)
            
        }
        
    }
    
    @IBAction func declineAction(_ sender: Any) {
        
        UserDefaults.standard.set(false, forKey: "acceptedDisclaimer1")
        showAlert(vc: self, title: "Are you sure?", message: "Unfortunately if you decline the disclaimer then you can not use the app.")
        
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
