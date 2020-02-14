//
//  ChooseWalletFormatViewController.swift
//  FullyNoded2
//
//  Created by Peter on 13/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class ChooseWalletFormatViewController: UIViewController {
    
    var node:NodeStruct!
    var newWallet = [String:Any]()
    var isBIP84 = Bool()
    var isBIP49 = Bool()
    var isBIP44 = Bool()
    var isMultiSig = Bool()
    var isSingleSig = Bool()
    var publickeys = [String]()
    var localSeed = Data()
    var nodesSeed = ""
    var descriptor = ""
    var recoveryPubkey = ""
    var backUpRecoveryPhrase = ""
    var singleSigDoneBlock : ((Bool) -> Void)?
    var multiSigDoneBlock : (((success: Bool, recoveryPhrase: String, descriptor: String)) -> Void)?
    let enc = Encryption()
    let creatingView = ConnectingView()
    
    @IBOutlet var formatSwitch: UISegmentedControl!
    @IBOutlet var templateSwitch: UISegmentedControl!
    @IBOutlet var buttonOutlet: UIButton!
    @IBOutlet var seedDescription: UILabel!
    //your device will hold one seed, your node will hold 2,000 private keys derived from a second seed, and you will securely store one seed offline for recovery purposes

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonOutlet.clipsToBounds = true
        buttonOutlet.layer.cornerRadius = 10
        formatSwitch.selectedSegmentIndex = 0
        templateSwitch.selectedSegmentIndex = 0
        isBIP84 = true
        isMultiSig = true
        
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
            
        case 1:
            
            isSingleSig = true
            isMultiSig = false
            
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
                self.creatingView.addConnectingView(vc: self, description: "creating your wallet")
                
                if self.isBIP84 {
                    
                    self.newWallet["derivation"] = "m/84'/1'/0'/0"
                    
                } else if self.isBIP49 {
                    
                    self.newWallet["derivation"] = "m/49'/1'/0'/0"
                    
                } else if self.isBIP44 {
                    
                    self.newWallet["derivation"] = "m/44'/1'/0'/0"
                    
                }
                
                self.newWallet["birthdate"] = keyBirthday()
                self.newWallet["id"] = UUID()
                self.newWallet["isActive"] = false
                self.newWallet["name"] = "\(randomString(length: 10))_StandUp"
                self.newWallet["lastUsed"] = Date()
                self.newWallet["lastBalance"] = 0.0
                self.newWallet["isArchived"] = false
                self.newWallet["nodeId"] = self.node.id
                
                print("ismultisig = \(self.isMultiSig)")
                
                if self.isMultiSig {
                    
                    self.newWallet["type"] = "MULTI"
                    self.createMultiSig()
                    
                } else if self.isSingleSig {
                    
                    self.newWallet["type"] = "DEFAULT"
                    self.createSingleSig()
                    
                }
                
            } else {
                
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
                        let walletCreator = WalletCreator()
                        walletCreator.walletDict = self.newWallet
                        walletCreator.node = self.node
                        let derivation = self.newWallet["derivation"] as! String
                        walletCreator.createStandUpWallet(derivation: derivation) { (success, errorDescription, descriptor) in
                            
                            if success {
                                
                                self.newWallet["descriptor"] = descriptor!
                                let walletSaver = WalletSaver()
                                walletSaver.save(walletToSave: self.newWallet) { (success) in
                                    
                                    if success {
                                        
                                        print("wallet saved")
                                        
                                        self.creatingView.removeConnectingView()
                                        self.singleSigDoneBlock!(true)
                                        
                                        DispatchQueue.main.async {
                                            
                                            self.dismiss(animated: true, completion: nil)
                                            
                                        }
                                        
                                    } else {
                                        
                                        print("error saving wallet")
                                        self.creatingView.removeConnectingView()
                                        displayAlert(viewController: self, isError: true, message: "There was an error saving your wallet")
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: "There was an error creating your wallet: \(errorDescription!)")
                                
                            }
                            
                        }

                        
                    } else {
                        
                        self.creatingView.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: "error encrypting your seed")
                    }
                    
                }
                
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
                        
                        if let masterKey = HDKey((mnemonic!.seedHex("")), self.network(path: derivation)) {
                            
                            if let path = BIP32Path(derivation) {
                                
                                do {
                                    
                                    let account = try masterKey.derive(path)
                                    self.recoveryPubkey = account.xpub
                                    self.publickeys.append(self.recoveryPubkey)
                                    self.createLocalKey()
                                    
                                } catch {
                                    
                                    displayAlert(viewController: self, isError: true, message: "failed deriving xpub")
                                    
                                }
                                
                            } else {
                                
                                displayAlert(viewController: self, isError: true, message: "failed initiating bip32 path")
                                
                            }
                            
                        } else {
                            
                            displayAlert(viewController: self, isError: true, message: "failed creating masterkey")
                            
                        }
                        
                    } else {
                        
                        displayAlert(viewController: self, isError: true, message: "error getting xpub from your recovery key")
                        
                    }
                    
                }
                
            } else {
                
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
                                
                                let derivation = self.newWallet["derivation"] as! String
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), self.network(path: derivation)) {
                                    
                                    if let path = BIP32Path(derivation) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            self.publickeys.append(account.xpub)
                                            self.createNodesKey()
                                            
//                                            if self.publickeys.count == 2 {
//
//
//
//                                            }
//
//                                            if self.publickeys.count == 3 {
//
//                                                self.nodesSeed = account.xpriv!
//                                                self.constructDescriptor(derivation: derivation)
//
//                                            }
                                            
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
                
                //let unencryptedSeed = words!.dataUsingUTF8StringEncoding
                //let enc = Encryption()
                //enc.encryptData(dataToEncrypt: unencryptedSeed) { (encryptedSeed, error) in
                    
                    if !error {
                        
                        //nodesSeed = encryptedSeed!
                        let converter = MnemonicCreator()
                        converter.convert(words: words!) { (mnemonic, error) in
                            
                            if !error {
                                
                                let derivation = self.newWallet["derivation"] as! String
                                
                                if let masterKey = HDKey((mnemonic!.seedHex("")), self.network(path: derivation)) {
                                    
                                    if let path = BIP32Path(derivation) {
                                        
                                        do {
                                            
                                            let account = try masterKey.derive(path)
                                            self.publickeys.append(account.xpub)
                                            self.nodesSeed = account.xpriv!
                                            self.constructDescriptor(derivation: derivation)
                                            
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
                    
                    
                //}
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "error creating your recovery key")
                
            }
            
        }
        
    }
    
    func constructDescriptor(derivation: String) {
        
        let signatures = 2
        
        var processedKeys = (publickeys.description).replacingOccurrences(of: "[", with: "")
        processedKeys = processedKeys.replacingOccurrences(of: ",", with: "/*,")
        processedKeys = processedKeys.replacingOccurrences(of: "]", with: "/*]")
        processedKeys = processedKeys.replacingOccurrences(of: "]", with: "")
        processedKeys = processedKeys.replacingOccurrences(of: "\"", with: "")
        
        // MARK: TODO CHANGE TO SORTEDMULTI
        
        switch derivation {

        case "m/84'/1'/0'/0", "m/84'/0'/0'/0":

            descriptor = "wsh(multi(\(signatures),\(processedKeys)))"

        case "m/44'/1'/0'/0", "m/44'/0'/0'/0":

            descriptor = "sh(multi(\(signatures),\(processedKeys)))"

        case "m/49'/1'/0'/0", "m/49'/0'/0'/0":

            descriptor = "sh(wsh(multi(\(signatures),\(processedKeys))))"
            
        default:

            break

        }
        
        descriptor = descriptor.replacingOccurrences(of: "\"", with: "")
        descriptor = descriptor.replacingOccurrences(of: " ", with: "")
        getInfo(descriptor: descriptor)
        
//        qrGenerator.textInput = descriptor
//
//        tapQRGesture = UITapGestureRecognizer(target: self,
//                                              action: #selector(shareQRCode(_:)))
//
//        imageView.addGestureRecognizer(tapQRGesture)
//
//        DispatchQueue.main.async {
//
//            self.imageView.image = self.qrGenerator.getQRCode()
//
//        }
        
    }
    
    func getInfo(descriptor: String) {
        
        DispatchQueue.main.async {
            
            self.creatingView.label.text = "creating your wallets descriptor"
            
        }
        
        let reducer = Reducer()
        print("descriptor: \(descriptor)")
        
        reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\"\(descriptor)\"") {
            
            DispatchQueue.main.async {
                
                self.creatingView.label.text = "importing your descriptor to your node"
                
            }
            
            if !reducer.errorBool {
                
                let result = reducer.dictToReturn
                print("result = \(result)")
                
                let desc = result["descriptor"] as! String
                
                let enc = Encryption()
                enc.getNode { (node, error) in
                    
                    if !error {
                        
                        self.newWallet["descriptor"] = desc
                        self.newWallet["seed"] = self.localSeed
                        
                        let multiSigCreator = CreateMultiSigWallet()
                        let wallet = WalletStruct(dictionary: self.newWallet)
                        multiSigCreator.create(wallet: wallet, nodeXprv: self.nodesSeed, nodeXpub: self.publickeys[2]) { (success) in
                            
                            if success {
                                
                                DispatchQueue.main.async {
                                   self.creatingView.label.text = "saving your wallet to your device"
                                }
                                
                                let walletSaver = WalletSaver()
                                walletSaver.save(walletToSave: self.newWallet) { (success) in
                                    
                                    if success {
                                        
                                        self.creatingView.removeConnectingView()
                                        
                                        DispatchQueue.main.async {
                                            
                                            self.multiSigDoneBlock!((true, self.backUpRecoveryPhrase, self.descriptor))
                                            self.dismiss(animated: true, completion: nil)
                                            
                                        }
                                        
                                    } else {
                                        
                                        displayAlert(viewController: self, isError: true, message: "error saving wallet")
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                displayAlert(viewController: self, isError: true, message: "failed creating your wallet")
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                print("error: \(reducer.errorDescription)")
                
            }
            
        }
        
    }
    
    private func network(path: String) -> Network {
        
        var network:Network!
        
        if path.contains("/1'") {
            
            network = .testnet
            
        } else {
            
            network = .mainnet
            
        }
        
        return network
        
    }
    
//    @IBAction func nativeSegwitAction(_ sender: Any) {
//
//        print("chose native segwit")
//
//        DispatchQueue.main.async {
//
//            self.performSegue(withIdentifier: "chooseTemplate", sender: self)
//
//        }
//
//    }
//
//    @IBAction func segwitWrappedAction(_ sender: Any) {
//
//        print("chose segwit wrapped")
//
//        DispatchQueue.main.async {
//
//            self.performSegue(withIdentifier: "chooseTemplate", sender: self)
//
//        }
//
//    }
//
//    @IBAction func legacyAction(_ sender: Any) {
//
//        print("chose legacy")
//
//        DispatchQueue.main.async {
//
//            self.performSegue(withIdentifier: "chooseTemplate", sender: self)
//
//        }
//
//    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        let id = segue.identifier
//
//        switch id {
//
//        case "chooseTemplate":
//
//            if let vc = segue.destination as? ChooseWalletTemplateViewController {
//
//                vc.chooseTemplateDoneBlock = { result in
//
//                    self.singleSigDoneBlock!(true)
//
//                    DispatchQueue.main.async {
//
//                         self.dismiss(animated: true, completion: nil)
//
//                    }
//
//                }
//
//            }
//
//        default:
//
//            break
//
//        }
//
//    }
    

}
