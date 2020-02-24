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
    
    var onDoneBlock : ((Bool) -> Void)?
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
    
    @objc func showAlert() {
        
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Don't have a QuickConnect QR?", message: "We have a testnet node you can borrow for testing purposes only, just tap \"Add Testing Node\" to use it. This is a great way to get comfortable with the app and gain an idea of how it works.", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Add Testing Node", style: .default, handler: { action in
                
                self.addnode()

            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
            self.present(alert, animated: true, completion: nil)
            
        }
    
    }
    
    func addnode() {
        
        // Testnet Linode instance:
        let url = "btcstandup://StandUp:71e355f8e097857c932cc315f321eb4a@ftemeyifladknw3cpdhilomt7fhb3cquebzczjb7hslia77khc7cnwid.onion:1309/?label=Testing%20Node"
        addBtcRpcQr(url: url)
        
    }
    
    func configureScanner() {
        
        imageView.alpha = 0
        imageView.frame = view.frame
        imageView.isUserInteractionEnabled = true
        
        qrScanner.isScanningNode = true
        qrScanner.keepRunning = false
        qrScanner.vc = self
        qrScanner.imageView = imageView
        qrScanner.completion = { self.getQRCode() }
        qrScanner.didChooseImage = { self.didPickImage() }
        
        qrScanner.addTestingNodeButton.addTarget(self, action: #selector(showAlert), for: .touchUpInside)
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
    
    // MARK: WIP
    func signPSBT(psbt: String) {
        
//        let cd = CoreDataService()
//        cd.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
//            if errorDescription == nil && wallets != nil {
//                for w in wallets! {
//                    let wallet = WalletStruct(dictionary: w)
//                    let chain = network(path: wallet.derivation)
//                    print("chain = \(chain)")
//                    do {
//                        var localPSBT = try PSBT(psbt, chain)
//                        let inputs = localPSBT.inputs
//                        print("inputs.count = \(inputs.count)")
//                        for input in inputs {
//                            let origins = input.origins
//                            for origin in origins! {
//                                var path = origin.value.path
//                                print("path = \(path)")
//                                let s = (path.description).replacingOccurrences(of: "m/", with: "")
//                                path = BIP32Path(s)!
//                                print("path2 = \(path)")
//                                let encryptedSeed = wallet.seed
//                                if String(bytes: encryptedSeed, encoding: .utf8) != "no seed" {
//                                    let enc = Encryption()
//                                    enc.decryptData(dataToDecrypt: encryptedSeed) { (seed) in
//                                        if seed != nil {
//                                            if let words = String(data: seed!, encoding: .utf8) {
//                                                let mnenomicCreator = MnemonicCreator()
//                                                mnenomicCreator.convert(words: words) { (mnemonic, error) in
//                                                    if !error {
//                                                        if let masterKey = HDKey(mnemonic!.seedHex(""), network(path: wallet.derivation)) {
//                                                            if let walletPath = BIP32Path(wallet.derivation) {
//                                                                do {
//                                                                    let account = try masterKey.derive(walletPath)
//                                                                    print("account xpub = \(account.xpub)")
//
//                                                                    do {
//                                                                        let key = try account.derive(path)
//                                                                        //if input.canSign(account) {
//                                                                            if let privkey = key.privKey {
//                                                                                print("privkey = \(privkey.wif)")
//                                                                                let mk = masterKey.xpriv!
//                                                                                let hdkey = HDKey(mk)
//                                                                                localPSBT.sign(hdkey!)
//                                                                                print("psbt signed")
//                                                                                let final = localPSBT.finalize()
//                                                                                let complete = localPSBT.complete
//
//                                                                                if final {
//
//                                                                                    if complete {
//
//                                                                                        if let hex = localPSBT.transactionFinal?.description {
//
//                                                                                            print("complete: \(hex)")
//
//                                                                                        } else {
//
//                                                                                            print("incomplete")
//
//                                                                                        }
//
//                                                                                    }
//
//                                                                                }
//
//                                                                            }
////                                                                        } else {
////                                                                            print("can't sign with that key")
////                                                                        }
//                                                                    } catch {
//                                                                        print("error deriving key")
//                                                                    }
//                                                                } catch {
//                                                                    print("error deriving account")
//                                                                }
//                                                            }
//
//                                                        }
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    } catch {
//
//
//                    }
//
//                }
//
//            }
//
//        }
        
    }
    
    func addBtcRpcQr(url: String) {
        
        let qc = QuickConnect()
    
        func nodeAdded() {
            
            print("result")
            
            if !qc.errorBool {
                
                DispatchQueue.main.async {
                    
                    self.onDoneBlock!(true)
                    self.dismiss(animated: true, completion: nil)
                    
                }
                
            } else {
                
                //scanNow()
                
                displayAlert(viewController: self,
                             isError: true,
                             message: qc.errorDescription)
                
            }
            
        }
        
        func addnode() {
            
            qc.addNode(vc: self,
                       url: url,
                       completion: nodeAdded)
            
        }
        
        if url.hasPrefix("btcrpc://") || url.hasPrefix("btcstandup://") {
            
            addnode()
            
//        } else if let _ = Data(base64Encoded: url) {
//            
//            signPSBT(psbt: url)
            
        } else {
            
            
            displayAlert(viewController: self,
                         isError: true,
                         message: "That's not a compatible QR Code!")
            
        }
                
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        if id == "showPubkey" {
            
            if let vc = segue.destination as? AuthenticateViewController {
                
                vc.isadding = true
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
