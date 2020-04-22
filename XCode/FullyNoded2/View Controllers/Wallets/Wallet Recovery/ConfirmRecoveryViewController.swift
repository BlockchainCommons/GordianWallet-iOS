//
//  ConfirmRecoveryViewController.swift
//  FullyNoded2
//
//  Created by Peter on 17/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class ConfirmRecoveryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    weak var nodeLogic = NodeLogic.sharedInstance
    let connectingView = ConnectingView()
    var words:String?
    var walletNameHash = ""
    var walletDict = [String:Any]()
    var derivation:String?
    var confirmedDoneBlock: ((Bool) -> Void)?
    var addresses = [String]()
    var descriptorStruct:DescriptorStruct!
    var isImporting = Bool()
    
    @IBOutlet var walletLabel: UILabel!
    @IBOutlet var walletName: UILabel!
    @IBOutlet var walletDerivation: UILabel!
    @IBOutlet var walletBirthdate: UILabel!
    @IBOutlet var walletType: UILabel!
    @IBOutlet var walletNetwork: UILabel!
    @IBOutlet var walletBalance: UILabel!
    @IBOutlet var addressTable: UITableView!
    @IBOutlet var cancelOutlet: UIButton!
    @IBOutlet var confirmOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        addressTable.delegate = self
        addressTable.dataSource = self
        addressTable.clipsToBounds = true
        addressTable.layer.cornerRadius = 8
        cancelOutlet.layer.cornerRadius = 8
        confirmOutlet.layer.cornerRadius = 8
        
        ///Importing
        /*if isImporting {
            
            let parser = DescriptorParser()
            descriptorStruct = parser.descriptor(walletDict["descriptor"] as! String)
            walletLabel.text = walletDict["label"] as? String ?? "no wallet label"
            walletBirthdate.text = getDate(unixTime: walletDict["birthdate"] as! Int32)
            walletNetwork.text = descriptorStruct.chain
            walletBalance.text = "unable to fetch balance until rescan completes"
            
            if descriptorStruct.isMulti {
                
                walletType.text = "\(descriptorStruct.mOfNType) multi-sig"
                walletDict["type"] = "MULTI"
                
                if descriptorStruct.multiSigPaths.count > 0 {
                    
                    walletDerivation.text = descriptorStruct.derivationArray[0] + "/\(descriptorStruct.multiSigPaths[0])"
                    walletDict["derivation"] = descriptorStruct.derivationArray[0] + "/\(descriptorStruct.multiSigPaths[0])"
                    
                } else {
                    
                    walletDerivation.text = "\(descriptorStruct.derivationArray[0])"
                    walletDict["derivation"] = "\(descriptorStruct.derivationArray[0])"
                    
                }
                                
                loadMultiSigAddressesFromImport()
                
            } else {
                
                showAlert(vc: self, title: "Under construction", message: "We only support multisig descriptor imports for now.")
                
            }
        
        /// Recovery QR only
        } else */if words == nil && walletDict["birthdate"] != nil {
            
            let parser = DescriptorParser()
            descriptorStruct = parser.descriptor(walletDict["descriptor"] as! String)
            walletLabel.text = walletDict["label"] as? String ?? "no wallet label"
            walletBirthdate.text = getDate(unixTime: walletDict["birthdate"] as! Int32)
            walletNetwork.text = descriptorStruct.chain
            walletBalance.text = "...fetching balance"
            
            if descriptorStruct.isMulti {
                
                walletType.text = "\(descriptorStruct.mOfNType) multi-sig"
                walletDerivation.text = descriptorStruct.derivationArray[1] + "/\(descriptorStruct.multiSigPaths[1])"
                walletDict["derivation"] = descriptorStruct.derivationArray[1]
                loadMultiSigAddressesFromQR()
                
            } else {
                
                walletType.text = "Single-sig"
                walletDerivation.text = descriptorStruct.derivation + "/0"
                loadSingleSigAddressesFromQR()
                
            }
            
        // Words only
        } else if words != nil && walletDict["birthdate"] == nil {
            
            loadAddressesFromLibWally()
            
        // Full multisig recovery
        } else if words != nil && walletDict["birthdate"] != nil {
            
            let parser = DescriptorParser()
            descriptorStruct = parser.descriptor(walletDict["descriptor"] as! String)
            walletLabel.text = walletDict["label"] as? String ?? "no wallet label"
            walletBirthdate.text = getDate(unixTime: walletDict["birthdate"] as! Int32)
            walletNetwork.text = descriptorStruct.chain
            walletBalance.text = "...fetching balance"
            walletType.text = "\(descriptorStruct.mOfNType) multi-sig"
            walletDerivation.text = descriptorStruct.derivationArray[1] + "/\(descriptorStruct.multiSigPaths[1])"
            loadMultiSigAddressesFromQR()
            
        }
        
    }
    
    private func loadAddressesFromLibWally() {
        
        if derivation != nil && words != nil {
         
            walletLabel.text = "unknown"
            walletName.text = reducedName(name: walletNameHash)
            var network:Network!
            if derivation!.contains("1") {
                walletNetwork.text = "Testnet"
                network = .testnet
            } else {
                walletNetwork.text = "Mainnet"
                network = .mainnet
            }
            walletBirthdate.text = "unknown"
            walletBalance.text = "...fetching balance"
            walletType.text = "Single-sig"
            walletDerivation.text = "\(derivation!)/0"
            
            let mnemonicCreator = MnemonicCreator()
            mnemonicCreator.convert(words: words!) { [unowned vc = self] (mnemonic, error) in
                
                if !error && mnemonic != nil {
                    
                    let mk = HDKey(mnemonic!.seedHex(), network)!
                    
                    for i in 0...4 {
                        
                        do {
                            
                            let key = try mk.derive(BIP32Path("\(vc.derivation!)/0/\(i)")!)
                            var addressType:AddressType!
                            
                            if vc.derivation!.contains("84") {
                                
                                addressType = .payToWitnessPubKeyHash
                                
                            } else if vc.derivation!.contains("44") {
                                
                                addressType = .payToPubKeyHash
                                
                            } else if vc.derivation!.contains("49") {
                                
                                addressType = .payToScriptHashPayToWitnessPubKeyHash
                                
                            }
                            
                            let address = key.address(addressType).description
                            vc.addresses.append(address)
                            
                        } catch {
                            
                            displayAlert(viewController: vc, isError: false, message: "error deriving addresses from those words")
                            
                        }
                        
                    }
                    
                    var zombieDict = [String:Any]()
                    zombieDict["name"] = vc.walletNameHash
                    let wallet = WalletStruct(dictionary: zombieDict)
                    vc.nodeLogic?.loadExternalWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                        
                        if success && dictToReturn != nil {
                            
                            let s = HomeStruct(dictionary: dictToReturn!)
                            let doub = (s.coldBalance).doubleValue
                            vc.walletDict["lastBalance"] = doub
                            
                            DispatchQueue.main.async {
                                
                                vc.walletBalance.text = "\(doub)"
                                
                            }
                            
                        } else {
                            
                            DispatchQueue.main.async {
                                
                                vc.walletBalance.text = "unknown"
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    displayAlert(viewController: vc, isError: true, message: "error deriving addresses from those words")
                    
                }
                
            }
            
        }
        
    }
    
    private func loadSingleSigAddressesFromQR() {
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        
        let xprv = descriptorStruct.accountXprv
        let xpub = HDKey(xprv)!.xpub
        let desc = (walletDict["descriptor"] as! String).replacingOccurrences(of: xprv, with: xpub)
        let walletName = walletNameHash
        
        DispatchQueue.main.async {
            
            self.walletName.text = self.reducedName(name: walletName)
            
        }
        
        Reducer.makeCommand(walletName: walletName, command: .getdescriptorinfo, param: "\"\(desc)\"") { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSDictionary {
                
                let descriptor = result["descriptor"] as! String
                Reducer.makeCommand(walletName: walletName, command: .deriveaddresses, param: "\"\(descriptor)\", [0,4]") { [unowned vc = self] (object, errorDesc) in
                    
                    if let result = object as? NSArray {
                        
                        for address in result {
                            
                            vc.addresses.append(address as! String)
                            
                        }
                        
                        vc.connectingView.removeConnectingView()
                        
                        DispatchQueue.main.async {
                            
                            vc.addressTable.reloadData()
                            
                        }
                        
                        vc.walletDict["name"] = walletName
                        let wallet = WalletStruct(dictionary: vc.walletDict)
                        vc.nodeLogic?.loadExternalWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                            
                            if success && dictToReturn != nil {
                                
                                let s = HomeStruct(dictionary: dictToReturn!)
                                let doub = (s.coldBalance).doubleValue
                                vc.walletDict["lastBalance"] = doub
                                
                                DispatchQueue.main.async {
                                    
                                    vc.walletBalance.text = "\(doub)"
                                    
                                }
                                
                            } else {
                                
                                DispatchQueue.main.async {
                                    
                                    vc.walletBalance.text = "error fetching balance"
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        vc.connectingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
                        
                    }
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "getdesriptorinfo error: \(errorDesc ?? "")")
                
            }
            
        }
        
    }
    
    
    private func loadMultiSigAddressesFromQR() {
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        
        /// Need to replace xprv with xpub so the checksum is valid for FN2 wallets, we also check if it is watch-only e.g. and imported descriptor
        
        var descriptor = walletDict["descriptor"] as! String
        
        if descriptor.contains("xprv") || descriptor.contains("tprv") {
            let xprv = descriptorStruct.multiSigKeys[1]
            let xpub = HDKey(xprv)!.xpub
            descriptor = descriptor.replacingOccurrences(of: xprv, with: xpub)
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            self.walletName.text = self.reducedName(name: vc.walletNameHash)
            
        }
        
        Reducer.makeCommand(walletName: walletNameHash, command: .deriveaddresses, param: "\"\(descriptor)\", [0,4]") { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSArray {
                
                for address in result {
                    
                    vc.addresses.append(address as! String)
                    
                }
                
                vc.connectingView.removeConnectingView()
                                
                DispatchQueue.main.async {
                    
                    vc.addressTable.reloadData()
                    
                }
                
                vc.walletDict["name"] = vc.walletNameHash
                let wallet = WalletStruct(dictionary: vc.walletDict)
                vc.nodeLogic?.loadExternalWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                    
                    if success && dictToReturn != nil {
                    
                        let s = HomeStruct(dictionary: dictToReturn!)
                        let doub = (s.coldBalance).doubleValue
                        vc.walletDict["lastBalance"] = doub
                        
                        DispatchQueue.main.async {
                            
                            vc.walletBalance.text = "\(doub)"
                            
                        }
                        
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            vc.walletBalance.text = "error fetching balance"
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        addresses.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row).  \(addresses[indexPath.row])"
        cell.textLabel?.textColor = .white
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.selectionStyle = .none
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 30
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        
        print("cancel")
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.dismiss(animated: true) {}
            
        }
        
    }
    
    private func recover(dict: [String:Any]) {
        
        let connectingView = ConnectingView()
        connectingView.addConnectingView(vc: self, description: "recovering your wallet")
        let recovery = RecoverWallet.sharedInstance
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                recovery.recover(node: node!, json: dict, words: vc.words, derivation: vc.derivation) { [unowned vc = self] (success, error) in
                    
                    if success {
                        
                        /// Use this notifaction to refresh all wallet data on the wallets page, this will ensure rescan labels show up and balances
                        ///  - only really necessary for wallets that have been recovered on the node.
                        NotificationCenter.default.post(name: .didSweep, object: nil, userInfo: nil)
                        
                        connectingView.removeConnectingView()
                        
                        DispatchQueue.main.async { [unowned vc = self] in
                                        
                            let alert = UIAlertController(title: "Wallet recovered!", message: "Your recovered wallet will now show up in \"Wallets\"", preferredStyle: .actionSheet)

                            alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
                                
                                DispatchQueue.main.async { [unowned vc = self] in
                                    
                                    vc.navigationController?.popToRootViewController(animated: true)
                                    
                                }
                                
                            }))
                            alert.popoverPresentationController?.sourceView = self.view
                            vc.present(alert, animated: true, completion: nil)
                            
                        }
                        
                    } else {
                        
                        connectingView.removeConnectingView()
                        
                        if error != nil {
                            
                            showAlert(vc: vc, title: "Error!", message: "Wallet recovery error: \(error!)")
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                connectingView.removeConnectingView()
                showAlert(vc: vc, title: "Error!", message: "Recovering wallets requires an active node!")
                
            }
            
        }
        
    }
    
    private func importWallet() {
        
        connectingView.addConnectingView(vc: self, description: "creating wallet on your node")
        let wallet = WalletStruct(dictionary: walletDict)
        
        func walletCreated() {
            
            NotificationCenter.default.post(name: .didSweep, object: nil, userInfo: nil)
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.connectingView.removeConnectingView()
                
                let alert = UIAlertController(title: "Wallet imported!", message: "Your imported wallet will now show up in \"Wallets\"", preferredStyle: .actionSheet)

                alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
                    
                    DispatchQueue.main.async { [unowned vc = self] in
                        
                        vc.navigationController?.popToRootViewController(animated: true)
                        
                    }
                    
                }))
                alert.popoverPresentationController?.sourceView = vc.view
                vc.present(alert, animated: true, completion: nil)
                
            }
            
        }
        
        func saveWallet() {
            
            CoreDataService.saveEntity(dict: walletDict, entityName: .wallets) { [unowned vc = self] (success, errorDescription) in
                
                print("walletDict = \(vc.walletDict)")
                
                if success {
                    
                    walletCreated()
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
                    
                }
                
            }
            
        }
        
        func importChangeDesc() {
            
            DispatchQueue.main.async { [unowned vc = self] in
                vc.connectingView.label.text = "importing change descriptor"
            }
            
            let params = "[{ \"desc\": \"\(wallet.changeDescriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }]"
            
            Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: params) { [unowned vc = self] (object, errorDescription) in
                
                if let result = object as? NSArray {
                    
                    if result.count > 0 {
                        
                        if let dict = result[0] as? NSDictionary {
                            
                            if let success = dict["success"] as? Bool {
                                
                                if success {
                                    
                                    saveWallet()
                                    
                                } else {
                                    
                                    vc.connectingView.removeConnectingView()
                                    showAlert(vc: vc, title: "Error", message: "Import error, error importing change descriptor: \(errorDescription ?? "unknown error")")
                                    
                                }
                                
                            } else {
                                
                                vc.connectingView.removeConnectingView()
                                showAlert(vc: vc, title: "Error", message: "Import error, error importing change descriptor: \(errorDescription ?? "unknown error")")
                                
                            }
                            
                        } else {
                            
                            vc.connectingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: "Import error, error importing change descriptor: \(errorDescription ?? "unknown error")")
                            
                        }
                        
                    } else {
                        
                        vc.connectingView.removeConnectingView()
                        showAlert(vc: vc, title: "Error", message: "Import error, error importing change descriptor: \(errorDescription ?? "unknown error")")
                        
                    }
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "Import error, error importing change descriptor: \(errorDescription ?? "unknown error")")
                    
                }
                
            }
            
        }
        
        func importPrimaryDesc() {
            
            DispatchQueue.main.async { [unowned vc = self] in
                vc.connectingView.label.text = "importing primary descriptor"
            }
            
            let params = "[{ \"desc\": \"\(wallet.descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }]"
            
            Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: params) { [unowned vc = self] (object, errorDescription) in
                
                if let result = object as? NSArray {
                    
                    if result.count > 0 {
                        
                        if let dict = result[0] as? NSDictionary {
                            
                            if let success = dict["success"] as? Bool {
                                
                                if success {
                                    
                                    importChangeDesc()
                                    
                                } else {
                                    
                                    vc.connectingView.removeConnectingView()
                                    showAlert(vc: vc, title: "Error", message: "Import error, error importing primary descriptor: \(errorDescription ?? "unknown error")")
                                    
                                }
                                
                            } else {
                                
                                vc.connectingView.removeConnectingView()
                                showAlert(vc: vc, title: "Error", message: "Import error, error importing primary descriptor: \(errorDescription ?? "unknown error")")
                                
                            }
                            
                        } else {
                            
                            vc.connectingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: "Import error, error importing primary descriptor: \(errorDescription ?? "unknown error")")
                            
                        }
                        
                    } else {
                        
                        vc.connectingView.removeConnectingView()
                        showAlert(vc: vc, title: "Error", message: "Import error, error importing primary descriptor: \(errorDescription ?? "unknown error")")
                        
                    }
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "Import error, error importing primary descriptor: \(errorDescription ?? "unknown error")")
                    
                }
                
            }
            
        }
        
        func createWallet() {
            
            let param = "\"\(wallet.name!)\", true, true, \"\", true"
            Reducer.makeCommand(walletName: "", command: .createwallet, param: param) { [unowned vc = self] (object, errorDescription) in
                
                if let _ = object as? NSDictionary {
                    
                    importPrimaryDesc()
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "Import error, error creating wallet: \(errorDescription ?? "unknown error")")
                    
                }
                
            }
            
        }
        
        createWallet()
        
//        let param = "\"\(wallet.name!)\", true, true, \"\", true"
//        Reducer.makeCommand(walletName: "", command: .createwallet, param: param) { [unowned vc = self] (object, errorDescription) in
//
//            if let _ = object as? NSDictionary {
//
//                let params = "[{ \"desc\": \"\(wallet.descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }]"
//
//                Reducer.makeCommand(walletName: wallet.name!, command: .importmulti, param: params) { [unowned vc = self] (object, errorDescription) in
//
//                    if let result = object as? NSArray {
//
//                        if result.count > 0 {
//
//                            if let dict = result[0] as? NSDictionary {
//
//                                if let success = dict["success"] as? Bool {
//
//                                    if success {
//
//                                        CoreDataService.saveEntity(dict: vc.walletDict, entityName: .wallets) { [unowned vc = self] (success, errorDescription) in
//
//                                            if success {
//
//                                                NotificationCenter.default.post(name: .didSweep, object: nil, userInfo: nil)
//
//                                                DispatchQueue.main.async { [unowned vc = self] in
//
//                                                    vc.connectingView.removeConnectingView()
//
//                                                    let alert = UIAlertController(title: "Wallet imported!", message: "Your imported wallet will now show up in \"Wallets\"", preferredStyle: .actionSheet)
//
//                                                    alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
//
//                                                        DispatchQueue.main.async { [unowned vc = self] in
//
//                                                            vc.navigationController?.popToRootViewController(animated: true)
//
//                                                        }
//
//                                                    }))
//                                                    alert.popoverPresentationController?.sourceView = vc.view
//                                                    vc.present(alert, animated: true, completion: nil)
//
//                                                }
//
//                                            } else {
//
//                                                vc.connectingView.removeConnectingView()
//                                                showAlert(vc: vc, title: "Error", message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
//
//                                            }
//
//                                        }
//
//                                    } else {
//
//                                        vc.connectingView.removeConnectingView()
//                                        showAlert(vc: vc, title: "Error", message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
//
//                                    }
//
//                                } else {
//
//                                    vc.connectingView.removeConnectingView()
//                                    showAlert(vc: vc, title: "Error", message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
//
//                                }
//
//                            } else {
//
//                                vc.connectingView.removeConnectingView()
//                                showAlert(vc: vc, title: "Error", message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
//
//                            }
//
//                        } else {
//
//                            vc.connectingView.removeConnectingView()
//                            showAlert(vc: vc, title: "Error", message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
//
//                        }
//
//                    } else {
//
//                        vc.connectingView.removeConnectingView()
//                        showAlert(vc: vc, title: "Error", message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
//
//                    }
//
//                }
//
//
//            } else {
//
//                vc.connectingView.removeConnectingView()
//                showAlert(vc: vc, title: "Error", message: "Import error, unable to create that wallet: \(errorDescription ?? "unknown error")")
//
//            }
//
//        }
        
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        
        if !isImporting {
            
            recover(dict: walletDict)
            
        } else {
            
            importWallet()
            
        }
        
    }
    
    private func getDate(unixTime: Int32) -> String {
        
        let dateFormatter = DateFormatter()
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm" //Specify your format that you want
        let strDate = dateFormatter.string(from: date)
        return strDate
        
    }
    
    private func reducedName(name: String) -> String {
        
        let first = String(name.prefix(5))
        let last = String(name.suffix(5))
        return "\(first)*****\(last).dat"
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
