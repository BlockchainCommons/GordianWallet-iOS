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
    var alertStyle = UIAlertController.Style.actionSheet
    
    @IBOutlet weak var seedWordsOutlet: UIButton!
    @IBOutlet weak var xpubsOutlet: UIButton!
    @IBOutlet var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanButton.layer.cornerRadius = 8
        seedWordsOutlet.layer.cornerRadius = 8
        xpubsOutlet.layer.cornerRadius = 8
        if (UIDevice.current.userInterfaceIdiom == .pad) {
          alertStyle = UIAlertController.Style.alert
        }
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
                                    if let _ = dict["blockheight"] as? Int {
                                        DispatchQueue.main.async { [unowned vc = self] in
                                            let alert = UIAlertController(title: "There is a valid Account Map QR image on your clipboard", message: "Would you like to upload this image as a Account Map QR?", preferredStyle: vc.alertStyle)
                                            alert.addAction(UIAlertAction(title: "Upload Account Map QR", style: .default, handler: { action in
                                                vc.processImport(importItem: qrCodeLink)
                                            }))
                                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                            alert.popoverPresentationController?.sourceView = self.view
                                            vc.present(alert, animated: true, completion: nil)
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
                                    if let _ = dict["blockheight"] as? Int {
                                        DispatchQueue.main.async { [unowned vc = self] in
                                            let alert = UIAlertController(title: "There is a valid Account Map text on your clipboard", message: "Would you like to upload this text as a Account Map QR?", preferredStyle: vc.alertStyle)
                                            alert.addAction(UIAlertAction(title: "Upload Account Map QR text", style: .default, handler: { action in
                                                vc.processImport(importItem: value)
                                            }))
                                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                            alert.popoverPresentationController?.sourceView = self.view
                                            vc.present(alert, animated: true, completion: nil)
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
    
    @IBAction func addXpubsManually(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToManualXpubRecovery", sender: vc)
        }        
    }
    
    @IBAction func getWordsAction(_ sender: Any) {
        getWords()
    }
    
    @IBAction func scanAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "scanRecovery", sender: vc)
        }
    }
    
    @IBAction func moreinfo(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "showInfo", sender: vc)
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
    
    private func processImport(importItem: String) {
        let cv = ConnectingView()
        cv.addConnectingView(vc: self, description: "processing...")
        if let data = importItem.data(using: .utf8) {
            do {
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                if let _ = dict["descriptor"] as? String {
                    if let _ = dict["blockheight"] as? Int {
                        /// It is an Account Map.
                        Import.importAccountMap(accountMap: dict) { walletDict in
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
                Import.importDescriptor(descriptor: importItem) { [unowned vc = self] walletDict in
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
            
        case "segueToManualXpubRecovery":
            if let vc = segue.destination as? AddExtendedKeyViewController {
                vc.isRecovering = true
            }
            
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
            }
            
        case "scanRecovery":
            if let vc = segue.destination as? ScannerViewController {
                vc.isRecovering = true
                vc.returnStringBlock = { [unowned thisVc = self] importItem in
                    thisVc.processImport(importItem: importItem)
                }
            }
            
        default:
            
            break
            
        }
        
    }

}
