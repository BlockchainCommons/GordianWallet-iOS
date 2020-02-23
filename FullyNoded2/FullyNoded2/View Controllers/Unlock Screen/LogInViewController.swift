//
//  LogInViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

//need to copy account creation to create account view controller

import UIKit
import KeychainSwift
import AuthenticationServices

class LogInViewController: UIViewController, UITextFieldDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        let logInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .whiteOutline)
        logInButton.sizeToFit()
        logInButton.addTarget(self, action: #selector(handleLogInWithAppleID), for: .touchUpInside)
        logInButton.frame = CGRect(x: 32, y: 100, width: view.frame.width - 64, height: 80)
        view.addSubview(logInButton)
        
        let description = UILabel()
        description.font = .systemFont(ofSize: 16, weight: .light)
        description.numberOfLines = 0
        description.frame = CGRect(x: 48, y: logInButton.frame.maxY + 5, width: self.view.frame.width - 96, height: 150)
        description.text = "Blockchain Commons, LLC and FullyNoded 2 do not use or save your Apple ID data in anyway, it is used solely for 2FA (two-factor authentication) purposes only."
        description.sizeToFit()
        description.textAlignment = .left
        description.textColor = .white
        view.addSubview(description)
        
    }
    
    @objc func handleLogInWithAppleID() {
        print("handleLogInWithAppleID")
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        switch authorization.credential {

        case let appleIDCredential as ASAuthorizationAppleIDCredential:

            let userIdentifier = appleIDCredential.user
            let keychain = KeychainSwift()
            keychain.set(userIdentifier, forKey: "userIdentifier1")
            self.dismiss(animated: true, completion: nil)

            break

        default:

            break

        }

    }
    
}

extension UIViewController {
    
    func topViewController() -> UIViewController! {
        
        if self.isKind(of: UITabBarController.self) {
            
            let tabbarController =  self as! UITabBarController
            
            return tabbarController.selectedViewController!.topViewController()
            
        } else if (self.isKind(of: UINavigationController.self)) {
            
            let navigationController = self as! UINavigationController
            
            return navigationController.visibleViewController!.topViewController()
            
        } else if ((self.presentedViewController) != nil) {
            
            let controller = self.presentedViewController
            
            return controller!.topViewController()
            
        } else {
            
            return self
            
        }
        
    }

}




