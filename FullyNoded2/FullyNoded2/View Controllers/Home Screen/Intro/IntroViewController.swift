//
//  IntroViewController.swift
//  FullyNoded 2
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

enum Pages: CaseIterable {
    case pageZero
    case pageOne
    case pageTwo
    case pageThree
    case pageFour
    case pageFive
    case pageSix
    
    var title: String {
        switch self {
        case .pageZero:
            return "Welcome to FullyNoded 2!"
        case .pageOne:
            return "What is FullyNoded 2?"
        case .pageTwo:
            return "How to support development of FullyNoded 2?"
        case .pageThree:
            return "How to use FullyNoded 2?"
        case .pageFour:
            return "Is FullyNoded 2 secure?"
        case .pageFive:
            return "License & Disclaimer"
        case .pageSix:
            return "Sign in with Apple"
        }
    }
    
    var image: UIImage {
        switch self {
        case .pageZero:
            return UIImage(systemName: "hand.thumbsup")!
        case .pageOne:
            return UIImage(systemName: "info.circle")!
        case .pageTwo:
            return UIImage(systemName: "heart")!
        case .pageThree:
            return UIImage(systemName: "wrench")!
        case .pageFour:
            return UIImage(systemName: "lock.shield")!
        case .pageFive:
            return UIImage(systemName: "exclamationmark.bubble")!
        case .pageSix:
            return UIImage(systemName: "person.crop.circle.badge.checkmark")!
        }
        
    }
    
    var body: String {
        
        switch self {
            
        case .pageZero:
        
            return "Thanks for trying out FullyNoded 2!\n\nYou will be connected to your own node and interacting with the Bitcoin network in a secure self-sovereign way in no time.\n\nBut first there are a few things you should know.\n\nPlease swipe left, until the end.\n\nWe appreciate your attention and patience!"
            
        case .pageOne:
            
            return "FullyNoded 2 is the successor app to FullyNoded 1.\n\nThe apps are very similiar yet very different in what they do. You can think of FullyNoded1 as a powerful, raw interface between you and your node where all the functionality is quite manual and meant for expert users.\n\nFullyNoded 2 is designed to be extremely easy to use without sacrificing functionality or security, it is a focused wallet which leverages the power of your node and your device in the best possible ways. FullyNoded 2 utilizes a well known library called LibWally which allows us to create seeds and sign transactions without needing an internet connection or your node at all. That makes FullyNoded 2 a hybrid between a hardware wallet and a remote control for your own personal node.\n\nFullyNoded 2 is capable of creating two wallet types; single-signature and multi-signature.\n\nSingle signature wallets:\n\n The app will create a seed, convert it to your back up words, encrypt the seed, store it locally on your device and then creates a specific wallet on your node, importing 2,000 public keys into it.\n\nFullyNoded 2 uses your node strictly as a watch-only wallet and does not interfere with any existing wallets on your node. In this way your node can be in charge of building unsigned PSBT's and your device will take those unsigned PSBT's and fetch the necessary private keys, decrypt them and then sign the transaction locally on your device. At that point the app will use your node to analyze the signed transaction displaying all the inputs and outputs to you for your verification before you broadcast.\n\nMulti-signature wallets:\n\n2 of 3 multi-sig wallet whereby your device holds one seed for signing locally, your node holds 2,000 private keys derived from a second seed and you securely store a third seed offline in the form of a 12 word BIP39 recovery phrase along with a RecoveryQR code to use in the unlikely event that you ever lose your node AND device. This is beneficial because if anyone stole your node or hacked their way into it they would not have any access to your funds, same goes for the offline recovery words. In short FullyNoded 2 makes using multi-signature easy for anyone.\n\nFor more information regarding wallet recovery please see our Recovery.md file."
            
        case .pageTwo:
            
            return "FullyNoded 2 is made possible by Blockchain Commons, A \"not-for-profit\" benefit corporation. Founded to support blockchain infrastructure & the broader security industry through cryptographic & privacy protocol implementations, research, and standards.\n\nPlease consider sponsoring this specific project by becoming a GitHub Sponsor.\n\nPlease consider supporting us via donations at our BTCPayServer.\n\nPlease see our website for more info at blockchaincommons.com.\n\nCheckout the GitHub repo which includes the source code and detailed information about how the app works."
            
        case .pageThree:
            
            return "Connect to your node by scanning the QuickConnect QR code that your node software produces, supporting node software includes StandUp.app (MacOS), BTCPay, MyNode, RaspiBlitz and Nodl. Of course you may do this yourself by following the instructions on our github or you can also use our simple StandUp.sh scripts for linux.\n\nThe app will then do all the hard work for you. Using FullyNoded 2 is straightforward, to create a Bitcoin invoice just tap the \"In\" button, to spend Bitcoin just tap the \"Out\" button."
            
        case .pageFour:
            
            return "FullyNoded 2 runs a Tor node which it uses to connect to your nodes V3 hidden service over the onion network. This way you can privately and securely control your nodes wallet functionality remotely from anywhere in the world, allowing you to keep your node completely behind a firewall with no port forwarding required. The app uses a lot of security minded features to avoid any sensitive info being recorded to your devices memory regarding the Tor traffic. Clearnet traffic is strictly disabled, the Tor config settings excludes exit nodes from your Tor circuit meaning it will only ever interact with the Tor network.\n\nFullyNoded 2 uses powerful encryption to secure your your nodes hidden service urls and private keys. Initially a private key is created which is stored on your devices keychain which is itself encrypted. That private key is used to decrypt/encrypt the apps sensitive data. Whenever your device goes into the background all the apps data becomes encrypted yet again. No sensitive info is ever stored unencrypted or transmitted over the internet in clear text. All Tor traffic is highly encrypted by default.\n\nFullyNoded 2 utilizes the latest generation of hidden services and allows you to take advantage of Tor V3 authentication, meaning your device is capable of producing a private/public key offline where you may upload the public to your node to ensure that your device is the only device in the world that can access your node EVEN IF an attacker managed to get your nodes hidden service url. This means of authentication is particularly handy if you want to share your node with trusted others, ensuring only they have access. This is possible because you as the user never have access to the private key used for authentication, so even if users share their public keys with an attacker it would be useless to them. To be clear the way it works is FullyNoded will create the ultra secret private key, encrypt it and store it locally, it then get decrypted when the Tor node starts up, whenever your app goes into the background the private key is deleted from your Tor config, the file the private key is saved on is also maximally protected by native iOS encryption on top of a secondary layer of encryption we give it, you as theuser will never see or have access to the private key and without that private key no device or attacker can possibly get access to your nodes hidden service. Of course there may be attack vectors we are not aware of and it is important you do your own research and look at the codebase if you are curious."
            
        case .pageFive:
            
            return "Please read and accept the terms of our disclaimer:\n\nThe use of FullyNoded 2 is under the \"BSD 2-Clause Plus Patent License\" (https://spdx.org/licenses/BSD-2-Clause-Patent.html). Copyright © 2019 BlockchainCommons. All rights reserved. With the disclaimer: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
            
        case .pageSix:
            
            return "In order to initially use this app we require that you utilize Apple's built in \"Sign in with Apple\" tool as a form of two-factor authentication.\n\nWe do not need your AppleID and we do not save your email, we simply use this to confirm it is in fact you using the app, then later when you go to broadcast transactions or export seeds/private keys we will use this tool again to ensure noone other then yourself gets access to your funds."
            
        }
    }
    
    var index: Int {
        switch self {
        case .pageZero:
            return 0
        case .pageOne:
            return 1
        case .pageTwo:
            return 2
        case .pageThree:
            return 3
        case .pageFour:
            return 4
        case .pageFive:
            return 5
        case .pageSix:
            return 6
        }
    }
}

class IntroViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    private var pageController: UIPageViewController?
    private var pages: [Pages] = Pages.allCases
    private var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupPageController()
        
    }
    
    private func setupPageController() {
        
        self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageController?.dataSource = self
        self.pageController?.delegate = self
        self.pageController?.view.backgroundColor = .clear
        self.pageController?.view.frame = self.view.frame//CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.addChild(self.pageController!)
        self.view.addSubview(self.pageController!.view)
        
        let initialVC = PageViewController(with: pages[0])
        
        self.pageController?.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
        
        self.pageController?.didMove(toParent: self)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return self.currentIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? PageViewController else {
            return nil
        }
        
        var index = currentVC.page.index
        
        if index == 0 {
            return nil
        }
        
        index -= 1
        
        let vc: PageViewController = PageViewController(with: pages[index])
        
        return vc
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? PageViewController else {
            return nil
        }
                
        var index = currentVC.page.index
        
        if index >= self.pages.count - 1 {
            return nil
        }
        
        index += 1
        
        let vc: PageViewController = PageViewController(with: pages[index])
        
        return vc
        
    }
    
}
