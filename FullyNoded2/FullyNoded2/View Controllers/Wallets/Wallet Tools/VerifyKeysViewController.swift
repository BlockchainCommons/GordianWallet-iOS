//
//  VerifyKeysViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 07/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class VerifyKeysViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var address = ""
    var words = ""
    var derivation = ""
    var keys = [String]()
    var comingFromSettings = Bool()
    let connectingView = ConnectingView()
    var wallet:WalletStruct!
    @IBOutlet var table: UITableView!
    @IBOutlet var saveButtonOutlet: UIButton!
    @IBOutlet var derivationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        if comingFromSettings {
            
            saveButtonOutlet.alpha = 0
            
        }
        
        saveButtonOutlet.clipsToBounds = true
        saveButtonOutlet.layer.cornerRadius = 8
        
        derivationLabel.adjustsFontSizeToFitWidth = true
        derivationLabel.text = ""
        
        if comingFromSettings {
            
            loadActiveWallet()
            
        } else {
            
            derivationLabel.text = labelText(derivation: derivation)
            loadProposedWallet()
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if comingFromSettings {
            
            table.translatesAutoresizingMaskIntoConstraints = true
            table.frame = CGRect(x: table.frame.origin.x, y: table.frame.origin.y, width: table.frame.width, height: view.frame.height)
            
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    func addExistingDerivationLabel() {
        
        let derivation = wallet.derivation
        derivationLabel.text = labelText(derivation: derivation)
        derivationLabel.adjustsFontSizeToFitWidth = true
        
    }
    
    func labelText(derivation: String) -> String {
        
        if derivation.contains("84") {
            
            return "Native Segwit Account 0 (BIP84 \(derivation))"
            
        } else if derivation.contains("44") {
            
            return "Legacy Account 0 (BIP44 \(derivation))"
            
        } else if derivation.contains("49") {
            
            return "P2SH Nested Segwit Account 0 (BIP49 \(derivation))"
            
        } else {
            
            return ""
            
        }
        
    }
    
    func loadProposedWallet() {
        
        getKeysFromLibWally()
        
    }
    
    func loadActiveWallet() {
        print("loadActiveWallet")
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                self.wallet = wallet!
                let parser = DescriptorParser()
                let str = parser.descriptor(wallet!.descriptor)
                
                if str.isMulti {
                    
                    self.getKeysFromBitcoinCore()
                    
                } else {
                    
                    let enc = Encryption()
                    
                    if let encryptedSeed = wallet?.seed {
                        
                        enc.decryptData(dataToDecrypt: encryptedSeed) { (decryptedSeed) in
                            
                            if decryptedSeed != nil {
                                
                                self.words = String(data: decryptedSeed!, encoding: .utf8)!
                                self.getKeysFromLibWally()
                                
                            } else {
                                
                                let s = String(bytes: wallet!.seed, encoding: .utf8)
                                if s == "no seed" {
                                    
                                    self.getKeysFromBitcoinCore()
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        self.getKeysFromBitcoinCore()
                        
                    }
                    
                }
                
                self.addExistingDerivationLabel()
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 77
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return keys.count
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Index #\(section)"
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "keyCell", for: indexPath)
        cell.selectionStyle = .none
        
        let keyLabel = cell.viewWithTag(2) as! UILabel
        let pathLabel = cell.viewWithTag(3) as! UILabel
        
        pathLabel.text = "\(wallet.derivation)/0/\(indexPath.section)"
        keyLabel.text = "\(keys[indexPath.section])"
        
        keyLabel.adjustsFontSizeToFitWidth = true
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let index = indexPath.section
        address = keys[index]
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "verifyAddress", sender: self)
            
        }
        
    }
    
    func getKeysFromBitcoinCore() {
        
        connectingView.addConnectingView(vc: self, description: "getting the addresses from your node")
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: wallet.name, command: .deriveaddresses, param: "\"\(wallet.descriptor)\", ''[0,999]''") {
            
            if !reducer.errorBool {
                
                let result = reducer.arrayToReturn
                self.keys = result as! [String]
                
                DispatchQueue.main.async {
                    
                    self.table.reloadData()
                    
                }
                
                self.connectingView.removeConnectingView()
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "error getting addresses from your node")
                self.connectingView.removeConnectingView()
                
            }
            
        }
        
    }

    func getKeysFromLibWally() {
        
        let mnemonicCreator = MnemonicCreator()
        mnemonicCreator.convert(words: words) { (mnemonic, error) in
            
            if !error {
                
                self.getKeys(mnemonic: mnemonic!)
                
                if !self.comingFromSettings {
                    
                    displayAlert(viewController: self, isError: false, message: "please verify that these keys match your expected keys, if they don't then do not save your wallet as something is wrong!")
                    
                }
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "error converting those words into a seed")
                
            }
            
        }
        
    }
    
    func getKeys(mnemonic: BIP39Mnemonic) {
        
        let derivation = wallet.derivation
        
        if let path = BIP32Path(wallet.derivation) {
            
            if let masterKey = HDKey((mnemonic.seedHex("")), network(path: derivation)) {
                
                do {
                    
                    let account = try masterKey.derive(path)
                    
                    for i in 0 ... 999 {
                        
                        do {
                            
                            let key1 = try account.derive(BIP32Path("\(i)")!)
                            var addressType:AddressType!
                            
                            if derivation.contains("84") {

                                addressType = .payToWitnessPubKeyHash

                            } else if derivation.contains("44") {

                                addressType = .payToPubKeyHash

                            } else if derivation.contains("49") {

                                addressType = .payToScriptHashPayToWitnessPubKeyHash

                            }
                            
                            let address = key1.address(addressType)
                            keys.append("\(address)")
                            
                            if i == 999 {
                                
                                DispatchQueue.main.async {
                                    
                                    self.table.reloadData()
                                    
                                }
                                
                            }
                            
                        } catch {
                            
                            displayAlert(viewController: self, isError: true, message: "error deriving your wallets keys")
                            
                        }
                        
                    }
                    
                } catch {
                    
                    displayAlert(viewController: self, isError: true, message: "error initiating your wallets account")
                    
                }
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "error initiating your wallets master key")
                
            }
            
        } else {
            
            displayAlert(viewController: self, isError: true, message: "error initiating your wallets path")
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
        (view as! UITableViewHeaderFooterView).textLabel?.alpha = 1
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        switch id {
            
        case "verifyAddress":
            
            if let vc = segue.destination as? VerifyAddressViewController {
                
                vc.address = address
                
            }
            
        default:
            
            break
            
        }
        
    }

}
