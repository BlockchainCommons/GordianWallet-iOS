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
    var nativeSegwit = Bool()
    var p2shSegwit = Bool()
    var legacy = Bool()
    let connectingView = ConnectingView()
    var initialLoad = Bool()
    var wallet:WalletStruct!
    
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var addressOutlet: UILabel!
    @IBOutlet weak var createOutlet: UIButton!
    @IBOutlet var amountField: UITextField!
    @IBOutlet var labelField: UITextField!
    @IBOutlet weak var invoiceAddressHeader: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressOutlet.clipsToBounds = true
        addressOutlet.layer.cornerRadius = 8
        createOutlet.layer.cornerRadius = 8
        initialLoad = true
        addressOutlet.isUserInteractionEnabled = true
        addressOutlet.text = ""
        amountField.delegate = self
        labelField.delegate = self
        addressOutlet.alpha = 0
        invoiceAddressHeader.alpha = 0
        qrButton.alpha = 0
        shareButton.alpha = 0
        copyButton.alpha = 0
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        imageView.layer.magnificationFilter = .nearest
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        addDoneButtonOnKeyboard()
        
        NotificationCenter.default.addObserver(self, selector: #selector(clearInvoice), name: .didSwitchAccounts, object: nil)
        
        amountField.addTarget(self,
                              action: #selector(textFieldDidChange(_:)),
                              for: .editingChanged)
        
        labelField.addTarget(self,
                             action: #selector(textFieldDidChange(_:)),
                             for: .editingChanged)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getActiveWalletNow() { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                DispatchQueue.main.async {
                    vc.imageView.image = LifeHash.image(wallet!.descriptor)
                }
            }
        }
    }
    
    @objc func clearInvoice() {
        addressOutlet.alpha = 0
        invoiceAddressHeader.alpha = 0
        qrButton.alpha = 0
        copyButton.alpha = 0
        shareButton.alpha = 0
        createOutlet.alpha = 1
    }
    
    @IBAction func createNow(_ sender: Any) {
        
        load()
        
    }
    
    
    @IBAction func refresh(_ sender: Any) {
        
        self.load()
                
    }
    
    @objc func load() {
        
        connectingView.addConnectingView(vc: self, description: "fetching invoice address from your node")
        
        getActiveWalletNow() { [unowned vc = self] (wallet, error) in
            
            if !error && wallet != nil {
                
                vc.wallet = wallet!
                
                if !vc.initialLoad {
                    
                    DispatchQueue.main.async {
                        
                        UIView.animate(withDuration: 0.3, animations: {
                            
                            vc.addressOutlet.alpha = 0
                            
                        }) { (_) in
                            
                            vc.addressOutlet.text = ""
                            vc.addressOutlet.alpha = 1
                            vc.showAddress()
                            
                        }
                        
                    }
                    
                } else {
                    
                    vc.showAddress()
                    
                }
                
            } else if error {
                
                vc.connectingView.removeConnectingView()
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
                vc.addressString = address!
                vc.showAddress(address: address!)
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error getting musig address")
                
            }
            
        }
        
    }
    
    @IBAction func showQrAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "showInvoiceQr", sender: vc)
        }
    }
    
    
    @IBAction func copyAction(_ sender: Any) {
        copyAddress()
    }
    
    @IBAction func shareAddressAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            let textToShare = [vc.addressString]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = vc.view
            activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
            vc.present(activityViewController, animated: true) {}
            
        }
    }
    
    func showAddress(address: String) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.updateBIP21Invoice()
            vc.addressOutlet.adjustsFontSizeToFitWidth = true
            vc.view.addSubview(vc.addressOutlet)
            
            UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                
                vc.imageView.image = LifeHash.image(vc.wallet!.descriptor)
                vc.invoiceAddressHeader.alpha = 1
                vc.qrButton.alpha = 1
                vc.addressOutlet.alpha = 1
                vc.copyButton.alpha = 1
                vc.shareButton.alpha = 1
                
            }) { [unowned vc = self] _ in
                
                vc.addressOutlet.text = address
                
            }
            
        }
        
    }
    
    @objc func copyAddress() {
        DispatchQueue.main.async { [unowned vc = self] in
            let pasteboard = UIPasteboard.general
            pasteboard.string = vc.addressString
            displayAlert(viewController: vc, isError: false, message: "address copied to clipboard")
        }
    }
    
    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
        
        Reducer.makeCommand(walletName: wallet.name!, command: method, param: param) { [unowned vc = self] (object, errorDesc) in
                           
            if let address = object as? String {
                
                DispatchQueue.main.async {
                    
                    vc.connectingView.removeConnectingView()
                    vc.initialLoad = false
                    vc.addressString = address
                    vc.addressOutlet.text = address
                    vc.showAddress(address: address)
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                
            }
                                
        }
        
    }
    
    func updateBIP21Invoice() {
                
        if amountField.text == "" && labelField.text == "" {
            
            textToShareViaQRCode = "bitcoin:\(addressString)"
            
        } else if amountField.text != "" && labelField.text != "" {
            
            textToShareViaQRCode = "bitcoin:\(addressString)?amount=\(amountField.text!)&label=\(labelField.text!)"
            
        } else if amountField.text != "" && labelField.text == "" {
            
            textToShareViaQRCode = "bitcoin:\(addressString)?amount=\(amountField.text!)"
            
        } else if amountField.text == "" && labelField.text != "" {
            
            textToShareViaQRCode = "bitcoin:\(addressString)?label=\(labelField.text!)"
            
        }
        
    }
    
    @objc func doneButtonAction() {
        
        amountField.resignFirstResponder()
        
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
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        updateBIP21Invoice()
        
    }
    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segue.identifier
        switch id {
        case "showInvoiceQr":
            if let vc = segue.destination as? QRDisplayerViewController {
                vc.address = textToShareViaQRCode
            }
        default:
            break
        }
    }

}
