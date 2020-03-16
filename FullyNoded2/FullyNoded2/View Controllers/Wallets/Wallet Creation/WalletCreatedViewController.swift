//
//  WalletCreatedViewController.swift
//  FullyNoded2
//
//  Created by Peter on 12/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

var recoveryString:String!
var words:String!
var derivation:String!
var isMultiSig:Bool!
var walletDoneBlock : ((Bool) -> Void)?
var id:UUID!

enum WalletPages: CaseIterable {
    case pageZero
    case pageOne
    case pageTwo
    
    var walletId: UUID {
        return id
    }
    
    var doneBlock: ((Bool) -> Void)? {
        return walletDoneBlock
    }
    
    var isMulti: Bool {
        return isMultiSig
    }
    
    var derivationScheme: String {
        switch self {
        case .pageTwo:
            return derivation
        default:
            return ""
        }
    }
    
    var recoveryItem: String {
        switch self {
        case .pageOne:
            return recoveryString
        case .pageTwo:
            return words
        default:
            return ""
        }
    }
    
    var title: String {
        switch self {
        case .pageZero:
            return "Wallet successfully created!"
        case .pageOne:
            return "RecoveryQR Code"
        case .pageTwo:
            return "BIP39 Recovery Phrase"
        }
    }
    
    var image: UIImage {
        switch self {
        case .pageZero:
            return UIImage(systemName: "checkmark.circle")!
        case .pageOne:
            return UIImage(systemName: "qrcode")!
        case .pageTwo:
            return UIImage(systemName: "list.number")!
        }
        
    }
    
    var singleSigBody: String {
        
        switch self {
            
        case .pageZero:
        
            return "In order to ensure you can recover your wallets there is some information you ought to record securely.\n\nYou will be presented with a RecoveryQR code and a 12 word recovery phrase.\n\nYou should make mutliple backups of each and store them in seperate locations.\n\nGive your wallet a label in the below text field:"
            
        case .pageOne:
            
            return "This is your RecoveryQR and is the easiest way of revovering your wallet.\n\nStore it somewhere safe and keep it off the internet, ideally print it. Just tap it to export it.\n\nWe highly encourage you to test this functionality! You can create test wallets, delete them, and recover them to get familiar with how it works and to trust that it does work."
            
        case .pageTwo:
            
            return "FullyNoded 2 does *NOT* use a passphrase to encrypt your recovery phrase.\n\nWe recommend writing these words down on water proof paper with a permanent marker along with the derivation path.\n\nThese words are for redundancy and for recovering with other apps.\n\nJust tap the words to export them."
            
        }
    }
    
    var multiSigBody: String {
        
        switch self {
            
        case .pageZero:
        
            return "In order to recover your wallet there is some information you ought to save securely.\n\nYou will be presented with a RecoveryQR code (your devices seed) and a 12 word recovery phrase (the offline backup seed).\n\nIt is recommended you store these two items in different locations.\n\nSaving both the RecoveryQR and the 12 word recovery phrase will ensure you can fully recover your multi-signature wallet *even* if you lose your device *AND* your node.\n\nGive your wallet a label in the below text field:"
            
        case .pageOne:
            
            return "This is your RecoveryQR and is the easiest way to revover your wallet. If you lost your device you can simply get a new one, download FullyNoded 2, add your node and then recover the wallet on your device with this QR.\n\nStore it somewhere very safe and keep it off the internet, ideally print it on waterproof paper. Just tap it to export it.\n\nWe highly encourage you to test this functionality by creating test wallets, deleting them from your device/node, and recover them."
            
        case .pageTwo:
            
            return "You *MUST* write these words down and save them seperately from the RecoveryQR, *THEY ARE REQUIRED* to recover a multi-signature wallet if you lose your node *AND* device.\n\nThese words **WILL BE DELETED FOREVER** once you navigate away from this page.\n\nAt a minimum we recommend writing these words down on water proof paper with a permanent marker.\n\nTap the words to export them."
            
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
        }
    }
}

class WalletCreatedViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    private var pageController: UIPageViewController?
    private var pages: [WalletPages] = WalletPages.allCases
    private var currentIndex: Int = 0
    var recoveryQr = ""
    var recoveryPhrase = ""
    var derivationPath = ""
    var isMulti = Bool()
    var walletDoneNowBlock : ((Bool) -> Void)?
    var walletId:UUID!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        id = walletId
        isMultiSig = isMulti
        recoveryString = recoveryQr
        words = recoveryPhrase
        derivation = derivationPath
        walletDoneBlock = walletDoneNowBlock
        self.setupPageController()

    }
    
    private func setupPageController() {
        
        self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageController?.dataSource = self
        self.pageController?.delegate = self
        self.pageController?.view.backgroundColor = .clear
        self.pageController?.view.frame = self.view.frame
        self.addChild(self.pageController!)
        self.view.addSubview(self.pageController!.view)
        
        let initialVC = WalletPageViewController(with: pages[0])
        
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
        
        guard let currentVC = viewController as? WalletPageViewController else {
            return nil
        }
        
        var index = currentVC.page.index
        
        if index == 0 {
            return nil
        }
        
        index -= 1
        
        let vc: WalletPageViewController = WalletPageViewController(with: pages[index])
        
        return vc
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let currentVC = viewController as? WalletPageViewController else {
            return nil
        }
                
        var index = currentVC.page.index
        
        if index >= self.pages.count - 1 {
            return nil
        }
        
        index += 1
        
        let vc: WalletPageViewController = WalletPageViewController(with: pages[index])
        
        return vc
        
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
