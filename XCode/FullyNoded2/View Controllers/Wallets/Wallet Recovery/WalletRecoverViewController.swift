//
//  WalletRecoverViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class WalletRecoverViewController: UIViewController, UITextFieldDelegate {
    
    var testingWords = Bool()
    var str:DescriptorStruct!
    let connectingView = ConnectingView()
    var walletName = ""
    var recoveryDict = [String:Any]()
    var onQrDoneBlock: ((Bool) -> Void)?
    @IBOutlet var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanButton.layer.cornerRadius = 8
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if UIPasteboard.general.hasImages {
            
            if let image = UIPasteboard.general.image {
                
                let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
                let ciImage:CIImage = CIImage(image: image)!
                var qrCodeLink = ""
                let features = detector.features(in: ciImage)
                for feature in features as! [CIQRCodeFeature] {
                    qrCodeLink += feature.messageString!
                }
                
                if let data = qrCodeLink.data(using: .utf8) {
                    
                    Encryption.getNode { (node, error) in
                        
                        if !error && node != nil {
                            
                            do {
                                
                                let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                                
                                if let _ = dict["descriptor"] as? String {
                                    
                                    if let _ = dict["birthdate"] as? Int32 {
                                        
                                        if let _ = dict["entropy"] as? String {
                                            
                                            if let _ = dict["blockheight"] as? Int {
                                                
                                                DispatchQueue.main.async { [unowned vc = self] in
                                                    
                                                    let alert = UIAlertController(title: "There is a valid Recovery QR image on your clipboard", message: "Would you like to upload this image as a Recovery QR?", preferredStyle: .actionSheet)
                                                    
                                                    alert.addAction(UIAlertAction(title: "Upload Recovery QR", style: .default, handler: { action in
                                                        
                                                        vc.recoveryDict = dict
                                                        vc.validRecoveryScanned()
                                                        
                                                    }))
                                                    
                                                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                                    alert.popoverPresentationController?.sourceView = self.view
                                                    vc.present(alert, animated: true, completion: nil)
                                                    
                                                    
                                                }
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            } catch  {}
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else if UIPasteboard.general.hasStrings {
            
            if let value = UIPasteboard.general.string {
                
                if let data = value.data(using: .utf8) {
                    
                    Encryption.getNode { (node, error) in
                        
                        if !error && node != nil {
                            
                            do {
                                
                                let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                                
                                if let _ = dict["descriptor"] as? String {
                                    
                                    if let _ = dict["birthdate"] as? Int32 {
                                        
                                        if let _ = dict["entropy"] as? String {
                                            
                                            if let _ = dict["blockheight"] as? Int {
                                                
                                                DispatchQueue.main.async { [unowned vc = self] in
                                                                
                                                    let alert = UIAlertController(title: "There is a valid Recovery QR text on your clipboard", message: "Would you like to upload this text as a Recovery QR?", preferredStyle: .actionSheet)

                                                    alert.addAction(UIAlertAction(title: "Upload Recovery QR text", style: .default, handler: { action in
                                                        
                                                        vc.recoveryDict = dict
                                                        vc.validRecoveryScanned()
                                                        
                                                    }))
                                                    
                                                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                                    alert.popoverPresentationController?.sourceView = self.view
                                                    vc.present(alert, animated: true, completion: nil)
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            } catch {}
                            
                        }
                        
                    }
                                
                }
                
            }
            
        }
        
    }
    
    @IBAction func getWordsAction(_ sender: Any) {
        
        getWords()
        
    }
    
    
    @IBAction func scanAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "scanRecovery", sender: self)
            
        }
        
    }
    
    private func validRecoveryScanned() {
        
        /// get the hot descriptor from the QR
        let desc = recoveryDict["descriptor"] as! String
        
        /// convert the hot descriptor to a pubkey descriptor
        let pubkeyDesc = convertDescriptor(desc)
        
        /// get the wallet name from the pubkey descriptor
        let walletName = Encryption.sha256hash(pubkeyDesc)
        
        /// search all nodes for that wallet
        checkIfWalletExists(name: walletName)
        
    }
    
    private func convertDescriptor(_ hotDescriptor: String) -> String {
        let p = DescriptorParser()
        str = p.descriptor(hotDescriptor)
        
        if str.isMulti {
            let xprv = str.multiSigKeys[1]
            let xpub = HDKey(xprv)!.xpub
            return hotDescriptor.replacingOccurrences(of: xprv, with: xpub)
            
        } else {
            let xprv = str.accountXprv
            let xpub = HDKey(xprv)!.xpub
            return hotDescriptor.replacingOccurrences(of: xprv, with: xpub)
        }
        
    }
    
    private func checkIfWalletExists(name: String) {
        walletName = name
        connectingView.addConnectingView(vc: self, description: "searching your node for that wallet")
        
        /// First check if the wallet exists on the current node
        Reducer.makeCommand(walletName: "", command: .listwalletdir, param: "") { [unowned vc = self] (object, errorDescription) in
            
            if let dict = object as? NSDictionary {
                
                if let wallets = dict["wallets"] as? NSArray {
                    
                    var walletExists = false
                    
                    for (i, wallet) in wallets.enumerated() {
                        
                        if let walletDict = wallet as? NSDictionary {
                            
                            if (walletDict["name"] as? String ?? "") == name {
                                
                                walletExists = true
                                
                            }
                            
                            if i + 1 == wallets.count {
                                
                                if walletExists {
                                    
                                    print("wallet exists")
                                    vc.checkDeviceForWallet(name: name)
                                    
                                } else {
                                    
                                    print("wallet does not exist")
                                    vc.connectingView.removeConnectingView()
                                    
                                    //  MARK: TO DO
                                    /// - See if other nodes exist that are on the same network, if there are prompt the user and ask if we should search those nodes too?
                                    
                                    if vc.str.isMulti {
                                        
                                        DispatchQueue.main.async { [unowned vc = self] in
                                                        
                                            let alert = UIAlertController(title: "Recovery Words are Required", message: "We could not find that wallet on your current node, if you would like to recover it on your current node you will need your offline recovery words", preferredStyle: .actionSheet)

                                            alert.addAction(UIAlertAction(title: "Add Recovery Words", style: .default, handler: { action in
                                                
                                                vc.getWords()
                                                
                                            }))
                                            
                                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                            alert.popoverPresentationController?.sourceView = self.view
                                            vc.present(alert, animated: true, completion: nil)
                                            
                                        }
                                        
                                    } else {
                                        
                                        vc.recoveryDict["walletExistsOnNode"] = false
                                        vc.connectingView.removeConnectingView()
                                        vc.confirm()
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "error: \(errorDescription ?? "invalid response from bitcoind")")
                
            }
            
        }
        
    }
    
    private func checkDeviceForWallet(name: String) {
        CoreDataService.retrieveEntity(entityName: .wallets) { [unowned vc = self] (wallets, errorDescription) in
            
            if wallets != nil {
                
                if wallets!.count > 0 {
                    
                    var walletExists = false
                    
                    for (i, wallet) in wallets!.enumerated() {
                        
                        let str = WalletStruct(dictionary: wallet)
                        if str.id != nil && str.name != nil && !str.isArchived {
                            
                            if str.name! == name {
                                
                                walletExists = true
                                
                            }
                                                        
                        }
                        
                        if i + 1 == wallets!.count {
                            
                            if walletExists {

                                vc.recoveryDict.removeAll()
                                vc.connectingView.removeConnectingView()
                                showAlert(vc: vc, title: "Wallet already exists", message: "That wallet already exists on your node and device, there is no need to recover it.")

                            } else {
                                
                                vc.connectingView.removeConnectingView()
                                
                                if vc.str.isMulti {
                                    
                                    DispatchQueue.main.async { [unowned vc = self] in
                                                    
                                        let alert = UIAlertController(title: "Multisig wallet recovery", message: "We found the wallet on your node, it is important to ensure you still have your offline recovery words for this wallet incase in the future you lose your node. You may test your offline recovery words now if you would like to.\n\nYou can always test your recovery words by refilling a multisig wallet's keypool from \"wallet tools\".", preferredStyle: .actionSheet)

                                        alert.addAction(UIAlertAction(title: "Test recovery words", style: .default, handler: { action in
                                            
                                            vc.testingWords = true
                                            vc.getWords()
                                            
                                        }))
                                        
                                        alert.addAction(UIAlertAction(title: "No thanks, recover now!", style: .default, handler: { action in
                                            
                                            vc.confirm()
                                            
                                        }))
                                        
                                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                        alert.popoverPresentationController?.sourceView = self.view
                                        vc.present(alert, animated: true, completion: nil)
                                        
                                    }
                                    
                                } else {
                                    
                                    vc.confirm()
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    vc.confirm()
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                vc.confirm()
                
            }
            
        }
        
    }
    
    @IBAction func moreinfo(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "showInfo", sender: self)
            
        }
        
    }
    
    private func confirm() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "goConfirmQr", sender: vc)
            
        }
        
    }
    
    private func getWords() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "getWords", sender: vc)
            
        }
        
    }
    
    private func processDescriptor(descriptor: String) {
        
        let cv = ConnectingView()
        cv.addConnectingView(vc: self, description: "processing...")
        
        if let data = descriptor.data(using: .utf8) {
            
            do {
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
            
                if let _ = dict["descriptor"] as? String {
                    
                    if let _ = dict["blockheight"] as? Int {
                        /// It is an Account Map.
                        Import.importAccountMap(accountMap: dict) { walletDict in
                            print("importAccountMap")
                            
                            if walletDict != nil {
                                DispatchQueue.main.async { [unowned vc = self] in
                                    vc.recoveryDict = walletDict!
                                    vc.walletName = walletDict!["name"] as! String
                                    vc.performSegue(withIdentifier: "goConfirmQr", sender: vc)
                                    
                                }
                            }
                        }
                    }
                }
                
            } catch {
                /// It is not an Account Map.
                Import.importDescriptor(descriptor: descriptor) { [unowned vc = self] walletDict in
                    
                    if walletDict != nil {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.recoveryDict = walletDict!
                            vc.walletName = walletDict!["name"] as! String
                            vc.performSegue(withIdentifier: "goConfirmQr", sender: vc)
                            
                        }
                        
                    } else {
                        cv.removeConnectingView()
                        showAlert(vc: vc, title: "Error", message: "error importing that account")
                        
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "getWords":
            
            if let vc = segue.destination as? WordRecoveryViewController {
                
                vc.testingWords = testingWords
                vc.recoveryDict = recoveryDict
                vc.walletNameHash = walletName
                
            }
            
        case "goConfirmQr":
            
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                
                vc.walletNameHash = walletName
                vc.walletDict = recoveryDict
                vc.isImporting = true
//                vc.confirmedDoneBlock = { [unowned thisVc = self] result in
//                    
//                    if result {
//                        
//                        thisVc.recover(dict: thisVc.recoveryDict)
//                        
//                    } else {
//                        
//                        DispatchQueue.main.async {
//                            
//                            thisVc.dismiss(animated: true, completion: nil)
//                            
//                        }
//                        
//                    }
//                    
//                }
                
            }
            
        case "scanRecovery":
            
            if let vc = segue.destination as? ScannerViewController {
                
                //vc.importin = true
                vc.isImporting = true
//                vc.onDoneRecoveringBlock = { [unowned thisVc = self] dict in
//
//                    thisVc.recoveryDict = dict
//                    thisVc.validRecoveryScanned()
//
//                }
                vc.onImportDoneBlock = { [unowned thisVc = self] descriptor in
                    
                    thisVc.processDescriptor(descriptor: descriptor)
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }

}
