//
//  ScannerViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit
import LibWally

class ScannerViewController: UIViewController, UINavigationControllerDelegate {
    
    var isImporting = Bool()
    var unsignedPsbt = ""
    var signedRawTx = ""
    var updatingNode = Bool()
    var nodeId:UUID!
    var words = ""
    var scanningNode = Bool()
    var isRecovering = Bool()
    var closeButton = UIButton()
    var onDoneRecoveringBlock : (([String:Any]) -> Void)?
    var onDoneBlock : ((Bool) -> Void)?
    var onImportDoneBlock : ((String) -> Void)?
    let qrScanner = QRScanner()
    var isTorchOn = Bool()
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let connectingView = ConnectingView()
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        configureScanner()
        scanNow()
        
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
                
                if qrCodeLink.hasPrefix("btcrpc://") || qrCodeLink.hasPrefix("btcstandup://") {
                
                DispatchQueue.main.async { [unowned vc = self] in
                                
                    let alert = UIAlertController(title: "There is a QuickConnect uri on your clipboard", message: "Would you like to add this node?", preferredStyle: .actionSheet)

                    alert.addAction(UIAlertAction(title: "Add Node", style: .default, handler: { action in
                        
                        vc.addBtcRpcQr(url: qrCodeLink)
                        
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    alert.popoverPresentationController?.sourceView = self.view
                    vc.present(alert, animated: true, completion: nil)
                    
                    }
                    
                }
                
            }
            
        } else if UIPasteboard.general.hasStrings {
            
            if let value = UIPasteboard.general.string {
                
                if value.hasPrefix("btcrpc://") || value.hasPrefix("btcstandup://") {
                    
                    DispatchQueue.main.async { [unowned vc = self] in
                                    
                        let alert = UIAlertController(title: "There is a QuickConnect uri on your clipboard", message: "Would you like to add this node?", preferredStyle: .actionSheet)

                        alert.addAction(UIAlertAction(title: "Add Node", style: .default, handler: { action in
                            
                            vc.addBtcRpcQr(url: value)
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        alert.popoverPresentationController?.sourceView = self.view
                        vc.present(alert, animated: true, completion: nil)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    @objc func addTester() {
        
        if scanningNode {
            
            DispatchQueue.main.async {
                
                let alert = UIAlertController(title: "Don't have a QuickConnect QR?", message: "We have a testnet node you can borrow for testing purposes only, just tap \"Add Testing Node\" to use it. This is a great way to get comfortable with the app and gain an idea of how it works.", preferredStyle: .actionSheet)

                alert.addAction(UIAlertAction(title: "Add Testing Node", style: .default, handler: { action in
                    
                    self.addnode()

                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        
                alert.popoverPresentationController?.sourceView = self.view
                self.present(alert, animated: true, completion: nil)
                
            }
            
        } else if isRecovering {
            
            let url = URL(string: "https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Recovery.md")!
            UIApplication.shared.open(url) { (Bool) in }
            
        }
    
    }
    
    func addnode() {
        
        // Testnet Linode instance:
        let url = "btcstandup://StandUp:71e355f8e097857c932cc315f321eb4a@ftemeyifladknw3cpdhilomt7fhb3cquebzczjb7hslia77khc7cnwid.onion:1309/?label=BlockchainCommons%20Testing%20Node"
        addBtcRpcQr(url: url)
        
    }
    
    func configureScanner() {
        
        imageView.alpha = 0
        imageView.frame = view.frame
        imageView.isUserInteractionEnabled = true
        
        qrScanner.isScanningNode = scanningNode
        qrScanner.scanningRecovery = isRecovering
        qrScanner.isImporting = isImporting
        qrScanner.keepRunning = false
        qrScanner.vc = self
        qrScanner.imageView = imageView
        qrScanner.completion = { self.getQRCode() }
        qrScanner.didChooseImage = { self.didPickImage() }
        
        qrScanner.addTestingNodeButton.addTarget(self, action: #selector(addTester), for: .touchUpInside)
        qrScanner.torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
        qrScanner.uploadButton.addTarget(self, action: #selector(chooseQRCodeFromLibrary), for: .touchUpInside)
        
        isTorchOn = false
        
    }
    
    func addScannerButtons() {
        
        self.addBlurView(frame: CGRect(x: self.imageView.frame.maxX - 80,
                                       y: self.imageView.frame.maxY - 120,
                                       width: 70,
                                       height: 70), button: self.qrScanner.uploadButton)
        
        self.addBlurView(frame: CGRect(x: 10,
                                       y: self.imageView.frame.maxY - 120,
                                       width: 70,
                                       height: 70), button: self.qrScanner.torchButton)
        
    }
    
    func didPickImage() {
        
        let qrString = qrScanner.qrString
        addBtcRpcQr(url: qrString)
        
    }
    
    @objc func chooseQRCodeFromLibrary() {
        
        qrScanner.chooseQRCodeFromLibrary()
        
    }
    
    func addBlurView(frame: CGRect, button: UIButton) {
        
        button.removeFromSuperview()
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
        blur.frame = frame
        blur.clipsToBounds = true
        blur.layer.cornerRadius = frame.width / 2
        blur.contentView.addSubview(button)
        self.imageView.addSubview(blur)
        
    }
    
    @objc func close() {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    func scanNow() {
        print("scanNow")
        
        DispatchQueue.main.async {
            
            self.qrScanner.scanQRCode()
            self.addScannerButtons()
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.imageView.alpha = 1
                
            })
            
        }
        
    }
    
    func getQRCode() {
        
        let btcstandupURI = qrScanner.stringToReturn
        addBtcRpcQr(url: btcstandupURI)
        
    }
    
    @objc func toggleTorch() {
        
        if isTorchOn {
            
            qrScanner.toggleTorch(on: false)
            isTorchOn = false
            
        } else {
            
            qrScanner.toggleTorch(on: true)
            isTorchOn = true
            
        }
        
    }
    
    func signPSBT(psbt: String) {
        
        PSBTSigner.sign(psbt: psbt) { [unowned vc = self] (success, psbt, rawTx) in
            
            if success {
                
                if psbt != nil {
                    vc.connectingView.removeConnectingView()
                    vc.unsignedPsbt = psbt!
                    
                } else if rawTx != nil {
                    vc.connectingView.removeConnectingView()
                    vc.signedRawTx = rawTx!
                    
                }
                
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.performSegue(withIdentifier: "goConfirmPsbt", sender: vc)
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "PSBT signing failed")
            }
            
        }
        
    }
    
    func addBtcRpcQr(url: String) {
        
        func addnode() {
            
            let qc = QuickConnect()
            qc.addNode(vc: self, url: url) { (success, errorDesc) in
                
                if success {
                    
                    DispatchQueue.main.async {
                        
                        self.onDoneBlock!(true)
                        self.dismiss(animated: true, completion: nil)
                        
                    }
                    
                } else {
                    
                    showAlert(vc: self, title: "Error", message: "Error adding node: \(errorDesc ?? "unknown error")")
                    
                }
                
            }
            
        }
        
        func updateNode() {
            
            let qc = QuickConnect()
            qc.nodeToUpdate = self.nodeId
            qc.addNode(vc: self, url: url) { (success, errorDesc) in
                
                if success {
                    
                    DispatchQueue.main.async {
                        
                        self.onDoneBlock!(true)
                        self.dismiss(animated: true, completion: nil)
                        
                    }
                    
                } else {
                    
                    showAlert(vc: self, title: "Error", message: "Error adding node: \(errorDesc ?? "unknown error")")
                    
                }
                
            }
            
        }
        
        if isImporting {
            
            dismiss(animated: true) { [unowned vc = self] in
                
                vc.onImportDoneBlock!(url)
                
            }
            
        } else {
            
            if url.hasPrefix("btcrpc://") || url.hasPrefix("btcstandup://") {
                
                if !updatingNode {
                    
                    addnode()
                    
                } else {
                    
                    updateNode()
                    
                }
                
            } else if let _ = Data(base64Encoded: url) {
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    let alert = UIAlertController(title: "Sign PSBT?", message: "We will attempt to sign this psbt with your nodes current active wallet and then we will attempt to sing it locally. If the psbt is complete it will be returned to you as a raw transaction for broadcasting, if it is incomplete you will be able to export it to another signer.", preferredStyle: .actionSheet)

                    alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { action in
                        
                        vc.connectingView.addConnectingView(vc: vc, description: "signing psbt")
                        vc.signPSBT(psbt: url)

                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                            
                    alert.popoverPresentationController?.sourceView = vc.view
                    vc.present(alert, animated: true, completion: nil)
                    
                }
                                
            } else if let data = url.data(using: .utf8) {
                
                func invalidAlert() {
                    
                    showAlert(vc: self, title: "Error", message: "Invalid Recovery QR")
                    
                }
                
                Encryption.getNode { (node, error) in
                    
                    if !error && node != nil {
                        
                        do {
                            
                            let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                            
                            if let _ = dict["descriptor"] as? String {
                                
                                if let _ = dict["birthdate"] as? Int32 {
                                    
                                    if let _ = dict["entropy"] as? String {
                                        
                                        if let _ = dict["blockheight"] as? Int {
                                            
                                            /// we know we are coming from wallet recovery view controller
                                            if self.isRecovering {
                                                
                                                DispatchQueue.main.async {
                                                    
                                                    self.connectingView.removeConnectingView()
                                                    self.onDoneRecoveringBlock!(dict)
                                                    self.dismiss(animated: true, completion: nil)
                                                    
                                                }
                                                
                                            } else {
                                                
                                                // we can recover the wallet now
                                                self.connectingView.addConnectingView(vc: self, description: "recovering your wallet")
                                                let recovery = RecoverWallet.sharedInstance
                                                recovery.recover(node: node!, json: dict, words: self.words, derivation: nil) { (success, error) in
                                                    
                                                    if success {
                                                        
                                                        self.connectingView.removeConnectingView()
                                                        showAlert(vc: self, title: "Success!", message: "Wallet recovered 🤩\n\nGo to wallets to activate it.")
                                                        
                                                    } else {
                                                        
                                                        self.connectingView.removeConnectingView()
                                                        
                                                        if error != nil {
                                                            
                                                            showAlert(vc: self, title: "Error!", message: "Wallet recovery error: \(error!)")
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        invalidAlert()
                                        
                                    }
                                    
                                } else {
                                    
                                    invalidAlert()
                                    
                                }
                                
                            } else {
                                
                                invalidAlert()
                                
                            }
                            
                        } catch let error as NSError {
                            
                            displayAlert(viewController: self,
                                         isError: true,
                                         message: error.localizedDescription)
                            
                        }
                        
                    } else {
                        
                        self.connectingView.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: "wallet recovery is not possible if there are no active nodes")
                        
                    }
                    
                }
                            
            } else {
                
                displayAlert(viewController: self, isError: true, message: "That's not a compatible QR Code!")
                
            }
            
        }
                
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        if id == "goConfirmPsbt" {
            
            if let vc = segue.destination as? ConfirmViewController {
                
                vc.unsignedPsbt = self.unsignedPsbt
                vc.signedRawTx = self.signedRawTx
            }
            
        }
        
    }

}

extension String {
//: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }

//: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
