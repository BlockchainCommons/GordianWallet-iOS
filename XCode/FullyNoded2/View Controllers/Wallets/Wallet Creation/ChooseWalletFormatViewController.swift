//
//  ChooseWalletFormatViewController.swift
//  FullyNoded2
//
//  Created by Peter on 13/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class ChooseWalletFormatViewController: UIViewController, UINavigationControllerDelegate {
    
    var userSuppliedWords:BIP39Mnemonic?
    var userSuppliedMultiSigXpub = ""
    var userSuppliedMultiSigFingerprint = ""
    var id:UUID!
    var derivation = ""
    var recoveryQr = ""
    var walletName = ""
    var entropy = ""
    var localXprv = ""
    var node:NodeStruct!
    var walletToImport = [String:Any]()
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
    let creatingView = ConnectingView()
    var recoverDoneBlock : ((Bool) -> Void)?
    
    @IBOutlet var formatSwitch: UISegmentedControl!
    @IBOutlet var templateSwitch: UISegmentedControl!
    @IBOutlet var buttonOutlet: UIButton!
    @IBOutlet var seedDescription: UILabel!
    @IBOutlet var recoverWalletOutlet: UIButton!
    @IBOutlet weak var bip84Outlet: UILabel!
    @IBOutlet weak var bip49Outlet: UILabel!
    @IBOutlet weak var bip44Outlet: UILabel!
    @IBOutlet weak var customSeedSwitch: UISwitch!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        buttonOutlet.clipsToBounds = true
        buttonOutlet.layer.cornerRadius = 10
        recoverWalletOutlet.layer.cornerRadius = 10
        formatSwitch.selectedSegmentIndex = 0
        templateSwitch.selectedSegmentIndex = 0
        customSeedSwitch.isOn = false
        isBIP84 = true
        isMultiSig = false
        isSingleSig = true
        seedDescription.text = "Your device will hold one seed and your node will hold 5,000 public keys derived from the same seed.\n\nYour node will build unsigned PSBT's acting as a watch-only wallet and pass them to your device for offline signing."
        seedDescription.sizeToFit()
        
    }
    
    @IBAction func switchCustomSeedAction(_ sender: Any) {
        
        if customSeedSwitch.isOn {
            
            let alert = UIAlertController(title: "⚠︎ Advanced feature! ⚠︎", message: "Please proceed with caution, this feature is for advanced users only who completely understand the implications of what they are doing! This feature allows you to add your own BIP39 mnemonic, or xpub to use as the devices seed for the wallet you are about to create. If you add an xpub it will need to be the account xpub and you will need to supply a master key fingerprint, adding an xpub means the device will not be able to sign transactions and will be watch-only, you will have the option of adding a signer later if you would like to. If any of this does not make sense to you please disable this feature!", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    
    @IBAction func importAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "goImport", sender: vc)
            
        }
        
    }
    
    
    @IBAction func recoverAction(_ sender: Any) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "goRecover", sender: vc)
            
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
            
            isSingleSig = true
            isMultiSig = false
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.formatSwitch.setTitle("Bech32", forSegmentAt: 0)
                vc.formatSwitch.setTitle("Segwit Wrapped", forSegmentAt: 1)
                vc.formatSwitch.setTitle("Legacy", forSegmentAt: 2)
                vc.formatSwitch.setEnabled(true, forSegmentAt: 1)
                vc.formatSwitch.setEnabled(true, forSegmentAt: 2)
                vc.bip84Outlet.text = "BIP84"
                vc.bip44Outlet.alpha = 1
                vc.bip49Outlet.alpha = 1
                
                vc.seedDescription.text = "Your device will hold one seed and your node will hold 5,000 public keys derived from the same seed.\n\nYour node will build unsigned PSBT's acting as a watch-only wallet and pass them to your device for offline signing."
                
            }
            
        case 1:
            
            isMultiSig = true
            isSingleSig = false
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.formatSwitch.setTitle("Bech32", forSegmentAt: 0)
                vc.formatSwitch.setTitle("", forSegmentAt: 1)
                vc.formatSwitch.setTitle("", forSegmentAt: 2)
                vc.formatSwitch.setEnabled(true, forSegmentAt: 0)
                vc.formatSwitch.setEnabled(false, forSegmentAt: 1)
                vc.formatSwitch.setEnabled(false, forSegmentAt: 2)
                vc.bip84Outlet.text = "WIP48"
                vc.bip44Outlet.alpha = 0
                vc.bip49Outlet.alpha = 0
                
                vc.seedDescription.text = "Your device will hold one seed, your node will hold 5,000 private keys derived from a second seed, and you will securely store one seed offline for recovery purposes.\n\nYour node will create PSBT's and sign them with one key, passing the partially signed PSBT's to your device which will sign the PSBT's with the second key."
                
                    
                let alert = UIAlertController(title: "We now support \"WIP48\" which is a Wallet Improvement Proposal for HD multi-sig wallets", message: "Other popular wallets such as Electrum, Coldcard, CoPay, and Specter also support this cross platform HD multisig wallet derivation making using multiple devices/apps/hardware wallets with multisig and PSBT easier then ever. The path that will be used for mainnet is m/48'/0'/0'/2'/0 and testnet m/48'/1'/0'/2'/0", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
                alert.popoverPresentationController?.sourceView = vc.view
                vc.present(alert, animated: true, completion: nil)
                    
                
            }
            
        default:
            
            break
            
        }
                
    }
    
    @IBAction func createAction(_ sender: Any) {
        
        if customSeedSwitch.isOn {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.performSegue(withIdentifier: "addSeedSegue", sender: vc)
                
            }
            
        } else {
            
            Encryption.getNode { [unowned vc = self] (node, error) in
                
                if !error && node != nil {
                    
                    vc.node = node!
                    vc.creatingView.addConnectingView(vc: self.navigationController!, description: "creating your wallet")
                    
                    Reducer.makeCommand(walletName: "", command: .getblockcount, param: "") { (object, errorDescription) in
                        
                        if let blockheight = object as? Int {
                            
                            vc.newWallet["blockheight"] = Int32(blockheight)
                            vc.newWallet["maxRange"] = 2500
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
                                
                                if vc.node.network == "testnet" {
                                    
                                    vc.newWallet["derivation"] = "m/48'/1'/0'/2'"
                                    vc.derivation = "WIP48 m/48'/1'/0'/2'"
                                    
                                } else if vc.node.network == "mainnet" {
                                    
                                    vc.newWallet["derivation"] = "m/48'/0'/0'/2'"
                                    vc.derivation = "WIP48 m/48'/0'/0'/2'"
                                    
                                }
                                
                                vc.createMultiSig()
                                
                            } else if vc.isSingleSig {
                                
                                vc.newWallet["type"] = "DEFAULT"
                                
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
                                
                                vc.createSingleSig()
                                
                            }
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            displayAlert(viewController: vc, isError: true, message: "error fetching blockheight: \(errorDescription ?? "unknown error")")
                            
                        }
                        
                    }
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "no active node")
                    
                }
                
            }
            
        }
        
    }
    
    private func updateStatus(text: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.creatingView.label.text = text
            
        }
        
    }
    
    func createSingleSig() {
        print("create single sig")
        
        updateStatus(text: "creating device's seed")
        
        KeychainCreator.createKeyChain() { [unowned vc = self] (mnemonic, error) in
            
            if !error {
                
                vc.updateStatus(text: "encrypting device's seed")
                
                let dataToEncrypt = mnemonic!.dataUsingUTF8StringEncoding
                Encryption.encryptData(dataToEncrypt: dataToEncrypt) { (encryptedData, error) in
                    
                    if !error {
                        
                        vc.updateStatus(text: "creating primary descriptor")
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
        
        KeyFetcher.xpub(wallet: wallet) { [unowned vc = self] (xpub, error) in
            
            if !error {
                
                KeyFetcher.fingerprint(wallet: wallet) { (fingerprint, error) in
                    
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
                        
                        Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) { (object, errorDesc) in
                            
                            if let dict = object as? NSDictionary {
                                
                                let primaryDescriptor = dict["descriptor"] as! String
                                vc.newWallet["descriptor"] = primaryDescriptor
                                vc.newWallet["name"] = Encryption.sha256hash(primaryDescriptor)
                                vc.updateStatus(text: "creating change descriptor")
                                vc.constructSingleSigChangeDescriptor(wallet: WalletStruct(dictionary: vc.newWallet))
                                                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                                
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
        
        KeyFetcher.xpub(wallet: wallet) { [unowned vc = self] (xpub, error) in
            
            if !error {
                
                KeyFetcher.fingerprint(wallet: wallet) { (fingerprint, error) in
                    
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
                        
                        Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) { (object, errorDesc) in
                            
                            if let dict = object as? NSDictionary {
                                
                                let changeDescriptor = dict["descriptor"] as! String
                                vc.newWallet["changeDescriptor"] = changeDescriptor
                                vc.updateStatus(text: "creating the wallet on your node")
                                vc.createSingleSigWallet()
                                                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                                
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
        
        let walletCreator = WalletCreator.sharedInstance
        walletCreator.createStandUpWallet(walletDict: newWallet) { [unowned vc = self] (success, errorDescription) in
            
            if success {
                
                vc.updateStatus(text: "saving the wallet to your device")
                
                CoreDataService.saveEntity(dict: vc.newWallet, entityName: .wallets) { (success, errorDescription) in
                    
                    if success {
                        
                        let w = WalletStruct(dictionary: vc.newWallet)
                        let encryptedMnemonic = w.seed
                        Encryption.decryptData(dataToDecrypt: encryptedMnemonic) { (mnemonic) in
                            
                            if mnemonic != nil {
                                
                                if let words = String(data: mnemonic!, encoding: .utf8) {
                                    
                                    if let bip39mnemonic = BIP39Mnemonic(words) {
                                        
                                        let seed = bip39mnemonic.seedHex()
                                        
                                        if let mk = HDKey(seed, network(descriptor: w.descriptor)) {
                                            
                                            if let path = BIP32Path(w.derivation) {
                                                
                                                do {
                                                    
                                                    if let xprv = try mk.derive(path).xpriv {
                                                        
                                                        let p = DescriptorParser()
                                                        let str = p.descriptor(w.descriptor)
                                                        let hotDesc = (w.descriptor).replacingOccurrences(of: str.accountXpub, with: xprv)
                                                        let recoveryQr = ["entropy": bip39mnemonic.entropy.description, "descriptor":"\(hotDesc)", "birthdate":w.birthdate, "blockheight":w.blockheight,"label":""] as [String : Any]
                                                        
                                                        if let json = recoveryQr.json() {
                                                            
                                                            DispatchQueue.main.async {
                                                                vc.creatingView.removeConnectingView()
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
                        displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error saving wallet")
                        
                    }
                    
                }
                
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "There was an error creating your wallet: \(errorDescription!)")
                
            }
            
        }
        
    }
    
    func createMultiSig() {
        
        updateStatus(text: "creating offline seed")
        
        KeychainCreator.createKeyChain { [unowned vc = self] (mnemonic, error) in
            
            if !error {
                
                let derivation = vc.newWallet["derivation"] as! String
                vc.backUpRecoveryPhrase = mnemonic!
                let mnemonicCreator = MnemonicCreator()
                mnemonicCreator.convert(words: vc.backUpRecoveryPhrase) { (mnemonic, error) in
                    
                    if !error {
                        
                        var network:Network!
                        if vc.node.network == "testnet" {
                            network = .testnet
                        } else {
                            network = .mainnet
                        }
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network) {
                            
                            let recoveryFingerPrint = masterKey.fingerprint.hexString
                            vc.fingerprints.append(recoveryFingerPrint)
                            
                            if let path = BIP32Path(derivation) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    vc.recoveryPubkey = account.xpub
                                    vc.publickeys.append(vc.recoveryPubkey)
                                    
                                    /// User supplied a custom xpub to create the multisig quorum with
                                    if vc.userSuppliedMultiSigXpub != "" {
                                        
                                        vc.fingerprints.append(vc.userSuppliedMultiSigFingerprint)
                                        vc.publickeys.append(vc.userSuppliedMultiSigXpub)
                                        vc.nodesSeed = vc.userSuppliedMultiSigXpub
                                        vc.createNodesKey()
                                        
                                    /// This will be for user supplied words in the multisig qourum
                                    } else if vc.userSuppliedWords != nil {
 
                                         
 
                                    } else {
                                        
                                        vc.createLocalKey()
                                        
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
        
        updateStatus(text: "creating device's seed")
        
        KeychainCreator.createKeyChain { [unowned vc = self] (words, error) in
            
            if !error {
                
                let unencryptedSeed = words!.dataUsingUTF8StringEncoding
                Encryption.encryptData(dataToEncrypt: unencryptedSeed) { (encryptedSeed, error) in
                    
                    if !error {
                        
                        vc.localSeed = encryptedSeed!
                        let converter = MnemonicCreator()
                        converter.convert(words: words!) { (mnemonic, error) in
                            
                            if !error {
                                
                                vc.entropy = mnemonic!.entropy.description
                                let derivation = vc.newWallet["derivation"] as! String
                                var network:Network!
                                if vc.node.network == "testnet" {
                                    network = .testnet
                                } else {
                                    network = .mainnet
                                }
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), network) {
                                    
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
        
        updateStatus(text: "creating node's seed")
        
        KeychainCreator.createKeyChain { [unowned vc = self] (words, error) in
            
            if !error {
                
                let converter = MnemonicCreator()
                converter.convert(words: words!) { (mnemonic, error) in
                    
                    if !error {
                        
                        let derivation = vc.newWallet["derivation"] as! String
                        
                        var network:Network!
                        if vc.node.network == "testnet" {
                            network = .testnet
                        } else {
                            network = .mainnet
                        }
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), network) {
                            
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
        
        updateStatus(text: "creating primary descriptor")
        
        let recoveryKey = publickeys[0]
        let localKey = publickeys[1]
        let nodeKey = publickeys[2]
        let recoveryFingerprint = fingerprints[0]
        let localFingerprint = fingerprints[1]
        let nodeFingerprint = fingerprints[2]
        let signatures = 2
        var changeDescriptor = ""
        
        switch derivation {
            
            //fe23bc9a/48h/1h/0h/2h
            
        case "m/48'/1'/0'/2'":
                                            
            descriptor = "wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/48'/1'/0'/2']\(recoveryKey)/0/*, [\(localFingerprint)/48'/1'/0'/2']\(localKey)/0/*, [\(nodeFingerprint)/48'/1'/0'/2']\(nodeKey)/0/*))"

            changeDescriptor = "wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/48'/1'/0'/2']\(recoveryKey)/1/*, [\(localFingerprint)/48'/1'/0'/2']\(localKey)/1/*, [\(nodeFingerprint)/48'/1'/0'/2']\(nodeKey)/1/*))"
            
        case "m/48'/0'/0'/2'":

            descriptor = "wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/48'/0'/0'/2']\(recoveryKey)/0/*, [\(localFingerprint)/48'/0'/0'/2']\(localKey)/0/*, [\(nodeFingerprint)/48'/0'/0'/2']\(nodeKey)/0/*))"
            
            changeDescriptor = "wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/48'/0'/0'/2']\(recoveryKey)/1/*, [\(localFingerprint)/48'/0'/0'/2']\(localKey)/1/*, [\(nodeFingerprint)/48'/0'/0'/2']\(nodeKey)/1/*))"

//        case "m/44'/1'/0'":
//
//            descriptor = "sh(sortedmulti(\(signatures),[\(recoveryFingerprint)/44'/1'/0']\(recoveryKey)/0/*, [\(localFingerprint)/44'/1'/0']\(localKey)/0/*, [\(nodeFingerprint)/44'/1'/0']\(nodeKey)/0/*))"
//
//            changeDescriptor = "sh(sortedmulti(\(signatures),[\(recoveryFingerprint)/44'/1'/0']\(recoveryKey)/1/*, [\(localFingerprint)/44'/1'/0']\(localKey)/1/*, [\(nodeFingerprint)/44'/1'/0']\(nodeKey)/1/*))"
//
//        case "m/44'/0'/0'":
//
//            descriptor = "sh(sortedmulti(\(signatures),[\(recoveryFingerprint)/44'/0'/0']\(recoveryKey)/0/*, [\(localFingerprint)/44'/0'/0']\(localKey)/0/*, [\(nodeFingerprint)/44'/0'/0']\(nodeKey)/0/*))"
//
//            changeDescriptor = "sh(sortedmulti(\(signatures),[\(recoveryFingerprint)/44'/0'/0']\(recoveryKey)/1/*, [\(localFingerprint)/44'/0'/0']\(localKey)/1/*, [\(nodeFingerprint)/44'/0'/0']\(nodeKey)/1/*))"
//
//        case "m/49'/1'/0'":
//
//            descriptor = "sh(wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/49'/1'/0']\(recoveryKey)/0/*, [\(localFingerprint)/49'/1'/0']\(localKey)/0/*, [\(nodeFingerprint)/49'/1'/0']\(nodeKey)/0/*)))"
//
//            changeDescriptor = "sh(wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/49'/1'/0']\(recoveryKey)/1/*, [\(localFingerprint)/49'/1'/0']\(localKey)/1/*, [\(nodeFingerprint)/49'/1'/0']\(nodeKey)/1/*)))"
//
//        case "m/49'/0'/0'":
//
//            descriptor = "sh(wsh(multi(\(signatures),[\(recoveryFingerprint)/49'/0'/0']\(recoveryKey)/0/*, [\(localFingerprint)/49'/0'/0']\(localKey)/0/*, [\(nodeFingerprint)/49'/0'/0']\(nodeKey)/0/*)))"
//
//            changeDescriptor = "sh(wsh(multi(\(signatures),[\(recoveryFingerprint)/49'/0'/0']\(recoveryKey)/1/*, [\(localFingerprint)/49'/0'/0']\(localKey)/1/*, [\(nodeFingerprint)/49'/0'/0']\(nodeKey)/1/*)))"
            
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
        
        Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryDescriptor)\"") { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSDictionary {
                
                if let primaryDescriptor = result["descriptor"] as? String {
                    
                    vc.updateStatus(text: "creating change descriptor")
                    
                    Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDescriptor)\"") { (object, errorDesc) in
                        
                        DispatchQueue.main.async {
                            
                            vc.creatingView.label.text = "importing your descriptors to your node"
                            
                        }
                        
                        if let result = object as? NSDictionary {
                            
                            if let changeDesc = result["descriptor"] as? String {
                                
                                Encryption.getNode { [unowned vc = self] (node, error) in
                                    
                                    if !error {
                                        
                                        vc.newWallet["descriptor"] = primaryDescriptor
                                        vc.newWallet["changeDescriptor"] = changeDesc
                                        if vc.localSeed != nil {
                                            vc.newWallet["seed"] = vc.localSeed
                                        }
                                        vc.newWallet["name"] = Encryption.sha256hash(primaryDescriptor)
                                        
                                        let multiSigCreator = CreateMultiSigWallet.sharedInstance
                                        let wallet = WalletStruct(dictionary: vc.newWallet)
                                        multiSigCreator.create(wallet: wallet, nodeXprv: vc.nodesSeed, nodeXpub: vc.publickeys[2]) { (success, error) in
                                            
                                            if success {
                                                
                                                DispatchQueue.main.async {
                                                    
                                                    vc.creatingView.label.text = "saving your wallet to your device"
                                                    
                                                }
                                                
                                                CoreDataService.saveEntity(dict: vc.newWallet, entityName: .wallets) { (success, errorDescription) in
                                                    
                                                    if success {
                                                        
                                                        vc.creatingView.removeConnectingView()
                                                        
                                                        DispatchQueue.main.async {
                                                            
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
                                                        displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error saving wallet")
                                                        
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
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: "error getting descriptor info: \(errorDesc ?? "unknown error"))")
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "error getting descriptor info: \(errorDesc ?? "unknown error"))")
                
            }
            
        }
        
    }
    
    private func processDescriptor(descriptor: String) {
        
        let cv = ConnectingView()
        cv.addConnectingView(vc: self, description: "processing descriptor")
        
        Encryption.getNode { [unowned vc = self] (n, error) in
            
            if n != nil {
                
                let p = DescriptorParser()
                let str = p.descriptor(descriptor)
                
                /// Currently we only support 2 of 3 bech32 Specter descriptors, can expand on this later.
                if descriptor.contains("&") && str.isMulti && descriptor.contains("wsh") && str.mOfNType == "2 of 3" {
                    
                    ///     An example descriptor from Specter, we need to convert it to HD and create the change descriptor:
                    ///     Key_123&wsh(sortedmulti(2,[fe23bc9a/48h/1h/0h/2h]tpubDEzBBGMH87CU5rCdo7gSaByN6SVvJW7c4WDkMuC6mKS8bcqpaVD3FCoiAEefcGhC4TwRCtACZnmnTZbPUk4cbx6dsLnHG8CyG8jz2Gr6j2z,
                    ///     [e120e47b/48h/1h/0h/2h]tpubDEvTHKHDhi8rQyogJNsnoNsbF8hMefbAzXFCT8CuJiZtxeZM7vUHcH65qpsp7teB2hJPQMKpLV9QcEJkNy3fvnvR6zckoN1E3fFywzfmcBA,
                    ///     [f0578536/48h/1h/0h/2h]tpubDE5GYE61m5mx2WrgtFe1kSAeAHT5Npoy5C2TpQTQGLTQkRkmsWMoA5PSP5XAkt4DBLgKY386iyGDjJKT5fVrRgShJ5CSEdd66UUc4icA8rw))
                    
                    let arr = descriptor.split(separator: "&")
                    let label = "\(arr[0])"
                    var primaryDesc = "\(arr[1])"
                    let arr1 = primaryDesc.split(separator: ",")
                    let key1 = "\(arr1[1])/0/*"
                    let key2 = "\(arr1[2])/0/*"
                    let key3 = "\(arr1[3])".replacingOccurrences(of: "))", with: "/0/*))")
                    primaryDesc = primaryDesc.replacingOccurrences(of: "\(arr1[1])", with: key1)
                    primaryDesc = primaryDesc.replacingOccurrences(of: "\(arr1[2])", with: key2)
                    primaryDesc = primaryDesc.replacingOccurrences(of: "\(arr1[3])", with: key3)
                    let changeDesc = primaryDesc.replacingOccurrences(of: "/0/*", with: "/1/*")
                    
                    Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(primaryDesc)\"") { [unowned vc = self] (object, errorDescription) in
                        
                        if let dict = object as? NSDictionary {
                            
                            let descriptor = dict["descriptor"] as! String
                            vc.walletToImport["descriptor"] = descriptor
                            vc.walletToImport["birthdate"] = keyBirthday()
                            vc.walletToImport["label"] = label
                            vc.walletToImport["nodeId"] = n!.id
                            vc.walletName = Encryption.sha256hash(descriptor)
                            vc.walletToImport["name"] = vc.walletName
                            vc.walletToImport["id"] = UUID()
                            vc.walletToImport["isArchived"] = false
                            vc.walletToImport["maxRange"] = 2500
                            vc.walletToImport["index"] = 0
                            vc.walletToImport["blockheight"] = 1
                            vc.walletToImport["lastUsed"] = Date()
                            vc.walletToImport["lastBalance"] = 0.0
                            vc.walletToImport["type"] = "MULTI"
                            
                            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(changeDesc)\"") { [unowned vc = self] (object, errorDescription) in
                                
                                if let dict = object as? NSDictionary {
                                    
                                    cv.removeConnectingView()
                                    let changeDescriptor = dict["descriptor"] as! String
                                    vc.walletToImport["changeDescriptor"] = changeDescriptor
                                    
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        
                                        vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                        
                                    }
                                    
                                } else {
                                    
                                    cv.removeConnectingView()
                                    showAlert(vc: vc, title: "Error", message: "error getting descriptor info: \(errorDescription ?? "unknown error")")
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            cv.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: "error getting descriptor info: \(errorDescription ?? "unknown error")")
                            
                        }
                        
                    }
                    
                } else {
                    
                    cv.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "We currently only support bech32, multisig descriptoras from Specter")
                    
                }
                
            } else {
                
                cv.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "You need to be connected to a node to import a wallet")
                
            }
            
        }
        
    }
    
    private func createWalletWithUserSuppliedSeed(dict: [String:String]) {
        
        creatingView.addConnectingView(vc: self.navigationController!, description: "creating your wallet")
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                vc.node = node!
                
                Reducer.makeCommand(walletName: "", command: .getblockcount, param: "") { (object, errorDescription) in
                    
                    if let blockheight = object as? Int {
                        
                        vc.newWallet["blockheight"] = Int32(blockheight)
                        vc.newWallet["maxRange"] = 2500
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
                            
                            if vc.node.network == "testnet" {
                                
                                vc.newWallet["derivation"] = "m/48'/1'/0'/2'"
                                vc.derivation = "WIP48 m/48'/1'/0'/2'"
                                
                            } else if vc.node.network == "mainnet" {
                                
                                vc.newWallet["derivation"] = "m/48'/0'/0'/2'"
                                vc.derivation = "WIP48 m/48'/0'/0'/2'"
                                
                            }
                            
                            vc.userSuppliedMultiSigXpub = dict["key"]!
                            vc.userSuppliedMultiSigFingerprint = dict["fingerprint"]!
                            vc.createMultiSig()
                            
                        } else if vc.isSingleSig {
                            
                            vc.newWallet["type"] = "DEFAULT"
                            
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
                            
                            vc.createCustomSingleSig(dict: dict)
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: "error fetching blockheight: \(errorDescription ?? "unknown error")")
                        
                    }
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "no active node")
                
            }
            
        }
        
    }
    
    
    private func createCustomSingleSig(dict: [String:String]) {
        
        let key = dict["key"]!
        if key.hasPrefix("xpub") || key.hasPrefix("tpub") {
            
            createCustomSingleSigPrimaryDescriptor(dict: dict)
            
        } else {
            
            let unencryptedXprv = key.dataUsingUTF8StringEncoding
            Encryption.encryptData(dataToEncrypt: unencryptedXprv) { [unowned vc = self] (encryptedData, error) in
                
                if encryptedData != nil {
                
                    vc.newWallet["xprv"] = encryptedData
                    vc.createCustomSingleSigPrimaryDescriptor(dict: dict)
                    
                }
                
            }
            
        }
        
    }
    
    private func createCustomSingleSigPrimaryDescriptor(dict: [String:String]) {
        
        let wallet = WalletStruct(dictionary: newWallet)
        var param = ""
        let key = dict["key"]!
        var xpub = ""
        
        if key.hasPrefix("xpub") || key.hasPrefix("tpub") {
            xpub = key
        } else {
            xpub = HDKey(dict["key"]!)!.xpub
        }
        
        let fingerprint = dict["fingerprint"]!
        
        switch wallet.derivation {
            
        case "m/84'/1'/0'":
            param = "\"wpkh([\(fingerprint)/84'/1'/0']\(xpub)/0/*)\""
            
        case "m/84'/0'/0'":
            param = "\"wpkh([\(fingerprint)/84'/0'/0']\(xpub)/0/*)\""
            
        case "m/44'/1'/0'":
            param = "\"pkh([\(fingerprint)/44'/1'/0']\(xpub)/0/*)\""
             
        case "m/44'/0'/0'":
            param = "\"pkh([\(fingerprint)/44'/0'/0']\(xpub)/0/*)\""
            
        case "m/49'/1'/0'":
            param = "\"sh(wpkh([\(fingerprint)/49'/1'/0']\(xpub)/0/*))\""
            
        case "m/49'/0'/0'":
            param = "\"sh(wpkh([\(fingerprint)/49'/0'/0']\(xpub)/0/*))\""
            
        default:
            
            break
            
        }
        
        Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSDictionary {
                
                let primaryDescriptor = result["descriptor"] as! String
                vc.newWallet["descriptor"] = primaryDescriptor
                vc.newWallet["name"] = Encryption.sha256hash(primaryDescriptor)
                vc.updateStatus(text: "creating change descriptor")
                vc.createCustomSingleSigChangeDescriptor(dict: dict)
                                                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                
            }
            
        }
        
    }
    
    private func createCustomSingleSigChangeDescriptor(dict: [String:String]) {
        
        let wallet = WalletStruct(dictionary: newWallet)
        let arr = (wallet.descriptor).split(separator: "#")
        let param = "\"\((arr[0]).replacingOccurrences(of: "/0/*", with: "/1/*"))\""
        Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSDictionary {
                
                let changeDescriptor = result["descriptor"] as! String
                vc.newWallet["changeDescriptor"] = changeDescriptor
                vc.updateStatus(text: "creating the wallet on your node")
                vc.createCustomSingleSigWallet(dict: dict)
                                                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                
            }
            
        }
        
    }
    
    private func createCustomSingleSigWallet(dict: [String:String]) {
        
        let walletCreator = WalletCreator.sharedInstance
        walletCreator.createStandUpWallet(walletDict: newWallet) { [unowned vc = self] (success, errorDescription) in
            
            if success {
                
                vc.updateStatus(text: "saving the wallet to your device")
                
                CoreDataService.saveEntity(dict: vc.newWallet, entityName: .wallets) { (success, errorDescription) in
                    
                    if success {
                        
                        let w = WalletStruct(dictionary: vc.newWallet)
                        let p = DescriptorParser()
                        let str = p.descriptor(w.descriptor)
                        let hotDesc = (w.descriptor).replacingOccurrences(of: str.accountXpub, with: dict["key"]!)
                        let recoveryQr = ["entropy": "", "descriptor":"\(hotDesc)", "birthdate":w.birthdate, "blockheight":w.blockheight,"label":""] as [String : Any]
                        
                        if let json = recoveryQr.json() {
                            
                            DispatchQueue.main.async {
                                vc.creatingView.removeConnectingView()
                                vc.backUpRecoveryPhrase = ""
                                vc.recoveryQr = json
                                vc.performSegue(withIdentifier: "walletCreated", sender: vc)
                                
                            }
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            displayAlert(viewController: vc, isError: true, message: "error converting to json")
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error saving wallet")
                        
                    }
                    
                }
                
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "There was an error creating your wallet: \(errorDescription!)")
                
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
                
                vc.onQrDoneBlock = { [unowned thisVc = self] result in
                    
                    DispatchQueue.main.async {
                        
                        thisVc.recoverDoneBlock!(true)
                        thisVc.navigationController!.popToRootViewController(animated: true)
                        
                    }                    
                    
                }
                
            }
            
        case "goImport":
            
            if let vc = segue.destination as? ScannerViewController {
                
                vc.isImporting = true
                vc.onImportDoneBlock = { [unowned thisVc = self] descriptor in
                    
                    thisVc.processDescriptor(descriptor: descriptor)
                    
                }
                
            }
            
        case "goConfirmImport":
            
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                
                vc.walletNameHash = walletName
                vc.isImporting = true
                vc.walletDict = walletToImport
                
            }
            
        case "addSeedSegue":
            
            if let vc = segue.destination as? AddExtendedKeyViewController {
                
                vc.onDoneBlock = { [unowned thisVc = self] dict in
                    
                    thisVc.createWalletWithUserSuppliedSeed(dict: dict)
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }

}
