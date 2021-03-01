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
    var s:DescriptorStruct!
    @IBOutlet var table: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        table.delegate = self
        table.dataSource = self
        connectingView.addConnectingView(vc: self, description: "deriving your keys")

    }

    override func viewDidAppear(_ animated: Bool) {

        getWords()

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

        addressView.layer.cornerRadius = 8
        publicKeyView.layer.cornerRadius = 8

        let addressLabel = cell.viewWithTag(2) as! UILabel
        let publicKeyLabel = cell.viewWithTag(6) as! UILabel

        addressLabel.adjustsFontSizeToFitWidth = true
        publicKeyLabel.adjustsFontSizeToFitWidth = true

        let showAddressQRButton = cell.viewWithTag(3) as! UIButton
        let copyAddressButton = cell.viewWithTag(4) as! UIButton
        let showPublicKeyQRButton = cell.viewWithTag(7) as! UIButton
        let copyPublicKeyButton = cell.viewWithTag(8) as! UIButton

        showAddressQRButton.accessibilityLabel = "\(indexPath.section)"
        copyAddressButton.accessibilityLabel = "\(indexPath.section)"
        showPublicKeyQRButton.accessibilityLabel = "\(indexPath.section)"
        copyPublicKeyButton.accessibilityLabel = "\(indexPath.section)"

        showAddressQRButton.addTarget(self, action: #selector(addressQR(_:)), for: .touchUpInside)
        copyAddressButton.addTarget(self, action: #selector(copyAddress(_:)), for: .touchUpInside)
        showPublicKeyQRButton.addTarget(self, action: #selector(publicKeyQR(_:)), for: .touchUpInside)
        copyPublicKeyButton.addTarget(self, action: #selector(copyPublicKey(_:)), for: .touchUpInside)

        addressLabel.text = keys[indexPath.section]["address"]
        publicKeyLabel.text = keys[indexPath.section]["publicKey"]

        return cell

    }

    private func multiSigCell(_ indexPath: IndexPath) -> UITableViewCell {

        let cell = table.dequeueReusableCell(withIdentifier: "exportMultiSigCell", for: indexPath)
        cell.selectionStyle = .none

        let addressView = cell.viewWithTag(1)!
        let pubkeysView = cell.viewWithTag(2)!
        let scriptPubKeyView = cell.viewWithTag(3)!

        addressView.layer.cornerRadius = 8
        pubkeysView.layer.cornerRadius = 8
        scriptPubKeyView.layer.cornerRadius = 8

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

        let addressQRButton = cell.viewWithTag(9) as! UIButton
        let addressCopyButton = cell.viewWithTag(10) as! UIButton
        let publicKeysQRButton = cell.viewWithTag(11) as! UIButton
        let publicKeysCopyButton = cell.viewWithTag(12) as! UIButton
        let scriptPubKeyQRButton = cell.viewWithTag(13) as! UIButton
        let scriptPubKeyCopyButton = cell.viewWithTag(14) as! UIButton

        addressQRButton.accessibilityLabel = "\(indexPath.section)"
        addressCopyButton.accessibilityLabel = "\(indexPath.section)"
        publicKeysCopyButton.accessibilityLabel = "\(indexPath.section)"
        publicKeysQRButton.accessibilityLabel = "\(indexPath.section)"
        scriptPubKeyCopyButton.accessibilityLabel = "\(indexPath.section)"
        scriptPubKeyQRButton.accessibilityLabel = "\(indexPath.section)"

        publicKeysQRButton.addTarget(self, action: #selector(publicKeyQR(_:)), for: .touchUpInside)
        publicKeysCopyButton.addTarget(self, action: #selector(copyPublicKey(_:)), for: .touchUpInside)

        scriptPubKeyQRButton.addTarget(self, action: #selector(scriptPubKeyQR(_:)), for: .touchUpInside)
        scriptPubKeyCopyButton.addTarget(self, action: #selector(copyScriptPubKey(_:)), for: .touchUpInside)

        addressQRButton.addTarget(self, action: #selector(addressQR(_:)), for: .touchUpInside)
        addressCopyButton.addTarget(self, action: #selector(copyAddress(_:)), for: .touchUpInside)

        return cell

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if !s.isMulti {

            return singleSigCell(indexPath)

        } else {

            return multiSigCell(indexPath)

        }

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if !s.isMulti {

            return 156

        } else {

            return 305

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

            displayAlert(viewController: self, isError: false, message: "script copied to clipboard for 60 seconds")
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

    func getMultiSigKeys(words: String?) {

        let parser = DescriptorParser()
        let s = parser.descriptor(wallet.descriptor)
        let keys = s.multiSigKeys
        let paths = s.multiSigPaths
        let sigsRequired = s.sigsRequired
        var failed = false
        var getKeysFromNode = false

//        func getPrivKeys() {
//            MnemonicCreator.convert(words: words!) { [unowned vc = self] (mnemonic, error) in
//
//                if !error {
//                    let derivation = vc.wallet.derivation
//
//                    for i in 0 ... 999 {
//                        let path = derivation + "/" + "\(i)"
//
//                        if let bip32path = BIP32Path(path) {
//
//                            if let key = HDKey((mnemonic!.seedHex("")), network(descriptor: vc.wallet.descriptor)) {
//
//                                do {
//                                    let childKey = try key.derive(bip32path)
//
//                                    if let privKey = childKey.privKey {
//
//                                        if vc.keys.count > 0 {
//                                            vc.keys[i]["wif"] = privKey.wif
//
//                                        }
//                                    }
//                                } catch {
//                                    print("failed getting a key")
//
//                                }
//                            }
//                        }
//
//                        if i == 999 {
//                            DispatchQueue.main.async {
//                                vc.table.reloadData()
//                                vc.connectingView.removeConnectingView()
//                            }
//
//                        }
//                    }
//                }
//            }
//        }

        for i in 0 ... 999 {
            var pubkeys = [PubKey]()
            var pubkeyStrings = [String]()

            for (k, key) in keys.enumerated() {
                let hdKey = try! HDKey(base58: key)
                let path = paths[k] + "/" + "\(i)"

                do {

                    if let bip32path = try? BIP32Path(string: path) {
                        guard let key = try? hdKey.derive(using: bip32path) else { return }
                        
                        pubkeys.append(key.pubKey)
                        pubkeyStrings.append("#\(k + 1): \(key.pubKey.data.hexString)")
                        
                        if k + 1 == keys.count {
                            let scriptPubKey = ScriptPubKey(multisig: pubkeys, threshold: sigsRequired, isBIP67: s.isBIP67)
                            var multiSigAddress:Address!
                            let processedPubkeys = processedKeys(pubkeys: pubkeyStrings)
                            
                            // LibWally only produces bech32 multisig addresses, so need to fetch other formats from the node
                            if wallet.derivation.contains("84") || wallet.derivation.contains("48") || s.isBIP84 || s.isP2WPKH {
                                multiSigAddress = try? Address(scriptPubKey: scriptPubKey, network: network(descriptor: wallet.descriptor))
                                self.keys.append(["address":"\(String(describing: multiSigAddress!))", "publicKey":"\(processedPubkeys)", "scriptPubKey":"\(scriptPubKey)"])
                                
                            } else {
                                self.keys.append(["address":"fetching addresses from your node...", "publicKey":"\(processedPubkeys)", "scriptPubKey":"\(scriptPubKey)"])
                                getKeysFromNode = true
                                
                            }
                            
                            pubkeys.removeAll()
                            
                        }
                    }

                } catch {
                    print("key derivation failed")
                    failed = true

                }
            }

            if i == 999 {

                if !failed {

                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.table.reloadData()
                        vc.connectingView.removeConnectingView()
                    }

//                    if words != nil {
//                        getPrivKeys()
//
//                    } else {
//                        DispatchQueue.main.async { [unowned vc = self] in
//                            vc.table.reloadData()
//                            vc.connectingView.removeConnectingView()
//                        }
//
//                    }

                } else {
                    self.connectingView.removeConnectingView()
                    displayAlert(viewController: self, isError: true, message: "key derivation failed")

                }

                if getKeysFromNode {
                    self.getKeysFromBitcoinCore()

                }
                    //displayAlert(viewController: self, isError: true, message: "key derivation failed")
                //}
//                if getKeysFromNode {
//                    self.getKeysFromBitcoinCore()
//                }
            }
        }
    }

    func getKeysFromBitcoinCore() {

       let param = "\"\(wallet.descriptor)\", ''[0,999]''"
       Reducer.makeCommand(walletName: "", command: .deriveaddresses, param: param) { [unowned vc = self] (object, errorDesc) in

            if let result = object as? NSArray {

                for (i, address) in result.enumerated() {
                    if vc.keys.count > 0 {
                        vc.keys[i]["address"] = (address as! String)
                    }
                    if i + 1 == result.count {
                        DispatchQueue.main.async {
                            vc.table.reloadData()
                        }
                    }
                }

            } else {

                displayAlert(viewController: vc, isError: true, message: "error getting addresses from your node")

            }
        }

    }

    func getWords() {

        getActiveWalletNow { [unowned vc = self] (wallet, error) in

            if wallet != nil && !error {

                vc.wallet = wallet!
                let parser = DescriptorParser()
                vc.s = parser.descriptor(wallet!.descriptor)

                if String(data: wallet!.seed, encoding: .utf8) != "no seed" {

                    Encryption.decryptData(dataToDecrypt: wallet!.seed) { [unowned vc = self] (decryptedSeed) in

                        if decryptedSeed != nil {

                            if let words = String(bytes: decryptedSeed!, encoding: .utf8) {

                                if vc.s.isMulti {

                                    vc.getMultiSigKeys(words: words)

                                } else {

                                    vc.getSingleSigKeys(words: words)

                                }

                            }

                        }

                    }

                } else {

                    /// Its watch-only
                    if vc.s.isMulti {

                        vc.getMultiSigKeys(words: nil)

                    } else {

                        vc.getSingleSigKeys(words: nil)

                    }

                }

            }

        }

    }

    func getSingleSigKeys(words: String?) {

        if words != nil {
            MnemonicCreator.convert(words: words!) { [unowned vc = self] (mnemonic, error) in

                if !error {
                    vc.getKeys(mnemonic: mnemonic!)

                } else {
                    vc.connectingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "error converting those words into a seed")

                }

            }

        } else {
            let p = DescriptorParser()
            let str = p.descriptor(wallet.descriptor)

            if let xpub = try? HDKey(base58: str.accountXpub) {
                fetchKeysFromXpub(xpub: xpub)

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
            let path = try! BIP32Path(string: "0/\(i)")

            do {
                let key = try xprv.derive(using: path)
                let address = key.address(type: addressType).description

                let dict = [

                    "address":"\(address)",
                    "publicKey":"\((key.pubKey.data).hexString)"/*,
                    "wif":"\(key.privKey!.wif)"*/

                ]

                keys.append(dict)

                if i == 999 {
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.table.reloadData()
                        vc.connectingView.removeConnectingView()

                    }

                }

            } catch {
                print("error deriving keys")

            }

        }

    }

    private func fetchKeysFromXpub(xpub: HDKey) {
        let derivation = wallet.derivation
        var addressType:AddressType!
        
        if derivation.contains("84") {
            addressType = .payToWitnessPubKeyHash
        } else if derivation.contains("44") {
            addressType = .payToPubKeyHash
        } else if derivation.contains("49") {
            addressType = .payToScriptHashPayToWitnessPubKeyHash
        } else {
            // To cover custom derivs
            let descriptor = wallet.descriptor
            let descriptorParser = DescriptorParser()
            let descriptorStruct = descriptorParser.descriptor(descriptor)
            if descriptorStruct.isP2PKH {
                addressType = .payToPubKeyHash
            } else if descriptorStruct.isP2SHP2WPKH {
                addressType = .payToScriptHashPayToWitnessPubKeyHash
            } else if descriptorStruct.isP2WPKH {
                addressType = .payToScriptHashPayToWitnessPubKeyHash
            }
        }

        for i in 0 ... 999 {

            let path = try! BIP32Path(string: "0/\(i)")

            do {

                let key = try xpub.derive(using: path)
                let address = key.address(type: addressType).description

                let dict = [

                    "address":"\(address)",
                    "publicKey":"\((key.pubKey.data).hexString)"

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
        let path = try! BIP32Path(string: derivation)
        let masterKey = try! HDKey(seed: (mnemonic.seedHex(passphrase: "")), network: network(descriptor: wallet.descriptor))
        let account = try! masterKey.derive(using: path)

        for i in 0 ... 999 {

            let key1 = try! account.derive(using: BIP32Path(string: "0/\(i)"))
            var addressType:AddressType!

            if derivation.contains("84") {

                addressType = .payToWitnessPubKeyHash

            } else if derivation.contains("44") {

                addressType = .payToPubKeyHash

            } else if derivation.contains("49") {

                addressType = .payToScriptHashPayToWitnessPubKeyHash

            }

            let address = key1.address(type: addressType).description

            let dict = [

                "address":"\(address)",
                "publicKey":"\((key1.pubKey.data).hexString)"/*,
                "wif":"\(key1.privKey!.wif)"*/

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

    func showAuth() {

        DispatchQueue.main.async {

            self.handleLogInWithAppleID()

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

                if self.keys[self.section]["wif"] != nil {

                    self.qrString = self.keys[self.section]["wif"] ?? "no wif"
                    self.showQr = false

                    DispatchQueue.main.async {

                        self.performSegue(withIdentifier: "exportKeys", sender: self)

                    }

                }

            } else if self.copyText {

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

    private func processedKeys(pubkeys: [String]) -> String {

        var processedPubkeys = "\(pubkeys)".replacingOccurrences(of: "[", with: "")
        processedPubkeys = processedPubkeys.replacingOccurrences(of: "]", with: "")
        processedPubkeys = processedPubkeys.replacingOccurrences(of: "\"", with: "")
        return processedPubkeys.replacingOccurrences(of: ",", with: "\n")

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

                vc.text = qrString

            }

        default:

            break

        }

    }


}
