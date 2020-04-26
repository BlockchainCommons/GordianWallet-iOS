//
//  LicenseDisclaimerViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class LicenseDisclaimerViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate {

    @IBOutlet var textView: UITextView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var declineOutlet: UIButton!
    @IBOutlet var acceptOutlet: UIButton!
    
    let licenseLink = "https://spdx.org/licenses/BSD-2-Clause-Patent.html"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        setTitleView()
        declineOutlet.layer.cornerRadius = 8
        acceptOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        
        textView.text = """
        Please read and accept the terms of our disclaimer:

        The use of FullyNoded 2 is under the "BSD 2-Clause Plus Patent License" (https://spdx.org/licenses/BSD-2-Clause-Patent.html). Copyright © 2019 BlockchainCommons. All rights reserved. With the disclaimer: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        """
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["https://spdx.org/licenses/BSD-2-Clause-Patent.html": licenseLink])
        
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
