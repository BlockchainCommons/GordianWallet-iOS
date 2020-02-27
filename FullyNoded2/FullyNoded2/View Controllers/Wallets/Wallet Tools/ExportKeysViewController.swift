//
//  ExportKeysViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 27/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally
import AuthenticationServices

class ExportKeysViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var section = Int()
    var showQr = Bool()
    var copyText = Bool()
    let authView = UIView()
    var fetchingAddresses = Bool()
    var qrString = ""
    var keys = [[String:String]]()
    var wallet:WalletStruct!
    var connectingView = ConnectingView()
    @IBOutlet var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self
        getWords()
        connectingView.addConnectingView(vc: self, description: "fetching your keys")
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return keys.count
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    private func singleSigCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = table.dequeueReusableCell(withIdentifier: "exportCell", for: indexPath)
        cell.selectionStyle = .none
        
        let addressView = cell.viewWithTag(1)!
        let publicKeyView = cell.viewWithTag(5)!
        let wifView = cell.viewWithTag(9)!
        
        addressView.layer.cornerRadius = 8
        publicKeyView.layer.cornerRadius = 8
        wifView.layer.cornerRadius = 8
        
        let addressLabel = cell.viewWithTag(2) as! UILabel
        let publicKeyLabel = cell.viewWithTag(6) as! UILabel
        let wifLabel = cell.viewWithTag(10) as! UILabel
        
        addressLabel.adjustsFontSizeToFitWidth = true
        publicKeyLabel.adjustsFontSizeToFitWidth = true
        wifLabel.adjustsFontSizeToFitWidth = true
        
        let showAddressQRButton = cell.viewWithTag(3) as! UIButton
        let copyAddressButton = cell.viewWithTag(4) as! UIButton
        let showPublicKeyQRButton = cell.viewWithTag(7) as! UIButton
        let copyPublicKeyButton = cell.viewWithTag(8) as! UIButton
        let showWifQRButton = cell.viewWithTag(11) as! UIButton
        let copyWifButton = cell.viewWithTag(12) as! UIButton
        
        showAddressQRButton.accessibilityLabel = "\(indexPath.section)"
        copyAddressButton.accessibilityLabel = "\(indexPath.section)"
        showPublicKeyQRButton.accessibilityLabel = "\(indexPath.section)"
        copyPublicKeyButton.accessibilityLabel = "\(indexPath.section)"
        showWifQRButton.accessibilityLabel = "\(indexPath.section)"
        copyWifButton.accessibilityLabel = "\(indexPath.section)"
        
        showAddressQRButton.addTarget(self, action: #selector(addressQR(_:)), for: .touchUpInside)
        copyAddressButton.addTarget(self, action: #selector(copyAddress(_:)), for: .touchUpInside)
        showPublicKeyQRButton.addTarget(self, action: #selector(publicKeyQR(_:)), for: .touchUpInside)
        copyPublicKeyButton.addTarget(self, action: #selector(copyPublicKey(_:)), for: .touchUpInside)
        showWifQRButton.addTarget(self, action: #selector(wifQR(_:)), for: .touchUpInside)
        copyWifButton.addTarget(self, action: #selector(copyWif(_:)), for: .touchUpInside)
        
        addressLabel.text = keys[indexPath.section]["address"]
        publicKeyLabel.text = keys[indexPath.section]["publicKey"]
        wifLabel.text = "*********************************************************"
        
        return cell
        
    }
    
    private func multiSigCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = table.dequeueReusableCell(withIdentifier: "exportMultiSigCell", for: indexPath)
        cell.selectionStyle = .none
        
        let addressView = cell.viewWithTag(1)!
        let pubkeysView = cell.viewWithTag(2)!
        let scriptPubKeyView = cell.viewWithTag(3)!
        let wifView = cell.viewWithTag(4)!
        
        addressView.layer.cornerRadius = 8
        pubkeysView.layer.cornerRadius = 8
        scriptPubKeyView.layer.cornerRadius = 8
        wifView.layer.cornerRadius = 8
        
        let addressLabel = cell.viewWithTag(5) as! UILabel
        addressLabel.adjustsFontSizeToFitWidth = true
        addressLabel.text = keys[indexPath.section]["address"]
        
        let pubkeysTextView = cell.viewWithTag(6) as! UITextView
        pubkeysTextView.text = keys[indexPath.section]["publicKey"]
        pubkeysTextView.isEditable = false
        pubkeysTextView.isSelectable = true
        
        let scriptPubKeyTextView = cell.viewWithTag(7) as! UITextView
        scriptPubKeyTextView.text = keys[indexPath.section]["scriptPubKey"]
        scriptPubKeyTextView.isEditable = false
        scriptPubKeyTextView.isSelectable = true
        
        let wifLabel = cell.viewWithTag(8) as! UILabel
        if keys[indexPath.section]["wif"] != nil {
            if keys[indexPath.section]["wif"] != "" {
                wifLabel.text = "**********************************************************"
            } else {
                wifLabel.text = "No private keys on device"
            }
        } else {
            wifLabel.text = "No private keys on device"
        }
        
        let addressQRButton = cell.viewWithTag(9) as! UIButton
        let addressCopyButton = cell.viewWithTag(10) as! UIButton
        let publicKeysQRButton = cell.viewWithTag(11) as! UIButton
        let publicKeysCopyButton = cell.viewWithTag(12) as! UIButton
        let scriptPubKeyQRButton = cell.viewWithTag(13) as! UIButton
        let scriptPubKeyCopyButton = cell.viewWithTag(14) as! UIButton
        let wifQRButton = cell.viewWithTag(15) as! UIButton
        let wifCopyButton = cell.viewWithTag(16) as! UIButton
        
        addressQRButton.accessibilityLabel = "\(indexPath.section)"
        addressCopyButton.accessibilityLabel = "\(indexPath.section)"
        publicKeysCopyButton.accessibilityLabel = "\(indexPath.section)"
        publicKeysQRButton.accessibilityLabel = "\(indexPath.section)"
        scriptPubKeyCopyButton.accessibilityLabel = "\(indexPath.section)"
        scriptPubKeyQRButton.accessibilityLabel = "\(indexPath.section)"
        wifQRButton.accessibilityLabel = "\(indexPath.section)"
        wifCopyButton.accessibilityLabel = "\(indexPath.section)"
        
        wifQRButton.addTarget(self, action: #selector(wifQR(_:)), for: .touchUpInside)
        wifCopyButton.addTarget(self, action: #selector(copyWif(_:)), for: .touchUpInside)
        
        publicKeysQRButton.addTarget(self, action: #selector(publicKeyQR(_:)), for: .touchUpInside)
        publicKeysCopyButton.addTarget(self, action: #selector(copyPublicKey(_:)), for: .touchUpInside)
        
        scriptPubKeyQRButton.addTarget(self, action: #selector(scriptPubKeyQR(_:)), for: .touchUpInside)
        scriptPubKeyCopyButton.addTarget(self, action: #selector(copyScriptPubKey(_:)), for: .touchUpInside)
        
        addressQRButton.addTarget(self, action: #selector(addressQR(_:)), for: .touchUpInside)
        addressCopyButton.addTarget(self, action: #selector(copyAddress(_:)), for: .touchUpInside)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let p = DescriptorParser()
        let s = p.descriptor(wallet.descriptor)
        
        if !s.isMulti {
            
            return singleSigCell(indexPath)
            
        } else {
            
            return multiSigCell(indexPath)
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let p = DescriptorParser()
        let s = p.descriptor(wallet.descriptor)
        
        if !s.isMulti {
            
            return 224
            
        } else {
            
            return 375
            
        }
                
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "\(wallet.derivation)/0/\(section)"
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
        (view as! UITableViewHeaderFooterView).textLabel?.alpha = 1
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
    @objc func copyAddress(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        let index = Int(sender.accessibilityLabel!)!
        let address = keys[index]["address"]!
        UIPasteboard.general.string = address
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            
            UIPasteboard.general.string = ""
            
        }
        
        displayAlert(viewController: self, isError: false, message: "address copied to clipboard for 60 seconds")
        
    }
    
    @objc func addressQR(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        let index = Int(sender.accessibilityLabel!)!
        qrString = keys[index]["address"] ?? "no address"
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "exportKeys", sender: self)
            
        }
        
    }
    
    @objc func copyScriptPubKey(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        let index = Int(sender.accessibilityLabel!)!
        
        if keys[index]["scriptPubKey"] != nil {
            
            let publicKey = keys[index]["scriptPubKey"]
            UIPasteboard.general.string = publicKey
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                
                UIPasteboard.general.string = ""
                
            }
            
            displayAlert(viewController: self, isError: false, message: "public key copied to clipboard for 60 seconds")
        }
        
    }
    
    @objc func scriptPubKeyQR(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        let index = Int(sender.accessibilityLabel!)!
        
        qrString = keys[index]["scriptPubKey"] ?? "no scriptPubKey to display"
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "exportKeys", sender: self)
            
        }
        
    }
    
    @objc func copyPublicKey(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        let index = Int(sender.accessibilityLabel!)!
        
        if keys[index]["publicKey"] != nil {
            
            let publicKey = keys[index]["publicKey"]
            UIPasteboard.general.string = publicKey
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                
                UIPasteboard.general.string = ""
                
            }
            
            displayAlert(viewController: self, isError: false, message: "public key copied to clipboard for 60 seconds")
        }
        
    }
    
    @objc func publicKeyQR(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        let index = Int(sender.accessibilityLabel!)!
        
        qrString = keys[index]["publicKey"] ?? "no public key to display"
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "exportKeys", sender: self)
            
        }
        
    }
    
    @objc func copyWif(_ sender: UIButton) {
        
        self.copyText = true
        self.section = Int(sender.accessibilityLabel!)!
        showAuth()
        
    }
    
    @objc func wifQR(_ sender: UIButton) {
        
        self.showQr = true
        self.section = Int(sender.accessibilityLabel!)!
        showAuth()
        
    }
    
    func getMultiSigKeys(words: String) {
        
        let parser = DescriptorParser()
        let s = parser.descriptor(wallet.descriptor)
        let keys = s.multiSigKeys
        let paths = s.multiSigPaths
        let sigsRequired = s.sigsRequired
        var failed = false
        var getKeysFromNode = false
        
        func getPrivKeys() {
            let mnemonicCreator = MnemonicCreator()
            mnemonicCreator.convert(words: words) { (mnemonic, error) in
                if !error {
                    let derivation = self.wallet.derivation
                    for i in 0 ... 999 {
                        let path = derivation + "/" + "\(i)"
                        if let bip32path = BIP32Path(path) {
                            if let key = HDKey((mnemonic!.seedHex("")), network(path: derivation)) {
                                do {
                                    let childKey = try key.derive(bip32path)
                                    if let privKey = childKey.privKey {
                                        if self.keys.count > 0 {
                                            self.keys[i]["wif"] = privKey.wif
                                        }
                                    }
                                } catch {
                                    print("failed getting a key")
                                }
                            }
                        }
                        if i == 999 {
                            DispatchQueue.main.async {
                                self.table.reloadData()
                                self.connectingView.removeConnectingView()
                            }
                        }
                    }
                }
            }
        }
        
        for i in 0 ... 999 {
            var pubkeys = [PubKey]()
            var pubkeyStrings = [String]()
            for (k, key) in keys.enumerated() {
                let hdKey = HDKey(key)
                let path = paths[k] + "/" + "\(i)"
                do {
                    if let bip32path = BIP32Path(path) {
                        let key = try hdKey?.derive(bip32path)
                        if key != nil {
                            pubkeys.append(key!.pubKey)
                            pubkeyStrings.append("#\(k + 1): \(key!.pubKey.data.hexString)")
                            if k + 1 == keys.count {
                                let scriptPubKey = ScriptPubKey(multisig: pubkeys, threshold: sigsRequired, bip67: false)
                                var multiSigAddress:Address!
                                var processedPubkeys = "\(pubkeyStrings)".replacingOccurrences(of: "[", with: "")
                                processedPubkeys = processedPubkeys.replacingOccurrences(of: "]", with: "")
                                processedPubkeys = processedPubkeys.replacingOccurrences(of: "\"", with: "")
                                processedPubkeys = processedPubkeys.replacingOccurrences(of: ",", with: "\n")
                                // LibWally only produces bech32 multisig addresses, so need to fetch other formats from the node
                                if wallet.derivation.contains("84") || s.isBIP84 || s.isP2WPKH {
                                    multiSigAddress = Address(scriptPubKey, network(path: wallet.derivation))
                                    self.keys.append(["address":"\(String(describing: multiSigAddress!))", "publicKey":"\(processedPubkeys)", "scriptPubKey":"\(scriptPubKey)"])
                                } else {
                                    self.keys.append(["address":"fetching addresses from your node...", "publicKey":"\(processedPubkeys)", "scriptPubKey":"\(scriptPubKey)"])
                                    getKeysFromNode = true
                                }
                                pubkeys.removeAll()
                                
                            }
                        }
                    }
                } catch {
                    print("key derivation failed")
                    failed = true
                }
            }
            
            if i == 999 {
                if !failed {
                    getPrivKeys()
                } else {
                    self.connectingView.removeConnectingView()
                    displayAlert(viewController: self, isError: true, message: "key derivation failed")
                }
                if getKeysFromNode {
                    self.getKeysFromBitcoinCore()
                }
            }
            
        }
        
    }
    
    func getKeysFromBitcoinCore() {
       
       let reducer = Reducer()
       let param = "\"\(wallet.descriptor)\", ''[0,999]''"
       reducer.makeCommand(walletName: "", command: .deriveaddresses, param: param) {
            if !reducer.errorBool {
               let result = reducer.arrayToReturn
               for (i, address) in result.enumerated() {
                   if self.keys.count > 0 {
                       self.keys[i]["address"] = (address as! String)
                   }
                   if i + 1 == result.count {
                       DispatchQueue.main.async {
                           self.table.reloadData()
                       }
                   }
               }
            } else {
                displayAlert(viewController: self, isError: true, message: "error getting addresses from your node")
            }
        }
        
    }
    
    func getWords() {
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                let enc = Encryption()
                self.wallet = wallet!
                let parser = DescriptorParser()
                let s = parser.descriptor(wallet!.descriptor)
                
                if String(data: wallet!.seed, encoding: .utf8) != "no seed" {
                 
                    enc.decryptData(dataToDecrypt: wallet!.seed) { (decryptedSeed) in
                        
                        if decryptedSeed != nil {
                            
                            if let words = String(bytes: decryptedSeed!, encoding: .utf8) {
                                
                                if s.isMulti {
                                    
                                    self.getMultiSigKeys(words: words)
                                    
                                } else {
                                    
                                    self.getSingleSigKeys(words: words)
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else if wallet?.xprv != nil {
                    
                    enc.decryptData(dataToDecrypt: wallet!.xprv!) { (decryptedXprv) in
                    
                        if decryptedXprv != nil {
                            
                            if let xprvString = String(data: decryptedXprv!, encoding: .utf8) {
                                
                                if let xprv = HDKey(xprvString) {
                                    
                                    if s.isMulti {
                                        
                                        self.fetchMultiSigKeysFromXprv(xprv: xprv)
                                        
                                    } else {
                                        
                                        self.fetchKeysFromXprv(xprv: xprv)
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }

    func getSingleSigKeys(words: String) {
        
        let mnemonicCreator = MnemonicCreator()
        mnemonicCreator.convert(words: words) { (mnemonic, error) in
            
            if !error {
                
                self.getKeys(mnemonic: mnemonic!)
                
            } else {
                
                self.connectingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "error converting those words into a seed")
                
            }
            
        }
        
    }
    
    private func fetchMultiSigKeysFromXprv(xprv: HDKey) {
        
        let parser = DescriptorParser()
        let s = parser.descriptor(wallet.descriptor)
        let keys = s.multiSigKeys
        let paths = s.multiSigPaths
        let sigsRequired = s.sigsRequired
        var failed = false
        var getKeysFromNode = false
        
        func getPrivKeys() {
            let derivation = self.wallet.derivation
            for i in 0 ... 999 {
                let path = derivation + "/" + "\(i)"
                if let bip32path = BIP32Path(path) {
                    do {
                        let childKey = try xprv.derive(bip32path)
                        if let privKey = childKey.privKey {
                            if self.keys.count > 0 {
                                self.keys[i]["wif"] = privKey.wif
                            }
                        }
                    } catch {
                        print("failed getting a key")
                    }
                }
                if i == 999 {
                    DispatchQueue.main.async {
                        self.table.reloadData()
                        self.connectingView.removeConnectingView()
                    }
                }
            }
        }
        
        for i in 0 ... 999 {
            var pubkeys = [PubKey]()
            var pubkeyStrings = [String]()
            for (k, key) in keys.enumerated() {
                let hdKey = HDKey(key)
                let path = paths[k] + "/" + "\(i)"
                do {
                    if let bip32path = BIP32Path(path) {
                        let key = try hdKey?.derive(bip32path)
                        if key != nil {
                            pubkeys.append(key!.pubKey)
                            pubkeyStrings.append("#\(k + 1): \(key!.pubKey.data.hexString)")
                            if k + 1 == keys.count {
                                let scriptPubKey = ScriptPubKey(multisig: pubkeys, threshold: sigsRequired, bip67: false)
                                var multiSigAddress:Address!
                                var processedPubkeys = "\(pubkeyStrings)".replacingOccurrences(of: "[", with: "")
                                processedPubkeys = processedPubkeys.replacingOccurrences(of: "]", with: "")
                                processedPubkeys = processedPubkeys.replacingOccurrences(of: "\"", with: "")
                                processedPubkeys = processedPubkeys.replacingOccurrences(of: ",", with: "\n")
                                // LibWally only produces bech32 multisig addresses, so need to fetch other formats from the node
                                if wallet.derivation.contains("84") || s.isBIP84 || s.isP2WPKH {
                                    multiSigAddress = Address(scriptPubKey, network(path: wallet.derivation))
                                    self.keys.append(["address":"\(String(describing: multiSigAddress!))", "publicKey":"\(processedPubkeys)", "scriptPubKey":"\(scriptPubKey)"])
                                } else {
                                    self.keys.append(["address":"fetching addresses from your node...", "publicKey":"\(processedPubkeys)", "scriptPubKey":"\(scriptPubKey)"])
                                    getKeysFromNode = true
                                }
                                pubkeys.removeAll()
                                
                            }
                        }
                    }
                } catch {
                    print("key derivation failed")
                    failed = true
                }
            }
            
            if i == 999 {
                if !failed {
                    getPrivKeys()
                } else {
                    self.connectingView.removeConnectingView()
                    displayAlert(viewController: self, isError: true, message: "key derivation failed")
                }
                if getKeysFromNode {
                    self.getKeysFromBitcoinCore()
                }
            }
            
        }
        
    }
    
    private func fetchKeysFromXprv(xprv: HDKey) {
        
        let derivation = wallet.derivation
        var addressType:AddressType!
        if derivation.contains("84") {

            addressType = .payToWitnessPubKeyHash

        } else if derivation.contains("44") {

            addressType = .payToPubKeyHash

        } else if derivation.contains("49") {

            addressType = .payToScriptHashPayToWitnessPubKeyHash

        }
        
        for i in 0 ... 999 {
            
            let path = BIP32Path("0/\(i)")!
            
            do {
                
                let key = try xprv.derive(path)
                let address = key.address(addressType)
                
                let dict = [
                
                    "address":"\(address)",
                    "publicKey":"\((key.pubKey.data).hexString)",
                    "wif":"\(key.privKey!.wif)"
                
                ]
                                        
                keys.append(dict)
                
                if i == 999 {
                    
                    DispatchQueue.main.async {
                        
                        self.table.reloadData()
                        self.connectingView.removeConnectingView()
                        
                    }
                    
                }
                
            } catch {
                
                print("error deriving keys")
                
            }
            
        }
        
    }
    
    func getKeys(mnemonic: BIP39Mnemonic) {
        
        let derivation = wallet.derivation
        let path = BIP32Path(derivation)!
        let masterKey = HDKey((mnemonic.seedHex("")), network(path: derivation))!
        let account = try! masterKey.derive(path)
        
        for i in 0 ... 999 {
            
            let key1 = try! account.derive(BIP32Path("\(i)")!)
            var addressType:AddressType!
            
            if derivation.contains("84") {

                addressType = .payToWitnessPubKeyHash

            } else if derivation.contains("44") {

                addressType = .payToPubKeyHash

            } else if derivation.contains("49") {

                addressType = .payToScriptHashPayToWitnessPubKeyHash

            }
            
            let address = key1.address(addressType)
            
            let dict = [
            
                "address":"\(address)",
                "publicKey":"\((key1.pubKey.data).hexString)",
                "wif":"\(key1.privKey!.wif)"
            
            ]
                                    
            keys.append(dict)
            
            if i == 999 {
                
                DispatchQueue.main.async {
                    
                    self.table.reloadData()
                    self.connectingView.removeConnectingView()
                    
                }
                
            }
            
        }
        
    }
    
    func impact() {
        
        DispatchQueue.main.async {
            
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            
        }
        
    }
    
    func showAuth() {
        
        DispatchQueue.main.async {
            
            self.authView.backgroundColor = .black
            self.authView.frame = self.view.frame
            let logInButton = ASAuthorizationAppleIDButton(type: .signIn, style: .whiteOutline)
            logInButton.sizeToFit()
            logInButton.addTarget(self, action: #selector(self.handleLogInWithAppleID), for: .touchUpInside)
            logInButton.frame = CGRect(x: 32, y: 100, width: self.view.frame.width - 64, height: 80)
            self.view.addSubview(self.authView)
            self.authView.addSubview(logInButton)
            
            let description = UILabel()
            description.font = .systemFont(ofSize: 16, weight: .light)
            description.numberOfLines = 0
            description.frame = CGRect(x: 48, y: logInButton.frame.maxY + 5, width: self.view.frame.width - 96, height: 150)
            description.text = "Blockchain Commons, LLC and FullyNoded 2 do not use or save your Apple ID data in anyway, it is used solely for 2FA (two-factor authentication) purposes only."
            description.sizeToFit()
            description.textAlignment = .left
            description.textColor = .white
            self.authView.addSubview(description)
            
        }
        
    }
    
    @objc func handleLogInWithAppleID() {
        print("handleLogInWithAppleID")
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        switch authorization.credential {

        case _ as ASAuthorizationAppleIDCredential:
            
            self.authView.removeFromSuperview()
            
            if self.showQr {
                
                self.impact()
                
                if self.keys[self.section]["wif"] != nil {
                    
                    self.qrString = self.keys[self.section]["wif"] ?? "no wif"
                    self.showQr = false
                    
                    DispatchQueue.main.async {
                        
                        self.performSegue(withIdentifier: "exportKeys", sender: self)
                        
                    }
                    
                }
                
            } else if self.copyText {
                
                self.impact()
                
                let wif = self.keys[self.section]["wif"] ?? "no wif exists"
                self.copyText = false
                
                UIPasteboard.general.string = wif
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                    
                    UIPasteboard.general.string = ""
                    
                }
                
                displayAlert(viewController: self, isError: false, message: "wif copied to clipboard for 60 seconds")
                
            }
                
            break

        default:

            break

        }

    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        let id = segue.identifier
        
        switch id {
            
        case "exportKeys":
            
            if let vc = segue.destination as? QRDisplayerViewController {
                
                vc.address = qrString
                
            }
            
        default:
            
            break
            
        }
        
    }
    

}
