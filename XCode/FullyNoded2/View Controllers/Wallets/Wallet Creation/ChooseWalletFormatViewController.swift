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
    
    var userSuppliedWords:String?
    var userSuppliedMultiSigXpub = ""
    var userSuppliedMultiSigFingerprint = ""
    var id:UUID!
    var derivation = ""
    var recoveryQr = ""
    var walletName = ""
    var localXprv = ""
    var node:NodeStruct!
    var walletToImport = [String:Any]()
    var newWallet = [String:Any]()
    var isMultiSig = Bool()
    var isSingleSig = Bool()
    var showAdvanced = Bool()
    var publickeys = [String]()
    var fingerprints = [String]()
    var localSeed:Data?
    var nodesSeed = ""
    var nodesWords = ""
    var nodesHdSeed = ""
    var descriptor = ""
    var recoveryPubkey = ""
    var backUpRecoveryPhrase = ""
    var walletDoneBlock : ((Bool) -> Void)?
    var multiSigDoneBlock : (((success: Bool, recoveryPhrase: String, descriptor: String)) -> Void)?
    let creatingView = ConnectingView()
    var recoverDoneBlock : ((Bool) -> Void)?
    let advancedButton = UIButton()
    
    @IBOutlet var recoverWalletOutlet: UIButton!
    @IBOutlet weak var customSeedSwitch: UISwitch!
    @IBOutlet weak var hotWalletOutlet: UIButton!
    @IBOutlet weak var warmWalletOutlet: UIButton!
    @IBOutlet weak var coolWalletOutlet: UIButton!
    @IBOutlet weak var coldWalletOutlet: UIButton!
    @IBOutlet weak var customSeedLabel: UILabel!
    @IBOutlet weak var coolInfoOutlet: UIButton!
    @IBOutlet weak var coldInfoOutlet: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showAdvanced = false
        navigationController?.delegate = self
        recoverWalletOutlet.layer.cornerRadius = 10
        hotWalletOutlet.layer.cornerRadius = 8
        warmWalletOutlet.layer.cornerRadius = 8
        coolWalletOutlet.layer.cornerRadius = 8
        coldWalletOutlet.layer.cornerRadius = 8
        customSeedSwitch.isOn = false
        customSeedSwitch.alpha = 0
        customSeedLabel.alpha = 0
        coolInfoOutlet.alpha = 0
        coldInfoOutlet.alpha = 0
        coolWalletOutlet.alpha = 0
        coldWalletOutlet.alpha = 0
        showAdvancedOptions()
        
    }
    
    private func showAdvancedOptions() {
        
        advancedButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        advancedButton.addTarget(self, action: #selector(show(_:)), for: .touchUpInside)
        advancedButton.tintColor = .white
        
        if showAdvanced {
            
            let hideImage = UIImage(systemName: "rectangle.compress.vertical")
            advancedButton.setImage(hideImage, for: .normal)
            
        } else {
            
            let expandImage = UIImage(systemName: "rectangle.expand.vertical")
            advancedButton.setImage(expandImage, for: .normal)
            
        }
       
       let rightButton = UIBarButtonItem(customView: advancedButton)
       
       self.navigationItem.setRightBarButtonItems([rightButton], animated: true)
        
    }
    
    @objc func show(_ sender: Any) {
        
        if showAdvanced {
            customSeedSwitch.isOn = false
            UIView.animate(withDuration: 0.2) { [unowned vc = self] in
                vc.customSeedSwitch.alpha = 0
                vc.customSeedLabel.alpha = 0
                vc.coolWalletOutlet.alpha = 0
                vc.coldWalletOutlet.alpha = 0
                vc.coolInfoOutlet.alpha = 0
                vc.coldInfoOutlet.alpha = 0
            }
            
        } else {
            UIView.animate(withDuration: 0.2) { [unowned vc = self] in
                vc.customSeedSwitch.alpha = 1
                vc.customSeedLabel.alpha = 1
                vc.coolWalletOutlet.alpha = 1
                vc.coldWalletOutlet.alpha = 1
                vc.coolInfoOutlet.alpha = 1
                vc.coldInfoOutlet.alpha = 1
            }
            
        }
        
        showAdvanced = !showAdvanced
        showAdvancedOptions()
        
    }
    
    @IBAction func hotInfo(_ sender: Any) {
        let alert = UIAlertController(title: "Hot self sovereign single signature account", message: " A master seed is held by your device and your node holds a watch-only key set. This is a live account meaning you can spend from it at anytime from your device.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
        alert.popoverPresentationController?.sourceView = self.view
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func warmInfo(_ sender: Any) {
        let alert = UIAlertController(title: "Warm self sovereign 2 of 3 multi signature account", message: "One master seed is held by your device, the other two are held offline by you. We derive and import a key set into your node from one of your offline master seeds so that your node can be the second signer for this account. This adds a layer of security and redundancy in case you lost your node, device or offline seed storage. This a warm account as neither your device or your node can spend independently. In order to spend from this account your device will need to be connected to your node!", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
        alert.popoverPresentationController?.sourceView = self.view
        self.present(alert, animated: true, completion: nil)
                    
    }
    
    @IBAction func coolWalletInfo(_ sender: Any) {
        let alert = UIAlertController(title: "Cool self sovereign 2 of 3 multi signature account", message: "You will need to supply an xpub which will represent the devices master key. We will create two offline master seeds for you to backup, they will NOT be saved by the device. One of these master seeds will be used to derive a key set and import it into your node so that your node can be a single signer. Cool accounts are not capable of spending on their own! Cool accounts will build unsigned transactions and allow you to export them as PSBT's to other devices for signing. This is an ideal account type for collaborative multisig. You will always have the option to convert it to a warm account by adding a master seed in the form of BIP39 words to it.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
        alert.popoverPresentationController?.sourceView = self.view
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func coldWalletInfo(_ sender: Any) {
        let alert = UIAlertController(title: "Cold self sovereign single signature account", message: "Cold accounts are single signature accounts where you will supply a master key xpub which is held by the device. The account will be purely watch-only and you will not be able to spend from it with this device. It will create unsigned transactions that can be exported to offline signers as PSBT's. You will always have the option to make it hot by adding a master seed to it in the form of BIP39 words.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
        alert.popoverPresentationController?.sourceView = self.view
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func createHotWallet(_ sender: Any) {
        isSingleSig = true
        isMultiSig = false
        createNow()
                
    }
    
    @IBAction func createWarmWallet(_ sender: Any) {
        isMultiSig = true
        isSingleSig = false
        createNow()
        
    }
    
    //addCustomWords
    @IBAction func createCoolWallet(_ sender: Any) {
        customSeedSwitch.isOn = false
        isSingleSig = false
        isMultiSig = true
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "addXpubSegue", sender: vc)
            
        }
        
    }
    
    @IBAction func createColdWallet(_ sender: Any) {
        customSeedSwitch.isOn = false
        isSingleSig = true
        isMultiSig = false
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.performSegue(withIdentifier: "addXpubSegue", sender: vc)
            
        }
    }
    
    
    private func createNow() {
        
        if customSeedSwitch.isOn {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.performSegue(withIdentifier: "addCustomWords", sender: vc)
                
            }
            
        } else {
            
            Encryption.getNode { [unowned vc = self] (node, error) in
                
                if !error && node != nil {
                    
                    vc.node = node!
                    vc.creatingView.addConnectingView(vc: self.navigationController!, description: "creating your account")
                    
                    Reducer.makeCommand(walletName: "", command: .getblockcount, param: "") { (object, errorDescription) in
                        
                        if let blockheight = object as? Int {
                            
                            vc.newWallet["blockheight"] = Int32(blockheight)
                            vc.newWallet["maxRange"] = 2500
                            //vc.newWallet["birthdate"] = keyBirthday()
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
                                    
                                    vc.newWallet["derivation"] = "m/84'/1'/0'"
                                    vc.derivation = "BIP84 m/84'/1'/0'"
                                    
                                } else if vc.node.network == "mainnet" {
                                    
                                    vc.newWallet["derivation"] = "m/84'/0'/0'"
                                    vc.derivation = "BIP84 m/84'/0'/0'"
                                    
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
    
    @IBAction func switchCustomSeedAction(_ sender: Any) {
        
        if customSeedSwitch.isOn {
            
            let alert = UIAlertController(title: "⚠︎ Advanced feature! ⚠︎", message: "This feature allows you to add your own BIP39 mnemonic as the device's master seed for the account you are about to create. This feature is only applicable to Hot and Warm accounts.", preferredStyle: .actionSheet)
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
    
    private func updateStatus(text: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.creatingView.label.text = text
            
        }
        
    }
    
    func createSingleSig() {
        print("create single sig")
        
        if userSuppliedWords == nil {
            
            updateStatus(text: "creating device's seed")
            
            KeychainCreator.createKeyChain() { [unowned vc = self] (mnemonic, error) in
                
                if !error {
                    
                    vc.updateStatus(text: "encrypting device's seed")
                    
                    let dataToEncrypt = mnemonic!.dataUsingUTF8StringEncoding
                    Encryption.encryptData(dataToEncrypt: dataToEncrypt) { (encryptedData, error) in
                        
                        if !error {
                            
                            vc.updateStatus(text: "creating primary descriptor")
                            //vc.newWallet["seed"] = encryptedData!
                            vc.saveSeed(seed: encryptedData!) { success in
                                
                                if success {
                                    vc.constructSingleSigPrimaryDescriptor(wallet: WalletStruct(dictionary: vc.newWallet), encryptedSeed: encryptedData!)
                                    
                                } else {
                                    vc.creatingView.removeConnectingView()
                                    displayAlert(viewController: vc, isError: true, message: "error saving your seed")
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            displayAlert(viewController: vc, isError: true, message: "error encrypting your seed")
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            
            creatingView.addConnectingView(vc: self, description: "creating single sig account")
            
            let dataToEncrypt = userSuppliedWords!.dataUsingUTF8StringEncoding
            Encryption.encryptData(dataToEncrypt: dataToEncrypt) { [unowned vc = self] (encryptedData, error) in
                
                if !error {
                    
                    vc.updateStatus(text: "creating primary descriptor")
                    //vc.newWallet["seed"] = encryptedData!
                    vc.saveSeed(seed: encryptedData!) { success in
                        
                        if success {
                            vc.constructSingleSigPrimaryDescriptor(wallet: WalletStruct(dictionary: vc.newWallet), encryptedSeed: encryptedData!)
                            
                        } else {
                            vc.creatingView.removeConnectingView()
                            displayAlert(viewController: vc, isError: true, message: "error saving your seed")
                            
                        }
                        
                    }
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "error encrypting your seed")
                }
                
            }
            
            
        }
        
        
    }
    
    func constructSingleSigPrimaryDescriptor(wallet: WalletStruct, encryptedSeed: Data) {
        /// Need to get the xpub
        var network:Network!
        
        if wallet.derivation.contains("/1'/") {
            network = .testnet
            
        } else {
            network = .mainnet
            
        }
        
        KeyFetcher.xpub(seed: encryptedSeed, chain: network, derivation: wallet.derivation) { [unowned vc = self] (xpub, fingerprint, error) in
            
            if xpub != nil && fingerprint != nil {
                var param = ""
                
                switch wallet.derivation {
                    
                case "m/84'/1'/0'":
                    param = "\"wpkh([\(fingerprint!)/84'/1'/0']\(xpub!)/0/*)\""
                    
                case "m/84'/0'/0'":
                    param = "\"wpkh([\(fingerprint!)/84'/0'/0']\(xpub!)/0/*)\""
                    
                default:
                    break
                    
                }
                
                Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) { [unowned vc = self] (object, errorDesc) in
                    
                    if let dict = object as? NSDictionary {
                        let primaryDescriptor = dict["descriptor"] as! String
                        vc.newWallet["descriptor"] = primaryDescriptor
                        vc.newWallet["name"] = Encryption.sha256hash(primaryDescriptor)
                        vc.updateStatus(text: "creating change descriptor")
                        let changeDescParam = param.replacingOccurrences(of: "/0/*", with: "/1/*")
                        vc.constructSingleSigChangeDescriptor(param: changeDescParam)
                                                        
                    } else {
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                        
                    }
                }
                
            } else {
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error deriving your xpub and fingerprint")
                
            }
            
        }
//        Encryption.decryptData(dataToDecrypt: wallet.seed) { [unowned vc = self] (unencryptedSeed) in
//
//            if unencryptedSeed != nil {
//
//                if let words = String(data: unencryptedSeed!, encoding: .utf8) {
//
//                    if let mnemonic = BIP39Mnemonic(words) {
//
//                        if let path = BIP32Path(wallet.derivation) {
//
//                            let seed = mnemonic.seedHex()
//
//
//                            if let mk = HDKey(seed, network) {
//
//                                do {
//
//                                    let key = try mk.derive(path)
//                                    let xpub = key.xpub
//                                    let fingerprint = mk.fingerprint.hexString
//
//
//                                } catch {
//
//                                    vc.creatingView.removeConnectingView()
//                                    displayAlert(viewController: vc, isError: true, message: "error creating your descriptor")
//
//                                }
//
//                            } else {
//                                vc.creatingView.removeConnectingView()
//                                displayAlert(viewController: vc, isError: true, message: "error deriving master key")
//
//                            }
//
//                        } else {
//                            vc.creatingView.removeConnectingView()
//                            displayAlert(viewController: vc, isError: true, message: "error converting derivation to bip32 path")
//
//                        }
//
//                    } else {
//                        vc.creatingView.removeConnectingView()
//                        displayAlert(viewController: vc, isError: true, message: "error converting words to BIP39 mnemonic")
//
//                    }
//
//                } else {
//                    vc.creatingView.removeConnectingView()
//                    displayAlert(viewController: vc, isError: true, message: "error converting seed to string")
//
//                }
//
//            } else {
//                vc.creatingView.removeConnectingView()
//                displayAlert(viewController: vc, isError: true, message: "error decrypting your seed")
//
//            }
//        }
    }
    
    func constructSingleSigChangeDescriptor(param: String) {
        
        Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) { [unowned vc = self] (object, errorDesc) in
            
            if let dict = object as? NSDictionary {
                let changeDescriptor = dict["descriptor"] as! String
                vc.newWallet["changeDescriptor"] = changeDescriptor
                vc.updateStatus(text: "creating the account on your node")
                vc.createSingleSigWallet()
                                                
            } else {
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                
            }
        }
    }
    
    func createSingleSigWallet() {
        
        let walletCreator = WalletCreator.sharedInstance
        walletCreator.createStandUpWallet(walletDict: newWallet) { [unowned vc = self] (success, errorDescription) in
            
            if success {
                
                vc.updateStatus(text: "saving the account to your device")
                
                CoreDataService.saveEntity(dict: vc.newWallet, entityName: .wallets) { (success, errorDescription) in
                    
                    if success {
                        
                        let w = WalletStruct(dictionary: vc.newWallet)
                        //let encryptedMnemonic = w.seed
                        //Encryption.decryptData(dataToDecrypt: encryptedMnemonic) { (mnemonic) in
                        
                        //if mnemonic != nil {
                        
                        //if let words = String(data: mnemonic!, encoding: .utf8) {
                        
                        //if let _ = BIP39Mnemonic(words) {
                        
                        SeedParser.fetchSeeds(wallet: w) { wordSet in
                            
                            if wordSet != nil {
                                
                                let recoveryQr = ["descriptor":"\(w.descriptor)", "blockheight":w.blockheight,"label":""] as [String : Any]
                                
                                if let json = recoveryQr.json() {
                                    
                                    DispatchQueue.main.async {
                                        vc.creatingView.removeConnectingView()
                                        vc.backUpRecoveryPhrase = "\(wordSet![0])"
                                        vc.recoveryQr = json
                                        vc.performSegue(withIdentifier: "walletCreated", sender: vc)
                                        
                                    }
                                    
                                } else {
                                    
                                    vc.creatingView.removeConnectingView()
                                    displayAlert(viewController: vc, isError: true, message: "error converting to json")
                                    
                                }
                            }
                        }
                        
                        //                                    } else {
                        //
                        //                                        vc.creatingView.removeConnectingView()
                        //                                        displayAlert(viewController: vc, isError: true, message: "error deriving bip39 mnemonic")
                        //
                        //                                    }
                        
                        //}
                        
                        //                            } else {
                        //
                        //                                vc.creatingView.removeConnectingView()
                        //                                displayAlert(viewController: vc, isError: true, message: "error decrypting seed")
                        //
                        //                            }
                        
                        //}
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error saving account")
                        
                    }
                    
                }
                
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "There was an error creating your account: \(errorDescription!)")
                
            }
            
        }
        
    }
    
    func createMultiSig() {
        
        updateStatus(text: "creating offline seed")
        
        KeychainCreator.createKeyChain { [unowned vc = self] (mnemonic, error) in
            
            if !error {
                
                let derivation = vc.newWallet["derivation"] as! String
                vc.backUpRecoveryPhrase = mnemonic!
                MnemonicCreator.convert(words: vc.backUpRecoveryPhrase) { (mnemonic, error) in
                    
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
        
        if userSuppliedWords == nil {
            
            updateStatus(text: "creating device's seed")
            
            KeychainCreator.createKeyChain { [unowned vc = self] (words, error) in
                
                if !error {
                    
                    let unencryptedSeed = words!.dataUsingUTF8StringEncoding
                    Encryption.encryptData(dataToEncrypt: unencryptedSeed) { (encryptedSeed, error) in
                        
                        if !error {
                            
                            vc.localSeed = encryptedSeed!
                            MnemonicCreator.convert(words: words!) { (mnemonic, error) in
                                
                                if !error {
                                    
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
            
        } else {
            
            print("creating with user supplied seed")
            
            /// Use the user supplied mnemonic for the local seed.
            let unencryptedSeed = userSuppliedWords!.dataUsingUTF8StringEncoding
            Encryption.encryptData(dataToEncrypt: unencryptedSeed) { [unowned vc = self] (encryptedSeed, error) in
                
                if !error {
                    
                    vc.localSeed = encryptedSeed!
                    MnemonicCreator.convert(words: vc.userSuppliedWords!) { [unowned vc = self] (mnemonic, error) in
                        
                        if !error {
                            
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
                    
                }
                
            }
            
        }
        
    }
    
    func createNodesKey() {
        print("createNodesKey")
        
        updateStatus(text: "creating node's seed")
        
        KeychainCreator.createKeyChain { [unowned vc = self] (words, error) in
                        
            if !error && words != nil {
                
                vc.nodesWords = words!
                
                MnemonicCreator.convert(words: words!) { (mnemonic, error) in
                    
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
                        
        case "m/48'/1'/0'/2'":
                                            
            descriptor = "wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/48'/1'/0'/2']\(recoveryKey)/0/*, [\(localFingerprint)/48'/1'/0'/2']\(localKey)/0/*, [\(nodeFingerprint)/48'/1'/0'/2']\(nodeKey)/0/*))"

            changeDescriptor = "wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/48'/1'/0'/2']\(recoveryKey)/1/*, [\(localFingerprint)/48'/1'/0'/2']\(localKey)/1/*, [\(nodeFingerprint)/48'/1'/0'/2']\(nodeKey)/1/*))"
            
        case "m/48'/0'/0'/2'":

            descriptor = "wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/48'/0'/0'/2']\(recoveryKey)/0/*, [\(localFingerprint)/48'/0'/0'/2']\(localKey)/0/*, [\(nodeFingerprint)/48'/0'/0'/2']\(nodeKey)/0/*))"
            
            changeDescriptor = "wsh(sortedmulti(\(signatures),[\(recoveryFingerprint)/48'/0'/0'/2']\(recoveryKey)/1/*, [\(localFingerprint)/48'/0'/0'/2']\(localKey)/1/*, [\(nodeFingerprint)/48'/0'/0'/2']\(nodeKey)/1/*))"
            
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
            
            self.creatingView.label.text = "creating your accounts descriptors"
            
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
                                        vc.newWallet["name"] = Encryption.sha256hash(primaryDescriptor)
                                        
                                        func create() {
                                           
                                            let multiSigCreator = CreateMultiSigWallet.sharedInstance
                                            let wallet = WalletStruct(dictionary: vc.newWallet)
                                            multiSigCreator.create(wallet: wallet, nodeXprv: vc.nodesSeed, nodeXpub: vc.publickeys[2]) { (success, error) in
                                                
                                                if success {
                                                    
                                                    DispatchQueue.main.async {
                                                        
                                                        vc.creatingView.label.text = "saving your account to your device"
                                                        
                                                    }
                                                    
                                                    CoreDataService.saveEntity(dict: vc.newWallet, entityName: .wallets) { (success, errorDescription) in
                                                        
                                                        if success {
                                                            
                                                            vc.creatingView.removeConnectingView()
                                                            
                                                            DispatchQueue.main.async {
                                                                
                                                                let recoveryQr = ["descriptor":"\(wallet.descriptor)", "blockheight":wallet.blockheight, "label":""] as [String : Any]
                                                                
                                                                if let json = recoveryQr.json() {
                                                                    
                                                                    DispatchQueue.main.async {
                                                                        
                                                                        vc.recoveryQr = json
                                                                        vc.performSegue(withIdentifier: "walletCreated", sender: vc)
                                                                        
                                                                    }
                                                                    
                                                                }
                                                                
                                                            }

                                                            
                                                        } else {
                                                            
                                                            vc.creatingView.removeConnectingView()
                                                            displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error saving account")
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                } else {
                                                    
                                                    if error != nil {
                                                        
                                                        vc.creatingView.removeConnectingView()
                                                        displayAlert(viewController: vc, isError: true, message: "error creating account: \(error!)")
                                                        
                                                    } else {
                                                        
                                                        vc.creatingView.removeConnectingView()
                                                        displayAlert(viewController: vc, isError: true, message: "error creating account")
                                                        
                                                    }
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                        if vc.localSeed != nil {
                                            //vc.newWallet["seed"] = vc.localSeed
                                            vc.saveSeed(seed: vc.localSeed!) { success in
                                                
                                                if success {
                                                    create()
                                                    
                                                } else {
                                                    vc.creatingView.removeConnectingView()
                                                    displayAlert(viewController: vc, isError: true, message: "error saving your seed")
                                                    
                                                }
                                                
                                            }
                                            
                                        } else {
                                            create()
                                            
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
        cv.addConnectingView(vc: self, description: "processing...")
        
        if let data = descriptor.data(using: .utf8) {
            
            do {
                
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
            
                if let _ = dict["descriptor"] as? String {
                    
                    if let _ = dict["blockheight"] as? Int {
                        /// It is an Account Map.
                        Import.importAccountMap(accountMap: dict) { walletDict in
                            print("importAccountMap")
                            
                            if walletDict != nil {
                                DispatchQueue.main.async { [unowned vc = self] in
                                    vc.walletToImport = walletDict!
                                    vc.walletName = walletDict!["name"] as! String
                                    vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                    
                                }
                            }
                        }
                    }
                } else if let fingerprint = dict["xfp"] as? String {
                    /// It is a coldcard wallet skeleton file.
                    cv.removeConnectingView()
                    DispatchQueue.main.async { [unowned vc = self] in
                        
                        let alert = UIAlertController(title: "Import Coldcard Single-sig account?", message: "You can choose either Native Segwit (BIP84, bech32 - bc1), Nested Segwit (BIP49, 3) or legacy (BIP44, 1) address types.", preferredStyle: .actionSheet)
                        
                        alert.addAction(UIAlertAction(title: "Native Segwit (BIP84, bc1)", style: .default, handler: { action in
                            cv.addConnectingView(vc: vc, description: "importing...")
                            let bip84Dict = dict["bip84"] as! NSDictionary
                            
                            Import.importColdCard(coldcardDict: bip84Dict, fingerprint: fingerprint) { (walletToImport) in
                                
                                if walletToImport != nil {
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        cv.removeConnectingView()
                                        vc.walletName = walletToImport!["name"] as! String
                                        vc.walletToImport = walletToImport!
                                        vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                        
                                    }
                                }
                            }
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Nested Segwit (BIP49, 3)", style: .default, handler: { action in
                            cv.addConnectingView(vc: vc, description: "importing...")
                            let bip49Dict = dict["bip49"] as! NSDictionary
                            
                            Import.importColdCard(coldcardDict: bip49Dict, fingerprint: fingerprint) { (walletToImport) in
                                
                                if walletToImport != nil {
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        cv.removeConnectingView()
                                        vc.walletName = walletToImport!["name"] as! String
                                        vc.walletToImport = walletToImport!
                                        vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                        
                                    }
                                }
                            }
                            
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Legacy (BIP44, 1)", style: .default, handler: { action in
                            cv.addConnectingView(vc: vc, description: "importing...")
                            let bip44Dict = dict["bip44"] as! NSDictionary
                            
                            Import.importColdCard(coldcardDict: bip44Dict, fingerprint: fingerprint) { (walletToImport) in
                                
                                if walletToImport != nil {
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        cv.removeConnectingView()
                                        vc.walletName = walletToImport!["name"] as! String
                                        vc.walletToImport = walletToImport!
                                        vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                        
                                    }
                                }
                            }
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        alert.popoverPresentationController?.sourceView = vc.view
                        vc.present(alert, animated: true, completion: nil)
                        
                    }
                }
                
            } catch {
                /// It is not an Account Map.
                Import.importDescriptor(descriptor: descriptor) { [unowned vc = self] walletDict in
                    
                    if walletDict != nil {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.walletToImport = walletDict!
                            vc.walletName = walletDict!["name"] as! String
                            vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                            
                        }
                        
                    } else {
                        cv.removeConnectingView()
                        showAlert(vc: vc, title: "Error", message: "error importing that account")
                        
                    }
                }
            }
        }
    }
    
    private func createWalletWithUserSuppliedSeed(dict: [String:String]?) {
        
        creatingView.addConnectingView(vc: self.navigationController!, description: "creating your account")
        
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
                            
                            /// Checks if user added an xpub or words.
                            if dict != nil {
                                
                                vc.userSuppliedMultiSigXpub = dict!["key"]!
                                vc.userSuppliedMultiSigFingerprint = dict!["fingerprint"]!
                                
                            }
                            
                            vc.createMultiSig()
                            
                        } else if vc.isSingleSig {
                            
                            vc.newWallet["type"] = "DEFAULT"
                            
                            if vc.node.network == "testnet" {
                                
                                vc.newWallet["derivation"] = "m/84'/1'/0'"
                                vc.derivation = "BIP84 m/84'/1'/0'"
                                
                            } else if vc.node.network == "mainnet" {
                                
                                vc.newWallet["derivation"] = "m/84'/0'/0'"
                                vc.derivation = "BIP84 m/84'/0'/0'"
                                
                            }
                            
                            /// Checks if user added an xpub or words.
                            if dict != nil {
                                
                                vc.createCustomSingleSig(dict: dict!)
                                
                            } else if vc.userSuppliedWords != nil {
                                
                                vc.createSingleSig()
                                
                            }
                            
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
            /// This should never happen as we only allow user to add an xpub, however we may add this ability in the near future
            //xpub = HDKey(dict["key"]!)!.xpub
            
        }
        
        let fingerprint = dict["fingerprint"]!
        
        switch wallet.derivation {
            
        case "m/84'/1'/0'":
            param = "\"wpkh([\(fingerprint)/84'/1'/0']\(xpub)/0/*)\""
            
        case "m/84'/0'/0'":
            param = "\"wpkh([\(fingerprint)/84'/0'/0']\(xpub)/0/*)\""
            
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
                vc.updateStatus(text: "creating the account on your node")
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
                
                vc.updateStatus(text: "saving the account to your device")
                
                CoreDataService.saveEntity(dict: vc.newWallet, entityName: .wallets) { (success, errorDescription) in
                    
                    if success {
                        
                        let w = WalletStruct(dictionary: vc.newWallet)
                        let recoveryQr = ["descriptor":w.descriptor, "blockheight":w.blockheight,"label":""] as [String : Any]
                        
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
                        displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error saving account")
                        
                    }
                    
                }
                
                
            } else {
                
                vc.creatingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "There was an error creating your account: \(errorDescription!)")
                
            }
            
        }
        
    }
    
    private func saveSeed(seed: Data, completion: @escaping ((Bool)) -> Void) {
        let dict = ["seed":seed,"id":UUID()] as [String : Any]
        
        CoreDataService.saveEntity(dict: dict, entityName: .seeds) { (success, errorDescription) in
            completion((success))
            
        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "walletCreated":
            
            if let vc = segue.destination as? WalletCreatedSuccessViewController {
                
                vc.recoveryPhrase = self.backUpRecoveryPhrase
                vc.recoveryQr = self.recoveryQr
                vc.wallet = self.newWallet
                vc.nodesWords = self.nodesWords
                
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
            
        case "addXpubSegue":
            
            if let vc = segue.destination as? AddExtendedKeyViewController {
                
                vc.onDoneBlock = { [unowned thisVc = self] dict in
                    
                    thisVc.createWalletWithUserSuppliedSeed(dict: dict)
                    
                }
                
            }
            
        case "addCustomWords":
            
            if let vc = segue.destination as? WordRecoveryViewController {
                
                vc.addingSeed = true
                vc.onSeedDoneBlock = { [unowned thisVc = self] mnemonic in
                    
                    thisVc.userSuppliedWords = mnemonic
                    thisVc.createWalletWithUserSuppliedSeed(dict: nil)
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }

}
