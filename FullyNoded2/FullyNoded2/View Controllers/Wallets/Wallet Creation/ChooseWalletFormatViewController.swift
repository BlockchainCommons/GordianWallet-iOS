//
//  ChooseWalletFormatViewController.swift
//  FullyNoded2
//
//  Created by Peter on 13/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally
import CryptoKit

class ChooseWalletFormatViewController: UIViewController, UINavigationControllerDelegate {
    
    var id:UUID!
    var derivation = ""
    var recoveryQr = ""
    var entropy = ""
    var localXprv = ""
    var node:NodeStruct!
    var newWallet = [String:Any]()
    var isBIP84 = Bool()
    var isBIP49 = Bool()
    var isBIP44 = Bool()
    var isMultiSig = Bool()
    var isSingleSig = Bool()
    var publickeys = [String]()
    var fingerprints = [String]()
    var localSeed = Data()
    var nodesSeed = ""
    var nodesHdSeed = ""
    var descriptor = ""
    var recoveryPubkey = ""
    var backUpRecoveryPhrase = ""
    var walletDoneBlock : ((Bool) -> Void)?
    var multiSigDoneBlock : (((success: Bool, recoveryPhrase: String, descriptor: String)) -> Void)?
    var importDoneBlock : ((Bool) -> Void)?
    let enc = Encryption()
    let creatingView = ConnectingView()
    var recoverDoneBlock : ((Bool) -> Void)?
    
    @IBOutlet var formatSwitch: UISegmentedControl!
    @IBOutlet var templateSwitch: UISegmentedControl!
    @IBOutlet var buttonOutlet: UIButton!
    @IBOutlet var seedDescription: UILabel!
    @IBOutlet var importButtonOutlet: UIButton!
    @IBOutlet var recoverWalletOutlet: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        buttonOutlet.clipsToBounds = true
        buttonOutlet.layer.cornerRadius = 10
        importButtonOutlet.layer.cornerRadius = 10
        recoverWalletOutlet.layer.cornerRadius = 10
        formatSwitch.selectedSegmentIndex = 0
        templateSwitch.selectedSegmentIndex = 0
        isBIP84 = true
        isMultiSig = true
        seedDescription.text = "Your device will hold one seed, your node will hold 2,000 private keys derived from a second seed, and you will securely store one seed offline for recovery purposes.\n\nYour node will create PSBT's and sign them with one key, passing the partially signed PSBT's to your device which will sign the PSBT's with the second key."
        seedDescription.sizeToFit()
        
    }
    
    @IBAction func importAction(_ sender: Any) {
        
        showAlert(vc: self, title: "🛠 Not yet ready", message: "This feature is under active development and not quite ready for testing yet.")
        
//        DispatchQueue.main.async {
//
//            self.importDoneBlock!(true)
//            self.dismiss(animated: true, completion: nil)
//
//        }
        
    }
    
    @IBAction func recoverAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "goRecover", sender: self)
            
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func derivationeAction(_ sender: Any) {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
        }
        
        let switcher = sender as! UISegmentedControl
        
        switch switcher.selectedSegmentIndex {
            
        case 0:
            
            isBIP84 = true
            isBIP44 = false
            isBIP49 = false
            
        case 1:
            
            isBIP49 = true
            isBIP44 = false
            isBIP84 = false
            
        case 2:
            
            isBIP44 = true
            isBIP84 = false
            isBIP49 = false
            
        default:
            
            break
            
        }
        
    }
    
    @IBAction func signatureTypeAction(_ sender: Any) {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
                
            impact.impactOccurred()
            
        }
        
        let switcher = sender as! UISegmentedControl
        
        switch switcher.selectedSegmentIndex {
            
        case 0:
            
            isMultiSig = true
            isSingleSig = false
            
            DispatchQueue.main.async {
                
                self.formatSwitch.setTitle("P2WSH", forSegmentAt: 0)
                self.formatSwitch.setTitle("P2SH-P2WSH", forSegmentAt: 1)
                self.formatSwitch.setTitle("P2SH", forSegmentAt: 2)
                
                self.seedDescription.text = "Your device will hold one seed, your node will hold 2,000 private keys derived from a second seed, and you will securely store one seed offline for recovery purposes.\n\nYour node will create PSBT's and sign them with one key, passing the partially signed PSBT's to your device which will sign the PSBT's with the second key."
                
            }
            
        case 1:
            
            isSingleSig = true
            isMultiSig = false
            
            DispatchQueue.main.async {
                
                self.formatSwitch.setTitle("P2WPKH", forSegmentAt: 0)
                self.formatSwitch.setTitle("P2SH-P2WPKH", forSegmentAt: 1)
                self.formatSwitch.setTitle("P2PKH", forSegmentAt: 2)
                
                self.seedDescription.text = "Your device will hold one seed and your node will hold 2,000 public keys derived from the same seed.\n\nYour node will build unsigned PSBT's acting as a watch-only wallet and pass them to your device for offline signing."
                
            }
            
        default:
            
            break
            
        }
                
    }
    
    @IBAction func createAction(_ sender: Any) {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
        }
        
        enc.getNode { (node, error) in
            
            if !error && node != nil {
                
                self.node = node!
                self.creatingView.addConnectingView(vc: self.navigationController!, description: "creating your wallet")
                self.newWallet["blockheight"] = UserDefaults.standard.object(forKey: "blockheight") as? Int ?? 1
                self.newWallet["maxRange"] = 2500
                
                if self.node.network == "testnet" {
                    
                    if self.isBIP84 {
                        
                        self.newWallet["derivation"] = "m/84'/1'/0'"
                        self.derivation = "BIP84 m/84'/1'/0'"
                        
                    } else if self.isBIP49 {
                        
                        self.newWallet["derivation"] = "m/49'/1'/0'"
                        self.derivation = "BIP49 m/49'/1'/0'"
                        
                    } else if self.isBIP44 {
                        
                        self.newWallet["derivation"] = "m/44'/1'/0'"
                        self.derivation = "BIP44 m/44'/1'/0'"
                        
                    }
                    
                } else if self.node.network == "mainnet" {
                    
                    if self.isBIP84 {
                        
                        self.newWallet["derivation"] = "m/84'/0'/0'"
                        self.derivation = "BIP84 m/84'/0'/0'"
                        
                    } else if self.isBIP49 {
                        
                        self.newWallet["derivation"] = "m/49'/0'/0'"
                        self.derivation = "BIP49 m/44'/0'/0'"
                        
                    } else if self.isBIP44 {
                        
                        self.newWallet["derivation"] = "m/44'/0'/0'"
                        self.derivation = "BIP44 m/44'/0'/0'"
                        
                    }
                    
                }
                
                self.newWallet["birthdate"] = keyBirthday()
                self.id = UUID()
                self.newWallet["id"] = self.id
                self.newWallet["isActive"] = false
                self.newWallet["lastUsed"] = Date()
                self.newWallet["lastBalance"] = 0.0
                self.newWallet["isArchived"] = false
                self.newWallet["nodeId"] = self.node.id
                                
                if self.isMultiSig {
                    
                    self.newWallet["type"] = "MULTI"
                    self.createMultiSig()
                    
                } else if self.isSingleSig {
                    
                    self.newWallet["type"] = "DEFAULT"
                    self.createSingleSig()
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "no active node")
                
            }
            
        }
        
    }
    
    func createSingleSig() {
        print("create single sig")
        
        let keyCreator = KeychainCreator()
        keyCreator.createKeyChain() { (mnemonic, error) in
            
            if !error {
                
                let dataToEncrypt = mnemonic!.dataUsingUTF8StringEncoding
                self.enc.encryptData(dataToEncrypt: dataToEncrypt) { (encryptedData, error) in
                    
                    if !error {
                        
                        self.newWallet["seed"] = encryptedData!
                        self.constructSingleSigPrimaryDescriptor(wallet: WalletStruct(dictionary: self.newWallet))
                        
                    } else {
                        
                        self.creatingView.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: "error encrypting your seed")
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func constructSingleSigPrimaryDescriptor(wallet: WalletStruct) {
        
        let keyFetcher = KeyFetcher()
        keyFetcher.xpub(wallet: wallet) { (xpub, error) in
            
            if !error {
                
                keyFetcher.fingerprint(wallet: wallet) { (fingerprint, error) in
                    
                    if !error && fingerprint != nil {
                        
                        var param = ""
                        
                        switch wallet.derivation {
                            
                        case "m/84'/1'/0'":
                            param = "\"wpkh([\(fingerprint!)/84'/1'/0']\(xpub!)/0/*)\""
                            
                        case "m/84'/0'/0'":
                            param = "\"wpkh([\(fingerprint!)/84'/0'/0']\(xpub!)/0/*)\""
                            
                        case "m/44'/1'/0'":
                            param = "\"pkh([\(fingerprint!)/44'/1'/0']\(xpub!)/0/*)\""
                             
                        case "m/44'/0'/0'":
                            param = "\"pkh([\(fingerprint!)/44'/0'/0']\(xpub!)/0/*)\""
                            
                        case "m/49'/1'/0'":
                            param = "\"sh(wpkh([\(fingerprint!)/49'/1'/0']\(xpub!)/0/*))\""
                            
                        case "m/49'/0'/0'":
                            param = "\"sh(wpkh([\(fingerprint!)/49'/0'/0']\(xpub!)/0/*))\""
                            
                        default:
                            
                            break
                            
                        }
                        
                        let reducer = Reducer()
                        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) {
                            
                            if !reducer.errorBool {
                                
                                if let dict = reducer.dictToReturn {
                                    
                                    let primaryDescriptor = dict["descriptor"] as! String
                                    self.newWallet["descriptor"] = primaryDescriptor
                                    let digest = SHA256.hash(data: primaryDescriptor.dataUsingUTF8StringEncoding)
                                    let stringHash = digest.map { String(format: "%02hhx", $0) }.joined()
                                    self.newWallet["name"] = stringHash
                                    self.constructSingleSigChangeDescriptor(wallet: WalletStruct(dictionary: self.newWallet))
                                    
                                }
                                
                            } else {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: reducer.errorDescription)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "error fetching xpub")
                
            }
            
        }
        
    }
    
    func constructSingleSigChangeDescriptor(wallet: WalletStruct) {
        
        let keyFetcher = KeyFetcher()
        keyFetcher.xpub(wallet: wallet) { (xpub, error) in
            
            if !error {
                
                keyFetcher.fingerprint(wallet: wallet) { (fingerprint, error) in
                    
                    if !error && fingerprint != nil {
                        
                        var param = ""
                        
                        switch wallet.derivation {
                            
                        case "m/84'/1'/0'":
                            param = "\"wpkh([\(fingerprint!)/84'/1'/0']\(xpub!)/1/*)\""
                            
                        case "m/84'/0'/0'":
                            param = "\"wpkh([\(fingerprint!)/84'/0'/0']\(xpub!)/1/*)\""
                            
                        case "m/44'/1'/0'":
                            param = "\"pkh([\(fingerprint!)/44'/1'/0']\(xpub!)/1/*)\""
                             
                        case "m/44'/0'/0'":
                            param = "\"pkh([\(fingerprint!)/44'/0'/0']\(xpub!)/1/*)\""
                            
                        case "m/49'/1'/0'":
                            param = "\"sh(wpkh([\(fingerprint!)/49'/1'/0']\(xpub!)/1/*))\""
                            
                        case "m/49'/0'/0'":
                            param = "\"sh(wpkh([\(fingerprint!)/49'/0'/0']\(xpub!)/1/*))\""
                            
                        default:
                            
                            break
                            
                        }
                        
                        let reducer = Reducer()
                        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) {
                            
                            if !reducer.errorBool {
                                
                                if let dict = reducer.dictToReturn {
                                    
                                    let changeDescriptor = dict["descriptor"] as! String
                                    self.newWallet["changeDescriptor"] = changeDescriptor
                                    self.createSingleSigWallet()
                                    
                                }
                                
                            } else {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: reducer.errorDescription)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "error fetching xpub")
                
            }
            
        }
        
    }
    
    func createSingleSigWallet() {
        
        let walletCreator = WalletCreator()
        walletCreator.walletDict = self.newWallet
        walletCreator.createStandUpWallet() { (success, errorDescription) in
            
            if success {
                
                let walletSaver = WalletSaver()
                walletSaver.save(walletToSave: self.newWallet) { (success) in
                    
                    if success {
                        
                        self.creatingView.removeConnectingView()
                        let w = WalletStruct(dictionary: self.newWallet)
                        
                        let encryptedMnemonic = w.seed
                        self.enc.decryptData(dataToDecrypt: encryptedMnemonic) { (mnemonic) in
                            
                            if mnemonic != nil {
                                
                                if let words = String(data: mnemonic!, encoding: .utf8) {
                                    
                                    if let bip39mnemonic = BIP39Mnemonic(words) {
                                        
                                        let seed = bip39mnemonic.seedHex()
                                        
                                        if let mk = HDKey(seed, network(path: w.derivation)) {
                                            
                                            if let path = BIP32Path(w.derivation) {
                                                
                                                do {
                                                    
                                                    if let xprv = try mk.derive(path).xpriv {
                                                        
                                                        let p = DescriptorParser()
                                                        let str = p.descriptor(w.descriptor)
                                                        
                                                        let hotDesc = (w.descriptor).replacingOccurrences(of: str.accountXpub, with: xprv)
                                                        
                                                        let recoveryQr = ["entropy": bip39mnemonic.entropy.description, "descriptor":"\(hotDesc)", "birthdate":w.birthdate, "blockheight":w.blockheight,"label":""] as [String : Any]
                                                        
                                                        if let json = recoveryQr.json() {
                                                            
                                                            DispatchQueue.main.async {
                                                                
                                                                self.backUpRecoveryPhrase = words
                                                                self.recoveryQr = json
                                                                self.performSegue(withIdentifier: "walletCreated", sender: self)
                                                                
                                                            }
                                                            
                                                        } else {
                                                            
                                                            self.creatingView.removeConnectingView()
                                                            displayAlert(viewController: self, isError: true, message: "error converting to json")
                                                            
                                                        }
                                                        
                                                    } else {
                                                        
                                                        self.creatingView.removeConnectingView()
                                                        displayAlert(viewController: self, isError: true, message: "error deriving xprv")
                                                        
                                                    }
                                                    
                                                } catch {
                                                    
                                                    self.creatingView.removeConnectingView()
                                                    displayAlert(viewController: self, isError: true, message: "error deriving xprv")
                                                    
                                                }
                                                
                                            } else {
                                                
                                                self.creatingView.removeConnectingView()
                                                displayAlert(viewController: self, isError: true, message: "error deriving bip32path")
                                                
                                            }
                                            
                                        } else {
                                            
                                            self.creatingView.removeConnectingView()
                                            displayAlert(viewController: self, isError: true, message: "error deriving master key")
                                            
                                        }
                                                                                
                                    } else {
                                        
                                        self.creatingView.removeConnectingView()
                                        displayAlert(viewController: self, isError: true, message: "error deriving bip39mnemonic")
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: "error decrypting seed")
                                
                            }
                            
                        }
                        
                    } else {
                        
                        self.creatingView.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: "There was an error saving your wallet")
                        
                    }
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "There was an error creating your wallet: \(errorDescription!)")
                
            }
            
        }
        
    }
    
    func createMultiSig() {
        
        let keychainCreator = KeychainCreator()
        keychainCreator.createKeyChain { (mnemonic, error) in
            
            if !error {
                
                let derivation = self.newWallet["derivation"] as! String
                self.backUpRecoveryPhrase = mnemonic!
                let mnemonicCreator = MnemonicCreator()
                mnemonicCreator.convert(words: self.backUpRecoveryPhrase) { (mnemonic, error) in
                    
                    if !error {
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivation)) {
                            
                            let recoveryFingerPrint = masterKey.fingerprint.hexString
                            self.fingerprints.append(recoveryFingerPrint)
                            
                            if let path = BIP32Path(derivation) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    self.recoveryPubkey = account.xpub
                                    self.publickeys.append(self.recoveryPubkey)
                                    self.createLocalKey()
                                    
                                } catch {
                                    
                                    self.creatingView.removeConnectingView()
                                    displayAlert(viewController: self, isError: true, message: "failed deriving xpub")
                                    
                                }
                                
                            } else {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: "failed initiating bip32 path")
                                
                            }
                            
                        } else {
                            
                            self.creatingView.removeConnectingView()
                            displayAlert(viewController: self, isError: true, message: "failed creating masterkey")
                            
                        }
                        
                    } else {
                        
                        self.creatingView.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: "error getting xpub from your recovery key")
                        
                    }
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "error creating your recovery key")
                
            }
            
        }
        
    }
    
    func createLocalKey() {
        print("createLocalKey")
        
        let keychainCreator = KeychainCreator()
        keychainCreator.createKeyChain { (words, error) in
            
            if !error {
                
                let unencryptedSeed = words!.dataUsingUTF8StringEncoding
                let enc = Encryption()
                enc.encryptData(dataToEncrypt: unencryptedSeed) { (encryptedSeed, error) in
                    
                    if !error {
                        
                        self.localSeed = encryptedSeed!
                        let converter = MnemonicCreator()
                        converter.convert(words: words!) { (mnemonic, error) in
                            
                            if !error {
                                
                                self.entropy = mnemonic!.entropy.description
                                let derivation = self.newWallet["derivation"] as! String
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivation)) {
                                    
                                    let localFingerPrint = masterKey.fingerprint.hexString
                                    self.fingerprints.append(localFingerPrint)
                                                                        
                                    if let path = BIP32Path(derivation) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            self.publickeys.append(account.xpub)
                                            
                                            if account.xpriv != nil {
                                                
                                                self.localXprv = account.xpriv!
                                                self.createNodesKey()
                                                
                                            } else {
                                                
                                                self.creatingView.removeConnectingView()
                                                displayAlert(viewController: self, isError: true, message: "failed deriving local xpriv")
                                                
                                            }
                                            
                                        } catch {
                                            
                                            self.creatingView.removeConnectingView()
                                            displayAlert(viewController: self, isError: true, message: "failed deriving xpub")
                                            
                                        }
                                        
                                    } else {
                                        
                                        self.creatingView.removeConnectingView()
                                        displayAlert(viewController: self, isError: true, message: "failed initiating bip32 path")
                                        
                                    }
                                    
                                } else {
                                    
                                    self.creatingView.removeConnectingView()
                                    displayAlert(viewController: self, isError: true, message: "failed creating masterkey")
                                    
                                }
                                
                            } else {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: "error converting your words to BIP39 mnmemonic")
                                
                            }
                            
                        }
                        
                    } else {
                        
                        self.creatingView.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: "error encrypting data")
                        
                    }
                    
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "error creating your recovery key")
                
            }
            
        }
        
    }
    
    func createNodesKey() {
        print("createNodesKey")
        
        let keychainCreator = KeychainCreator()
        keychainCreator.createKeyChain { (words, error) in
            
            if !error {
                
                let converter = MnemonicCreator()
                converter.convert(words: words!) { (mnemonic, error) in
                    
                    print("nodes words  = \(String(describing: words))")
                    
                    if !error {
                        
                        let derivation = self.newWallet["derivation"] as! String
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivation)) {
                            
                            do {
                                
                                let hdSeed = try masterKey.derive(BIP32Path("m/0'/0'")!)
                                print("hdseed = \(String(describing: hdSeed.xpriv))")
                                
                            } catch {
                                
                                
                            }
                            
                            let nodesFingerPrint = masterKey.fingerprint.hexString
                            self.fingerprints.append(nodesFingerPrint)
                            
                            if let path = BIP32Path(derivation) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    self.publickeys.append(account.xpub)
                                    
                                    if account.xpriv != nil {
                                        
                                        self.nodesSeed = account.xpriv!
                                        self.constructDescriptor(derivation: derivation)
                                        
                                    } else {
                                        
                                        self.creatingView.removeConnectingView()
                                        displayAlert(viewController: self, isError: true, message: "failed deriving node's xprv")
                                        
                                    }
                                    
                                    
                                } catch {
                                    
                                    self.creatingView.removeConnectingView()
                                    displayAlert(viewController: self, isError: true, message: "failed deriving xpub")
                                    
                                }
                                
                            } else {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: "failed initiating bip32 path")
                                
                            }
                            
                        } else {
                            
                            self.creatingView.removeConnectingView()
                            displayAlert(viewController: self, isError: true, message: "failed creating masterkey")
                            
                        }
                        
                    } else {
                        
                        self.creatingView.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: "error converting your words to BIP39 mnmemonic")
                        
                    }
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "error encrypting data")
                
            }
            
        }
        
    }
    
    func constructDescriptor(derivation: String) {
        
        let recoveryKey = publickeys[0]
        let localKey = publickeys[1]
        let nodeKey = publickeys[2]
        let recoveryFingerprint = fingerprints[0]
        let localFingerprint = fingerprints[1]
        let nodeFingerprint = fingerprints[2]
        let signatures = 2
        var changeDescriptor = ""
        
        // MARK: TODO CHANGE MULTI TO SORTEDMULTI - NEEDS BITCOIN CORE V0.20
        
        switch derivation {
            
        case "m/84'/1'/0'":
                                            
            descriptor = "wsh(multi(\(signatures),[\(recoveryFingerprint)/84'/1'/0']\(recoveryKey)/0/*, [\(localFingerprint)/84'/1'/0']\(localKey)/0/*, [\(nodeFingerprint)/84'/1'/0']\(nodeKey)/0/*))"

            changeDescriptor = "wsh(multi(\(signatures),[\(recoveryFingerprint)/84'/1'/0']\(recoveryKey)/1/*, [\(localFingerprint)/84'/1'/0']\(localKey)/1/*, [\(nodeFingerprint)/84'/1'/0']\(nodeKey)/1/*))"
            
        case "m/84'/0'/0'":

            descriptor = "wsh(multi(\(signatures),[\(recoveryFingerprint)/84'/0'/0']\(recoveryKey)/0/*, [\(localFingerprint)/84'/0'/0']\(localKey)/0/*, [\(nodeFingerprint)/84'/0'/0']\(nodeKey)/0/*))"
            
            changeDescriptor = "wsh(multi(\(signatures),[\(recoveryFingerprint)/84'/0'/0']\(recoveryKey)/1/*, [\(localFingerprint)/84'/0'/0']\(localKey)/1/*, [\(nodeFingerprint)/84'/0'/0']\(nodeKey)/1/*))"

        case "m/44'/1'/0'":

            descriptor = "sh(multi(\(signatures),[\(recoveryFingerprint)/44'/1'/0']\(recoveryKey)/0/*, [\(localFingerprint)/44'/1'/0']\(localKey)/0/*, [\(nodeFingerprint)/44'/1'/0']\(nodeKey)/0/*))"
            
            changeDescriptor = "sh(multi(\(signatures),[\(recoveryFingerprint)/44'/1'/0']\(recoveryKey)/1/*, [\(localFingerprint)/44'/1'/0']\(localKey)/1/*, [\(nodeFingerprint)/44'/1'/0']\(nodeKey)/1/*))"

        case "m/44'/0'/0'":

            descriptor = "sh(multi(\(signatures),[\(recoveryFingerprint)/44'/0'/0']\(recoveryKey)/0/*, [\(localFingerprint)/44'/0'/0']\(localKey)/0/*, [\(nodeFingerprint)/44'/0'/0']\(nodeKey)/0/*))"
            
            changeDescriptor = "sh(multi(\(signatures),[\(recoveryFingerprint)/44'/0'/0']\(recoveryKey)/1/*, [\(localFingerprint)/44'/0'/0']\(localKey)/1/*, [\(nodeFingerprint)/44'/0'/0']\(nodeKey)/1/*))"

        case "m/49'/1'/0'":

            descriptor = "sh(wsh(multi(\(signatures),[\(recoveryFingerprint)/49'/1'/0']\(recoveryKey)/0/*, [\(localFingerprint)/49'/1'/0']\(localKey)/0/*, [\(nodeFingerprint)/49'/1'/0']\(nodeKey)/0/*)))"
            
            changeDescriptor = "sh(wsh(multi(\(signatures),[\(recoveryFingerprint)/49'/1'/0']\(recoveryKey)/1/*, [\(localFingerprint)/49'/1'/0']\(localKey)/1/*, [\(nodeFingerprint)/49'/1'/0']\(nodeKey)/1/*)))"

        case "m/49'/0'/0'":
            
            descriptor = "sh(wsh(multi(\(signatures),[\(recoveryFingerprint)/49'/0'/0']\(recoveryKey)/0/*, [\(localFingerprint)/49'/0'/0']\(localKey)/0/*, [\(nodeFingerprint)/49'/0'/0']\(nodeKey)/0/*)))"
            
            changeDescriptor = "sh(wsh(multi(\(signatures),[\(recoveryFingerprint)/49'/0'/0']\(recoveryKey)/1/*, [\(localFingerprint)/49'/0'/0']\(localKey)/1/*, [\(nodeFingerprint)/49'/0'/0']\(nodeKey)/1/*)))"
            
        default:
            
            break
            
        }
        
        descriptor = descriptor.replacingOccurrences(of: "\"", with: "")
        descriptor = descriptor.replacingOccurrences(of: " ", with: "")
        changeDescriptor = changeDescriptor.replacingOccurrences(of: "\"", with: "")
        changeDescriptor = changeDescriptor.replacingOccurrences(of: " ", with: "")
        getInfo(primaryDescriptor: descriptor, changeDescriptor: changeDescriptor)
        
    }
    
    func getInfo(primaryDescriptor: String, changeDescriptor: String) {
        
        DispatchQueue.main.async {
            
            self.creatingView.label.text = "creating your wallets descriptors"
            
        }
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryDescriptor)\"") {
            
            if !reducer.errorBool {
                
                if let result = reducer.dictToReturn {
                    
                    if let primaryDescriptor = result["descriptor"] as? String {
                        
                        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDescriptor)\"") {
                            
                            DispatchQueue.main.async {
                                
                                self.creatingView.label.text = "importing your descriptors to your node"
                                
                            }
                            
                            if let result = reducer.dictToReturn {
                                
                                if let changeDesc = result["descriptor"] as? String {
                                    
                                    let enc = Encryption()
                                    enc.getNode { (node, error) in
                                        
                                        if !error {
                                            
                                            self.newWallet["descriptor"] = primaryDescriptor
                                            self.newWallet["changeDescriptor"] = changeDesc
                                            self.newWallet["seed"] = self.localSeed
                                            let digest = SHA256.hash(data: primaryDescriptor.dataUsingUTF8StringEncoding)
                                            let stringHash = digest.map { String(format: "%02hhx", $0) }.joined()
                                            self.newWallet["name"] = stringHash
                                            
                                            let multiSigCreator = CreateMultiSigWallet()
                                            let wallet = WalletStruct(dictionary: self.newWallet)
                                            multiSigCreator.create(wallet: wallet, nodeXprv: self.nodesSeed, nodeXpub: self.publickeys[2]) { (success, error) in
                                                
                                                if success {
                                                    
                                                    DispatchQueue.main.async {
                                                        
                                                       self.creatingView.label.text = "saving your wallet to your device"
                                                        
                                                    }
                                                    
                                                    let walletSaver = WalletSaver()
                                                    walletSaver.save(walletToSave: self.newWallet) { (success) in
                                                        
                                                        if success {
                                                            
                                                            self.creatingView.removeConnectingView()
                                                            
                                                            DispatchQueue.main.async {
                                                                
                                                                //self.nodesSeed = ""
                                                                //self.newWallet.removeAll()
                                                                // include the checksum as we will convert this back to a pubkey descriptor when recovering
                                                                let hotDescriptor = primaryDescriptor.replacingOccurrences(of: self.publickeys[1], with: self.localXprv)
                                                                let recoveryQr = ["entropy": self.entropy, "descriptor":"\(hotDescriptor)", "birthdate":wallet.birthdate, "blockheight":wallet.blockheight, "label":""] as [String : Any]
                                                                
                                                                if let json = recoveryQr.json() {
                                                                    
                                                                    DispatchQueue.main.async {
                                                                        
                                                                        self.recoveryQr = json
                                                                        self.performSegue(withIdentifier: "walletCreated", sender: self)
                                                                        
                                                                    }
                                                                    
                                                                }
                                                                
                                                            }
                                                            
                                                        } else {
                                                            
                                                            self.creatingView.removeConnectingView()
                                                            displayAlert(viewController: self, isError: true, message: "error saving wallet")
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                } else {
                                                    
                                                    if error != nil {
                                                        
                                                        self.creatingView.removeConnectingView()
                                                        displayAlert(viewController: self, isError: true, message: "error creating wallet: \(error!)")
                                                        
                                                    } else {
                                                        
                                                        self.creatingView.removeConnectingView()
                                                        displayAlert(viewController: self, isError: true, message: "error creating wallet")
                                                        
                                                    }                                                    
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                                
            } else {
                
                print("error: \(reducer.errorDescription)")
                
            }
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "walletCreated":
            
            if let vc = segue.destination as? WalletCreatedSuccessViewController {
                
                //vc.isMulti = self.isMultiSig
                //vc.derivationPath = self.derivation
                vc.recoveryPhrase = self.backUpRecoveryPhrase
                vc.recoveryQr = self.recoveryQr
                //vc.walletId = self.id
                vc.wallet = self.newWallet
                
//                vc.walletDoneNowBlock = { result in
//
//                    DispatchQueue.main.async {
//
//                        self.dismiss(animated: true) {
//
//                            self.walletDoneBlock!(true)
//
//                        }
//
//                    }
//
//                }
                
            }
            
        case "goRecover":
            
            if let vc = segue.destination as? WalletRecoverViewController {
                
                vc.onDoneBlock = { result in
                    
                    DispatchQueue.main.async {
                        
                        self.recoverDoneBlock!(true)
                        self.navigationController!.popToRootViewController(animated: true)
                        
                    }                    
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }

}
