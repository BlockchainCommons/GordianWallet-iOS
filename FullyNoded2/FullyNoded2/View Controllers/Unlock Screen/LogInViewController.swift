//
//  LogInViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

//TODO: Need to copy account creation to create account view controller

import UIKit
import KeychainSwift
import AuthenticationServices

/// View Controller that handles app authorization via Apple ID.
class LogInViewController: UIViewController {
    
    let lblDescription = UILabel()
    let btnLogin = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .whiteOutline)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    func setupViews() {
        
        view.backgroundColor = .black
        
        btnLogin.translatesAutoresizingMaskIntoConstraints = false
        lblDescription.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(btnLogin)
        view.addSubview(lblDescription)
        
        btnLogin.addTarget(self, action: #selector(handleLogInWithAppleID), for: .touchUpInside)
        
        lblDescription.font = .systemFont(ofSize: 12, weight: .regular)
        lblDescription.numberOfLines = 0
        lblDescription.text = "Blockchain Commons and Fully Noded do not save your Apple ID. It is used purely for 2 factor authentication purposes only."
        lblDescription.textAlignment = .left
        lblDescription.textColor = .lightGray
        
        btnLogin.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btnLogin.widthAnchor.constraint(equalToConstant: 300).isActive = true
        btnLogin.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0).isActive = true
        btnLogin.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        
        lblDescription.heightAnchor.constraint(equalToConstant: 75).isActive = true
        lblDescription.topAnchor.constraint(equalTo: btnLogin.bottomAnchor, constant: 10).isActive = true
        lblDescription.widthAnchor.constraint(equalTo: btnLogin.widthAnchor, constant: 0).isActive = true
        lblDescription.centerXAnchor.constraint(equalTo: btnLogin.centerXAnchor, constant: 0).isActive = true
        
    }
    
    @objc func handleLogInWithAppleID() {
        print("handleLogInWithAppleID")
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

/// ASAuthorization protocol extension
extension LogInViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    // Derives a keychain based on an Apple ID upon successful authorization.
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
