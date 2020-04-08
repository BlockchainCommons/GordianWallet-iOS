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
    let enc = Encryption.sharedInstance
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
        
        enc.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                vc.node = node!
                vc.creatingView.addConnectingView(vc: self.navigationController!, description: "creating your wallet")
                vc.newWallet["blockheight"] = UserDefaults.standard.object(forKey: "blockheight") as? Int ?? 1
                vc.newWallet["maxRange"] = 2500
                
                if vc.node.network == "testnet" {
                    
                    if vc.isBIP84 {
                        
                        vc.newWallet["derivation"] = "m/84'/1'/0'"
                        vc.derivation = "BIP84 m/84'/1'/0'"
                        
                    } else if vc.isBIP49 {
                        
                        vc.newWallet["derivation"] = "m/49'/1'/0'"
                        vc.derivation = "BIP49 m/49'/1'/0'"
                        
                    } else if vc.isBIP44 {
                        
                        vc.newWallet["derivation"] = "m/44'/1'/0'"
                        vc.derivation = "BIP44 m/44'/1'/0'"
                        
                    }
                    
                } else if vc.node.network == "mainnet" {
                    
                    if vc.isBIP84 {
                        
                        vc.newWallet["derivation"] = "m/84'/0'/0'"
                        vc.derivation = "BIP84 m/84'/0'/0'"
                        
                    } else if vc.isBIP49 {
                        
                        vc.newWallet["derivation"] = "m/49'/0'/0'"
                        vc.derivation = "BIP49 m/44'/0'/0'"
                        
                    } else if vc.isBIP44 {
                        
                        vc.newWallet["derivation"] = "m/44'/0'/0'"
                        vc.derivation = "BIP44 m/44'/0'/0'"
                        
                    }
                    
                }
                
                vc.newWallet["birthdate"] = keyBirthday()
                vc.id = UUID()
                vc.newWallet["id"] = vc.id
                vc.newWallet["isActive"] = false
                vc.newWallet["lastUsed"] = Date()
                vc.newWallet["lastBalance"] = 0.0
                vc.newWallet["isArchived"] = false
                vc.newWallet["nodeId"] = vc.node.id
                                
                if vc.isMultiSig {
                    
                    vc.newWallet["type"] = "MULTI"
                    vc.createMultiSig()
                    
                } else if vc.isSingleSig {
                    
                    vc.newWallet["type"] = "DEFAULT"
                    vc.createSingleSig()
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "no active node")
                
            }
            
        }
        
    }
    
    func createSingleSig() {
        print("create single sig")
        
        let keyCreator = KeychainCreator()
        keyCreator.createKeyChain() { [unowned vc = self] (mnemonic, error) in
            
            if !error {
                
                let dataToEncrypt = mnemonic!.dataUsingUTF8StringEncoding
                vc.enc.encryptData(dataToEncrypt: dataToEncrypt) { (encryptedData, error) in
                    
                    if !error {
                        
                        vc.newWallet["seed"] = encryptedData!
                        vc.constructSingleSigPrimaryDescriptor(wallet: WalletStruct(dictionary: vc.newWallet))
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: "error encrypting your seed")
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func constructSingleSigPrimaryDescriptor(wallet: WalletStruct) {
        
        let keyFetcher = KeyFetcher()
        keyFetcher.xpub(wallet: wallet) { [unowned vc = self] (xpub, error) in
            
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
                                    vc.newWallet["descriptor"] = primaryDescriptor
                                    let digest = SHA256.hash(data: primaryDescriptor.dataUsingUTF8StringEncoding)
                                    let stringHash = digest.map { String(format: "%02hhx", $0) }.joined()
                                    vc.newWallet["name"] = stringHash
                                    vc.constructSingleSigChangeDescriptor(wallet: WalletStruct(dictionary: vc.newWallet))
                                    
                                }
                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: reducer.errorDescription)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error fetching xpub")
                
            }
            
        }
        
    }
    
    func constructSingleSigChangeDescriptor(wallet: WalletStruct) {
        
        let keyFetcher = KeyFetcher()
        keyFetcher.xpub(wallet: wallet) { [unowned vc = self] (xpub, error) in
            
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
                                    vc.newWallet["changeDescriptor"] = changeDescriptor
                                    vc.createSingleSigWallet()
                                    
                                }
                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: reducer.errorDescription)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error fetching xpub")
                
            }
            
        }
        
    }
    
    func createSingleSigWallet() {
        
        let walletCreator = WalletCreator()
        walletCreator.walletDict = newWallet
        walletCreator.createStandUpWallet() { [unowned vc = self] (success, errorDescription) in
            
            if success {
                
                let walletSaver = WalletSaver()
                walletSaver.save(walletToSave: vc.newWallet) { (success) in
                    
                    if success {
                        
                        vc.creatingView.removeConnectingView()
                        let w = WalletStruct(dictionary: vc.newWallet)
                        
                        let encryptedMnemonic = w.seed
                        vc.enc.decryptData(dataToDecrypt: encryptedMnemonic) { (mnemonic) in
                            
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
                                                                
                                                                vc.backUpRecoveryPhrase = words
                                                                vc.recoveryQr = json
                                                                vc.performSegue(withIdentifier: "walletCreated", sender: vc)
                                                                
                                                            }
                                                            
                                                        } else {
                                                            
                                                            vc.creatingView.removeConnectingView()
                                                            displayAlert(viewController: vc, isError: true, message: "error converting to json")
                                                            
                                                        }
                                                        
                                                    } else {
                                                        
                                                        vc.creatingView.removeConnectingView()
                                                        displayAlert(viewController: vc, isError: true, message: "error deriving xprv")
                                                        
                                                    }
                                                    
                                                } catch {
                                                    
                                                    vc.creatingView.removeConnectingView()
                                                    displayAlert(viewController: vc, isError: true, message: "error deriving xprv")
                                                    
                                                }
                                                
                                            } else {
                                                
                                                vc.creatingView.removeConnectingView()
                                                displayAlert(viewController: vc, isError: true, message: "error deriving bip32path")
                                                
                                            }
                                            
                                        } else {
                                            
                                            vc.creatingView.removeConnectingView()
                                            displayAlert(viewController: vc, isError: true, message: "error deriving master key")
                                            
                                        }
                                                                                
                                    } else {
                                        
                                        vc.creatingView.removeConnectingView()
                                        displayAlert(viewController: vc, isError: true, message: "error deriving bip39mnemonic")
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: "error decrypting seed")
                                
                            }
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: "There was an error saving your wallet")
                        
                    }
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "There was an error creating your wallet: \(errorDescription!)")
                
            }
            
        }
        
    }
    
    func createMultiSig() {
        
        let keychainCreator = KeychainCreator()
        keychainCreator.createKeyChain { [unowned vc = self] (mnemonic, error) in
            
            if !error {
                
                let derivation = vc.newWallet["derivation"] as! String
                vc.backUpRecoveryPhrase = mnemonic!
                let mnemonicCreator = MnemonicCreator()
                mnemonicCreator.convert(words: vc.backUpRecoveryPhrase) { (mnemonic, error) in
                    
                    if !error {
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivation)) {
                            
                            let recoveryFingerPrint = masterKey.fingerprint.hexString
                            vc.fingerprints.append(recoveryFingerPrint)
                            
                            if let path = BIP32Path(derivation) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    vc.recoveryPubkey = account.xpub
                                    vc.publickeys.append(self.recoveryPubkey)
                                    vc.createLocalKey()
                                    
                                } catch {
                                    
                                    vc.creatingView.removeConnectingView()
                                    displayAlert(viewController: vc, isError: true, message: "failed deriving xpub")
                                    
                                }
                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: "failed initiating bip32 path")
                                
                            }
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            displayAlert(viewController: vc, isError: true, message: "failed creating masterkey")
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: "error getting xpub from your recovery key")
                        
                    }
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error creating your recovery key")
                
            }
            
        }
        
    }
    
    func createLocalKey() {
        print("createLocalKey")
        
        let keychainCreator = KeychainCreator()
        keychainCreator.createKeyChain { [unowned vc = self] (words, error) in
            
            if !error {
                
                let unencryptedSeed = words!.dataUsingUTF8StringEncoding
                let enc = Encryption.sharedInstance
                enc.encryptData(dataToEncrypt: unencryptedSeed) { (encryptedSeed, error) in
                    
                    if !error {
                        
                        vc.localSeed = encryptedSeed!
                        let converter = MnemonicCreator()
                        converter.convert(words: words!) { (mnemonic, error) in
                            
                            if !error {
                                
                                vc.entropy = mnemonic!.entropy.description
                                let derivation = vc.newWallet["derivation"] as! String
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivation)) {
                                    
                                    let localFingerPrint = masterKey.fingerprint.hexString
                                    vc.fingerprints.append(localFingerPrint)
                                                                        
                                    if let path = BIP32Path(derivation) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            vc.publickeys.append(account.xpub)
                                            
                                            if account.xpriv != nil {
                                                
                                                vc.localXprv = account.xpriv!
                                                vc.createNodesKey()
                                                
                                            } else {
                                                
                                                vc.creatingView.removeConnectingView()
                                                displayAlert(viewController: vc, isError: true, message: "failed deriving local xpriv")
                                                
                                            }
                                            
                                        } catch {
                                            
                                            vc.creatingView.removeConnectingView()
                                            displayAlert(viewController: vc, isError: true, message: "failed deriving xpub")
                                            
                                        }
                                        
                                    } else {
                                        
                                        vc.creatingView.removeConnectingView()
                                        displayAlert(viewController: vc, isError: true, message: "failed initiating bip32 path")
                                        
                                    }
                                    
                                } else {
                                    
                                    vc.creatingView.removeConnectingView()
                                    displayAlert(viewController: vc, isError: true, message: "failed creating masterkey")
                                    
                                }
                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: "error converting your words to BIP39 mnmemonic")
                                
                            }
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: "error encrypting data")
                        
                    }
                    
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error creating your recovery key")
                
            }
            
        }
        
    }
    
    func createNodesKey() {
        print("createNodesKey")
        
        let keychainCreator = KeychainCreator()
        keychainCreator.createKeyChain { [unowned vc = self] (words, error) in
            
            if !error {
                
                let converter = MnemonicCreator()
                converter.convert(words: words!) { (mnemonic, error) in
                    
                    if !error {
                        
                        let derivation = vc.newWallet["derivation"] as! String
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network(path: derivation)) {
                            
                            let nodesFingerPrint = masterKey.fingerprint.hexString
                            vc.fingerprints.append(nodesFingerPrint)
                            
                            if let path = BIP32Path(derivation) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    vc.publickeys.append(account.xpub)
                                    
                                    if account.xpriv != nil {
                                        
                                        vc.nodesSeed = account.xpriv!
                                        vc.constructDescriptor(derivation: derivation)
                                        
                                    } else {
                                        
                                        vc.creatingView.removeConnectingView()
                                        displayAlert(viewController: vc, isError: true, message: "failed deriving node's xprv")
                                        
                                    }
                                    
                                    
                                } catch {
                                    
                                    vc.creatingView.removeConnectingView()
                                    displayAlert(viewController: vc, isError: true, message: "failed deriving xpub")
                                    
                                }
                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: "failed initiating bip32 path")
                                
                            }
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            displayAlert(viewController: vc, isError: true, message: "failed creating masterkey")
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: "error converting your words to BIP39 mnmemonic")
                        
                    }
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error encrypting data")
                
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
        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryDescriptor)\"") { [unowned vc = self] in
            
            if !reducer.errorBool {
                
                if let result = reducer.dictToReturn {
                    
                    if let primaryDescriptor = result["descriptor"] as? String {
                        
                        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDescriptor)\"") {
                            
                            DispatchQueue.main.async {
                                
                                vc.creatingView.label.text = "importing your descriptors to your node"
                                
                            }
                            
                            if let result = reducer.dictToReturn {
                                
                                if let changeDesc = result["descriptor"] as? String {
                                    
                                    let enc = Encryption.sharedInstance
                                    enc.getNode { (node, error) in
                                        
                                        if !error {
                                            
                                            vc.newWallet["descriptor"] = primaryDescriptor
                                            vc.newWallet["changeDescriptor"] = changeDesc
                                            vc.newWallet["seed"] = self.localSeed
                                            let digest = SHA256.hash(data: primaryDescriptor.dataUsingUTF8StringEncoding)
                                            let stringHash = digest.map { String(format: "%02hhx", $0) }.joined()
                                            vc.newWallet["name"] = stringHash
                                            
                                            let multiSigCreator = CreateMultiSigWallet()
                                            let wallet = WalletStruct(dictionary: vc.newWallet)
                                            multiSigCreator.create(wallet: wallet, nodeXprv: vc.nodesSeed, nodeXpub: vc.publickeys[2]) { (success, error) in
                                                
                                                if success {
                                                    
                                                    DispatchQueue.main.async {
                                                        
                                                       vc.creatingView.label.text = "saving your wallet to your device"
                                                        
                                                    }
                                                    
                                                    let walletSaver = WalletSaver()
                                                    walletSaver.save(walletToSave: vc.newWallet) { (success) in
                                                        
                                                        if success {
                                                            
                                                            vc.creatingView.removeConnectingView()
                                                            
                                                            DispatchQueue.main.async {
                                                                
                                                                //self.nodesSeed = ""
                                                                //self.newWallet.removeAll()
                                                                // include the checksum as we will convert this back to a pubkey descriptor when recovering
                                                                let hotDescriptor = primaryDescriptor.replacingOccurrences(of: vc.publickeys[1], with: vc.localXprv)
                                                                let recoveryQr = ["entropy": vc.entropy, "descriptor":"\(hotDescriptor)", "birthdate":wallet.birthdate, "blockheight":wallet.blockheight, "label":""] as [String : Any]
                                                                
                                                                if let json = recoveryQr.json() {
                                                                    
                                                                    DispatchQueue.main.async {
                                                                        
                                                                        vc.recoveryQr = json
                                                                        vc.performSegue(withIdentifier: "walletCreated", sender: vc)
                                                                        
                                                                    }
                                                                    
                                                                }
                                                                
                                                            }
                                                            
                                                        } else {
                                                            
                                                            vc.creatingView.removeConnectingView()
                                                            displayAlert(viewController: vc, isError: true, message: "error saving wallet")
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                } else {
                                                    
                                                    if error != nil {
                                                        
                                                        vc.creatingView.removeConnectingView()
                                                        displayAlert(viewController: vc, isError: true, message: "error creating wallet: \(error!)")
                                                        
                                                    } else {
                                                        
                                                        vc.creatingView.removeConnectingView()
                                                        displayAlert(viewController: vc, isError: true, message: "error creating wallet")
                                                        
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
                
                vc.recoveryPhrase = self.backUpRecoveryPhrase
                vc.recoveryQr = self.recoveryQr
                vc.wallet = self.newWallet
                
            }
            
        case "goRecover":
            
            if let vc = segue.destination as? WalletRecoverViewController {
                
                vc.onDoneBlock = { [unowned thisVc = self] result in
                    
                    DispatchQueue.main.async {
                        
                        thisVc.recoverDoneBlock!(true)
                        thisVc.navigationController!.popToRootViewController(animated: true)
                        
                    }                    
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }

}
