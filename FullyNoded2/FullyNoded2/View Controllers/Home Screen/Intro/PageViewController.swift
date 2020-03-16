//
//  PageViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit
import AuthenticationServices
import KeychainSwift

class PageViewController: UIViewController, UITextViewDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var doneBlock : ((Bool) -> Void)?
    let declineButton = UIButton()
    let acceptButton = UIButton()
    var titleLabel = UILabel()
    var textView = UITextView()
    var imageView = UIImageView()
    var page: Pages
    var donationLinkUrl = "https://btcpay.blockchaincommons.com"
    var homePageUrl = "www.blockchaincommons.com"
    var repoLink = "https://github.com/BlockchainCommons/FullyNoded-2"
    var standupAppLink = "https://drive.google.com/open?id=1lXyl_zO6WPJN5tzWAVV3p42WPFtyesCR"
    var scriptLink = "https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/Scripts"
    var recoveryUrl = "https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Recovery.md"
    var libwallyLink = "https://github.com/blockchain/libwally-swift/blob/master/README.md"
    var sponsorLink = "https://github.com/sponsors/BlockchainCommons"
    var myNodeLink = "http://www.mynodebtc.com"
    var raspiBlitzLink = "https://raspiblitz.com"
    var nodlLink = "https://www.nodl.it"
    var btcpayLink = "https://btcpayserver.org"
    var fullynoded1Link = "https://apps.apple.com/us/app/fully-noded/id1436425586"
    var torLink = "https://www.torproject.org"
    var hiddenServiceLink = "https://blog.torproject.org/tors-fall-harvest-next-generation-onion-services"
    var authLink = "https://matt.traudt.xyz/p/FgbdRTFr.html"
    var licenseLink = "https://spdx.org/licenses/BSD-2-Clause-Patent.html"
    var quickConnectLink = "https://github.com/BlockchainCommons/Bitcoin-Standup#quick-connect-url-using-btcstandup"
    
    init(with page: Pages) {
        self.page = page
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        textView.delegate = self
        
        imageView.frame = CGRect(x: 16, y: 100, width: 40, height: 40)
        imageView.image = page.image
        if page.index == 2 {
            imageView.tintColor = .systemPink
        } else {
            imageView.tintColor = .lightGray
        }
        
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        let logoView = UIImageView()
        logoView.image = UIImage(imageLiteralResourceName: "1024.png")
        logoView.frame = CGRect(x: view.frame.midX - 25, y: 30, width: 50, height: 50)
        logoView.contentMode = .scaleAspectFit
        view.addSubview(logoView)
        
        titleLabel.frame = CGRect(x: imageView.frame.maxX + 5, y: imageView.frame.origin.y, width: (view.frame.width - 16) - (imageView.frame.width + 5), height: 30)
        titleLabel.textAlignment = NSTextAlignment.left
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        titleLabel.text = page.title
        titleLabel.textColor = .lightGray
        titleLabel.sizeToFit()
        view.addSubview(titleLabel)
        
        textView.frame = CGRect(x: 16, y: titleLabel.frame.maxY + 20, width: view.frame.width - 32, height: view.frame.height - 350)
        textView.text = page.body
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = true
        textView.textAlignment = .left
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 13)
        textView.isEditable = false
        textView.addHyperLinksToText(originalText: page.body, hyperLinks: ["BTCPayServer": donationLinkUrl, "blockchaincommons.com": homePageUrl, "GitHub repo": repoLink, "StandUp.app": standupAppLink, "StandUp.sh scripts": scriptLink, "Recovery.md": recoveryUrl, "LibWally": libwallyLink, "GitHub Sponsor": sponsorLink, "MyNode": myNodeLink, "RaspiBlitz": raspiBlitzLink, "Nodl": nodlLink, "BTCPay": btcpayLink, "FullyNoded 1": fullynoded1Link, "Tor": torLink, "V3 hidden service": hiddenServiceLink, "Tor V3 authentication": authLink, "https://spdx.org/licenses/BSD-2-Clause-Patent.html": licenseLink, "QuickConnect QR": quickConnectLink])

        view.addSubview(textView)
        
        let buttonwidth = (((view.frame.width - 64) / 2) - 15)
        
        acceptButton.frame = CGRect(x: 32, y: textView.frame.maxY + 20, width: buttonwidth, height: 50)
        acceptButton.clipsToBounds = true
        acceptButton.layer.cornerRadius = 8
        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.backgroundColor = #colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
        acceptButton.setTitleColor(.systemTeal, for: .normal)
        acceptButton.addTarget(self, action: #selector(accept), for: .touchUpInside)
        
        declineButton.frame = CGRect(x: view.frame.maxX - (buttonwidth + 32), y: textView.frame.maxY + 20, width: buttonwidth, height: 50)
        declineButton.clipsToBounds = true
        declineButton.layer.cornerRadius = 8
        declineButton.setTitle("Decline", for: .normal)
        declineButton.backgroundColor = #colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
        declineButton.setTitleColor(.systemRed, for: .normal)
        declineButton.addTarget(self, action: #selector(decline), for: .touchUpInside)
        
        if page.index == 5 {
        
            view.addSubview(acceptButton)
            view.addSubview(declineButton)
            
        } else {
            
            acceptButton.removeFromSuperview()
            declineButton.removeFromSuperview()
            
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let logInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .whiteOutline)
        logInButton.sizeToFit()
        logInButton.addTarget(self, action: #selector(handleLogInWithAppleID), for: .touchUpInside)
        logInButton.frame = CGRect(x: 32, y: view.frame.maxY - 100, width: view.frame.width - 64, height: 80)
        
        if page.index == 6 {
            
            if UserDefaults.standard.object(forKey: "acceptedDisclaimer") as! Bool == false {
                
                showAlert(vc: self, title: "Oops", message: "You have not yet accepted the disclaimer, please go back and accept it to move forward.")
                
            } else {
                
                view.addSubview(logInButton)
                
            }
            
        }
        
    }
    
    @objc func handleLogInWithAppleID() {
        print("handleLogInWithAppleID")
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    private func impact() {
        
        DispatchQueue.main.async {
            
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            
        }
        
    }
    
    @objc func accept() {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.acceptButton.removeFromSuperview()
            self.declineButton.removeFromSuperview()
            
        }
        
        UserDefaults.standard.set(true, forKey: "acceptedDisclaimer")
        
        showAlert(vc: self, title: "Accepted!", message: "Please swipe left to the final step.")
        
    }
    
    @objc func decline() {
        
        impact()
        
        showAlert(vc: self, title: "Are you sure?", message: "If you do not accept the disclaimer then unfortunately you will not be able to use the app.")
        
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if (URL.absoluteString == donationLinkUrl) || (URL.absoluteString == homePageUrl) || (URL.absoluteString == repoLink) {
            UIApplication.shared.open(URL) { (Bool) in

            }
        }
        return false
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        
        return self.view.window!
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIDCredential.user
            let keychain = KeychainSwift()
            keychain.set(userIdentifier, forKey: "userIdentifier")
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    NotificationCenter.default.post(name: .didCompleteOnboarding, object: nil, userInfo: nil)
                }
            }
        default:
            break
        }

    }

}

extension UITextView {

  func addHyperLinksToText(originalText: String, hyperLinks: [String: String]) {
    let style = NSMutableParagraphStyle()
    style.alignment = .left
    let attributedOriginalText = NSMutableAttributedString(string: originalText)
    for (hyperLink, urlString) in hyperLinks {
        let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
        let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
        attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
        attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
        attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 17), range: fullRange)
        attributedOriginalText.addAttribute(.foregroundColor, value: UIColor.lightGray, range: fullRange)
    }

    self.linkTextAttributes = [
        NSAttributedString.Key.foregroundColor: UIColor.systemTeal
    ]
    self.attributedText = attributedOriginalText
  }
}
