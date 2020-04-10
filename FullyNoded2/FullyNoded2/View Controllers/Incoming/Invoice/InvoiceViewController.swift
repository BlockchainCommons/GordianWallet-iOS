//
//  InvoiceViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class InvoiceViewController: UIViewController, UITextFieldDelegate {
    
    let spinner = UIActivityIndicatorView(style: .medium)
    var textToShareViaQRCode = String()
    var addressString = String()
    var qrView = UIImageView()
    var qrCode = UIImage()
    let descriptionLabel = UILabel()
    var tapQRGesture = UITapGestureRecognizer()
    var tapAddressGesture = UITapGestureRecognizer()
    var nativeSegwit = Bool()
    var p2shSegwit = Bool()
    var legacy = Bool()
    let connectingView = ConnectingView()
    let qrGenerator = QRGenerator()
    let copiedLabel = UILabel()
    var refreshButton = UIBarButtonItem()
    var dataRefresher = UIBarButtonItem()
    var initialLoad = Bool()
    var wallet:WalletStruct!
    var presentingModally = Bool()
    var addressOutlet = UILabel()
    
    @IBOutlet var closeButtonOutlet: UIButton!
    @IBOutlet var amountField: UITextField!
    @IBOutlet var labelField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        initialLoad = true
        addressOutlet.isUserInteractionEnabled = true
        addressOutlet.text = ""
        amountField.delegate = self
        labelField.delegate = self
        self.addressOutlet.alpha = 0
        configureCopiedLabel()
        
        amountField.addTarget(self,
                              action: #selector(textFieldDidChange(_:)),
                              for: .editingChanged)
        
        labelField.addTarget(self,
                             action: #selector(textFieldDidChange(_:)),
                             for: .editingChanged)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        addDoneButtonOnKeyboard()
        
        if presentingModally {
            
            closeButtonOutlet.alpha = 1
            
        } else {
            
            closeButtonOutlet.alpha = 0
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        load()
        
    }
    
    @IBAction func refresh(_ sender: Any) {
        
        self.load()
                
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
    func addNavBarSpinner() {
        
        spinner.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        dataRefresher = UIBarButtonItem(customView: spinner)
        navigationItem.setRightBarButton(dataRefresher, animated: true)
        spinner.startAnimating()
        spinner.alpha = 1
        
    }
    
    func removeLoader() {
        
        DispatchQueue.main.async {
            
            self.spinner.stopAnimating()
            self.spinner.alpha = 0
            
            self.refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                 target: self,
                                                 action: #selector(self.load))
            
            self.refreshButton.tintColor = UIColor.white.withAlphaComponent(1)
            
            self.navigationItem.setRightBarButton(self.refreshButton,
                                                  animated: true)
            
                        
        }
        
    }
    
    @objc func load() {
        
        connectingView.addConnectingView(vc: self, description: "fetching invoice address from your node")
        
        getActiveWalletNow() { [unowned vc = self] (wallet, error) in
            
            if !error && wallet != nil {
                
                vc.wallet = wallet!
                
                vc.addNavBarSpinner()
                
                if !vc.initialLoad {
                    
                    DispatchQueue.main.async {
                        
                        UIView.animate(withDuration: 0.3, animations: {
                            
                            vc.addressOutlet.alpha = 0
                            vc.qrView.alpha = 0
                            
                        }) { (_) in
                            
                            vc.addressOutlet.text = ""
                            vc.qrView.image = nil
                            vc.addressOutlet.alpha = 1
                            vc.qrView.alpha = 1
                            vc.showAddress()
                            
                        }
                        
                    }
                    
                } else {
                    
                    vc.showAddress()
                    
                }
                
            } else if error {
                
                vc.connectingView.removeConnectingView()
                vc.removeLoader()
                showAlert(vc: vc, title: "Error", message: "No active wallets")
                
            }
            
        }
        
    }
    
    func filterDerivation(str: DescriptorStruct) {
        print("derivation")
        
        if str.isP2PKH || str.isBIP44 || wallet.derivation.contains("44") {
            
            self.executeNodeCommand(method: .getnewaddress,
                                    param: "\"\", \"legacy\"")
            
        } else if str.isP2WPKH || str.isBIP84 || wallet.derivation.contains("84")  {
            
            self.executeNodeCommand(method: .getnewaddress,
                                    param: "\"\", \"bech32\"")
            
        } else if str.isP2SHP2WPKH || str.isBIP49 || wallet.derivation.contains("49")  {
            
            self.executeNodeCommand(method: .getnewaddress,
                                    param: "\"\", \"p2sh-segwit\"")
            
        }
        
    }
    
    func showAddress() {
        print("showAddress")
        
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet!.descriptor)
        
        if str.isMulti {
            
            self.getMsigAddress()
            
        } else {
            
            self.filterDerivation(str: str)
            
        }
        
    }
    
    func getMsigAddress() {
        print("getMsigAddress")
        
        KeyFetcher.musigAddress { [unowned vc = self] (address, error) in
            
            if !error {
                
                vc.connectingView.removeConnectingView()
                vc.removeLoader()
                vc.addressString = address!
                vc.showAddress(address: address!)
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error getting musig address")
                
            }
            
        }
        
    }
    
    func showAddress(address: String) {
        
        DispatchQueue.main.async {
            
            let pasteboard = UIPasteboard.general
            pasteboard.string = address
            
            self.qrCode = self.generateQrCode(key: address)
            self.qrView.image = self.qrCode
            self.qrView.isUserInteractionEnabled = true
            self.qrView.alpha = 0
            self.qrView.frame = CGRect(x: 32, y: self.amountField.frame.maxY + 20, width: self.view.frame.width - 64, height: self.view.frame.width - 64)
            self.view.addSubview(self.qrView)
            
            self.addressOutlet.frame = CGRect(x: 32, y: self.qrView.frame.maxY + 5, width: self.view.frame.width - 64, height: 20)
            self.addressOutlet.adjustsFontSizeToFitWidth = true
            self.addressOutlet.textAlignment = .center
            self.view.addSubview(self.addressOutlet)
            
            self.descriptionLabel.frame = CGRect(x: 10, y: self.tabBarController!.tabBar.frame.minY - 20, width: self.view.frame.width - 20, height: 20)
            
            self.descriptionLabel.textAlignment = .center
            
            self.descriptionLabel.font = UIFont.init(name: "HelveticaNeue-Light",
                                                size: 12)
            
            self.descriptionLabel.textColor = .lightGray
            self.descriptionLabel.text = "Tap the QR Code or text to copy/save/share"
            self.descriptionLabel.adjustsFontSizeToFitWidth = true
            self.descriptionLabel.alpha = 0
            self.view.addSubview(self.descriptionLabel)
            
            self.tapAddressGesture = UITapGestureRecognizer(target: self,
                                                       action: #selector(self.shareAddressText(_:)))
            
            self.addressOutlet.addGestureRecognizer(self.tapAddressGesture)
            
            self.tapQRGesture = UITapGestureRecognizer(target: self,
                                                  action: #selector(self.shareQRCode(_:)))
            
            self.qrView.addGestureRecognizer(self.tapQRGesture)
            
            UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                
                vc.descriptionLabel.alpha = 1
                vc.qrView.alpha = 1
                vc.addressOutlet.alpha = 1
                
            }) { [unowned vc = self] _ in
                
                vc.addressOutlet.text = address
                vc.addCopiedLabel()
                
            }
            
        }
        
    }
    
    func addCopiedLabel() {
        
        view.addSubview(copiedLabel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            
            UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                
                if vc.tabBarController != nil {
                    
                    vc.copiedLabel.frame = CGRect(x: 0,
                                                    y: vc.tabBarController!.tabBar.frame.minY - 50,
                                                    width: vc.view.frame.width,
                                                    height: 50)
                    
                }
                
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                
                UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                    
                    vc.copiedLabel.frame = CGRect(x: 0,
                                                    y: vc.view.frame.maxY + 100,
                                                    width: vc.view.frame.width,
                                                    height: 50)
                    
                }, completion: { [unowned vc = self] _ in
                    
                    vc.copiedLabel.removeFromSuperview()
                    
                })
                
            })
            
        }
        
    }
    
    @objc func shareAddressText(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
            
            vc.addressOutlet.alpha = 0
            
        }) { _ in
            
            UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                
                vc.addressOutlet.alpha = 1
                
            })
            
        }
        
        DispatchQueue.main.async {
            
            let textToShare = [self.addressString]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
            
            vc.qrView.alpha = 0
            
        }) { _ in
            
            UIView.animate(withDuration: 0.2, animations: { [unowned vc = self] in
                
                vc.qrView.alpha = 1
                
            }) { [unowned vc = self] _ in
                
                let activityController = UIActivityViewController(activityItems: [vc.qrView.image!],
                                                                  applicationActivities: nil)
                
                activityController.popoverPresentationController?.sourceView = vc.view
                vc.present(activityController, animated: true) {}
                
            }
            
        }
        
    }
    
    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
        
        Reducer.makeCommand(walletName: wallet.name!, command: method, param: param) { [unowned vc = self] (object, errorDesc) in
                           
            if let address = object as? String {
                
                DispatchQueue.main.async {
                    
                    vc.connectingView.removeConnectingView()
                    vc.initialLoad = false
                    vc.removeLoader()
                    vc.addressString = address
                    vc.addressOutlet.text = address
                    vc.showAddress(address: address)
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                vc.removeLoader()
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                
            }
                                
        }
        
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        updateQRImage()
        
    }
    
    func generateQrCode(key: String) -> UIImage {
        
        return qrGenerator.getQRCode(textInput: key)
        
    }
    
    func updateQRImage() {
        
        var newImage = UIImage()
        
        if self.amountField.text == "" && self.labelField.text == "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressString)")
            textToShareViaQRCode = "bitcoin:\(self.addressString)"
            
        } else if self.amountField.text != "" && self.labelField.text != "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressString)?amount=\(self.amountField.text!)&label=\(self.labelField.text!)")
            textToShareViaQRCode = "bitcoin:\(self.addressString)?amount=\(self.amountField.text!)&label=\(self.labelField.text!)"
            
        } else if self.amountField.text != "" && self.labelField.text == "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressString)?amount=\(self.amountField.text!)")
            textToShareViaQRCode = "bitcoin:\(self.addressString)?amount=\(self.amountField.text!)"
            
        } else if self.amountField.text == "" && self.labelField.text != "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressString)?label=\(self.labelField.text!)")
            textToShareViaQRCode = "bitcoin:\(self.addressString)?label=\(self.labelField.text!)"
            
        }
        
        DispatchQueue.main.async {
            
            UIView.transition(with: self.qrView,
                              duration: 0.75,
                              options: .transitionCrossDissolve,
                              animations: { self.qrView.image = newImage },
                              completion: nil)
            
        }
        
    }
    
    @objc func doneButtonAction() {
        
        self.amountField.resignFirstResponder()
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        view.endEditing(true)
        return false
        
    }
    
    func addDoneButtonOnKeyboard() {
        
        let doneToolbar = UIToolbar()
        
        doneToolbar.frame = CGRect(x: 0,
                                   y: 0,
                                   width: 320,
                                   height: 50)
        
        doneToolbar.barStyle = UIBarStyle.default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
                                        target: nil,
                                        action: nil)
        
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done",
                                                    style: UIBarButtonItem.Style.done,
                                                    target: self,
                                                    action: #selector(doneButtonAction))
        
        let items = NSMutableArray()
        items.add(flexSpace)
        items.add(done)
        
        doneToolbar.items = (items as! [UIBarButtonItem])
        doneToolbar.sizeToFit()
        
        self.amountField.inputAccessoryView = doneToolbar
        
    }
    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
        
    }
    
    func configureCopiedLabel() {
        
        copiedLabel.text = "copied to clipboard ✓"
        
        copiedLabel.frame = CGRect(x: 0,
                                   y: view.frame.maxY + 100,
                                   width: view.frame.width,
                                   height: 50)
        
        copiedLabel.textColor = UIColor.darkGray
        copiedLabel.font = UIFont.init(name: "HiraginoSans-W3", size: 17)
        copiedLabel.backgroundColor = UIColor.black
        copiedLabel.textAlignment = .center
        
    }

}
