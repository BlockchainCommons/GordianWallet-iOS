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
    
    var scanningShards = Bool()
    var isScanningInvoice = Bool()
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
    var returnStringBlock: ((String) -> Void)?
    //var onImportDoneBlock : ((String) -> Void)?
    let qrScanner = QRScanner()
    var isTorchOn = Bool()
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let connectingView = ConnectingView()
    var alertStyle = UIAlertController.Style.actionSheet
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        configureScanner()
        scanNow()
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
                
                if qrCodeLink.hasPrefix("btcrpc://") || qrCodeLink.hasPrefix("btcstandup://") {
                
                DispatchQueue.main.async { [unowned vc = self] in
                                
                    let alert = UIAlertController(title: "There is a QuickConnect uri on your clipboard", message: "Would you like to add this node?", preferredStyle: vc.alertStyle)

                    alert.addAction(UIAlertAction(title: "Add Node", style: .default, handler: { action in
                        
                        vc.processQRString(url: qrCodeLink)
                        
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
                                    
                        let alert = UIAlertController(title: "There is a QuickConnect uri on your clipboard", message: "Would you like to add this node?", preferredStyle: vc.alertStyle)

                        alert.addAction(UIAlertAction(title: "Add Node", style: .default, handler: { action in
                            
                            vc.processQRString(url: value)
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        alert.popoverPresentationController?.sourceView = self.view
                        vc.present(alert, animated: true, completion: nil)
                        
                    }
                    
                } else if value.hasPrefix("01") || value.hasPrefix("02") {
                    connectingView.addConnectingView(vc: self, description: "converting to psbt")
                    Reducer.makeCommand(walletName: "", command: .converttopsbt, param: "\"\(value)\"") { (object, errorDescription) in
                        if let psbt = object as? String {
                            DispatchQueue.main.async { [unowned vc = self] in
                                vc.connectingView.removeConnectingView()
                                let alert = UIAlertController(title: "Sign Raw Transaction?", message: "We will attempt to sign this transaction with your nodes current active wallet and then we will attempt to sign it locally. If the transaction is complete it will be returned to you as a raw transaction for broadcasting, if it is incomplete you will be able to export it to another signer as a psbt.", preferredStyle: vc.alertStyle)
                                alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { action in
                                    vc.connectingView.addConnectingView(vc: vc, description: "signing psbt")
                                    vc.signPSBT(psbt: psbt)
                                }))
                                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                                    vc.connectingView.removeConnectingView()
                                }))
                                alert.popoverPresentationController?.sourceView = vc.view
                                vc.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func addTester() {
        
        if scanningNode {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                let alert = UIAlertController(title: "Connect to our testing node?", message: "We have a testnet node you can borrow for testing purposes only, just tap \"Add Testing Node\" to use it. This is a great way to get comfortable with the app and gain an idea of how it works.", preferredStyle: vc.alertStyle)

                alert.addAction(UIAlertAction(title: "Add Testing Node", style: .default, handler: { [unowned vc = self] action in
                    
                    vc.addnode()

                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        
                alert.popoverPresentationController?.sourceView = vc.view
                vc.present(alert, animated: true, completion: nil)
                
            }
            
        } else if isRecovering {
            
            let url = URL(string: "https://github.com/BlockchainCommons/GordianWallet-iOS/blob/master/Recovery.md")!
            UIApplication.shared.open(url) { (Bool) in }
            
        }
    
    }
    
    func addnode() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            let alert = UIAlertController(title: "Warning", message: "We may periodically delete testnet wallets from our testing node. Please make sure you save your recovery info when creating wallets so you can easily recover.", preferredStyle: vc.alertStyle)

            alert.addAction(UIAlertAction(title: "Add Testing Node", style: .default, handler: { [unowned vc = self] action in
                
                // Testnet Linode instance:
                let url = "btcstandup://StandUp:71e355f8e097857c932cc315f321eb4a@ftemeyifladknw3cpdhilomt7fhb3cquebzczjb7hslia77khc7cnwid.onion:1309/?label=BC%20Beta%20Test%20Node"
                vc.processQRString(url: url)

            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    func configureScanner() {
        
        imageView.alpha = 0
        imageView.frame = view.frame
        imageView.isUserInteractionEnabled = true
        
        qrScanner.scanningShards = scanningShards
        qrScanner.scanningBip21 = isScanningInvoice
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
        
        self.addBlurView(frame: CGRect(x: self.view.frame.maxX - 80,
                                       y: self.view.frame.maxY - 140,
                                       width: 70,
                                       height: 70), button: self.qrScanner.uploadButton)
        
        self.addBlurView(frame: CGRect(x: 10,
                                       y: self.view.frame.maxY - 140,
                                       width: 70,
                                       height: 70), button: self.qrScanner.torchButton)
        
    }
    
    func didPickImage() {
        
        let qrString = qrScanner.qrString
        processQRString(url: qrString)
        
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
        processQRString(url: btcstandupURI)
        
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
    
    func processQRString(url: String) {
        
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
        
        if scanningShards || isScanningInvoice || isImporting {
            if navigationController != nil {
                self.returnStringBlock!(url)
                navigationController?.popViewController(animated: true)
            } else {
                dismiss(animated: true) { [weak self] in
                    self?.returnStringBlock!(url)
                }
            }
            
        } else if isRecovering {
            returnStringBlock!(url)
            navigationController?.popViewController(animated: true)
            
        } else {
            if url.hasPrefix("btcrpc://") || url.hasPrefix("btcstandup://") {
                if !updatingNode {
                    addnode()
                } else {
                    updateNode()
                }
                
            } else if let _ = Data(base64Encoded: url) {
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    let alert = UIAlertController(title: "Sign PSBT?", message: "We will attempt to sign this psbt with your nodes current active wallet and then we will attempt to sign it locally. If the psbt is complete it will be returned to you as a raw transaction for broadcasting, if it is incomplete you will be able to export it to another signer.", preferredStyle: vc.alertStyle)

                    alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { action in
                        
                        vc.connectingView.addConnectingView(vc: vc, description: "signing psbt")
                        vc.signPSBT(psbt: url)

                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                            
                    alert.popoverPresentationController?.sourceView = vc.view
                    vc.present(alert, animated: true, completion: nil)
                    
                }
                            
            } else if url.hasPrefix("01") || url.hasPrefix("02") {
                connectingView.addConnectingView(vc: self, description: "converting to psbt")
                Reducer.makeCommand(walletName: "", command: .converttopsbt, param: "\"\(url)\"") { (object, errorDescription) in
                    if let psbt = object as? String {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.connectingView.removeConnectingView()
                            let alert = UIAlertController(title: "Sign Raw Transaction?", message: "We will attempt to sign this transaction with your nodes current active wallet and then we will attempt to sign it locally. If the transaction is complete it will be returned to you as a raw transaction for broadcasting, if it is incomplete you will be able to export it to another signer as a psbt.", preferredStyle: vc.alertStyle)
                            alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { action in
                                vc.connectingView.addConnectingView(vc: vc, description: "signing psbt")
                                vc.signPSBT(psbt: psbt)
                            }))
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                                vc.connectingView.removeConnectingView()
                            }))
                            alert.popoverPresentationController?.sourceView = vc.view
                            vc.present(alert, animated: true, completion: nil)
                        }
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
