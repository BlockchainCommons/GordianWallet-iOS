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
    var updateDerivationBlock:(([String:String]) -> Void)?
    var addresses = [String]()
    var descriptorStruct:DescriptorStruct!
    var isImporting = Bool()
    var primaryDescriptors:[String] = []
    var changeDescriptors:[String] = []
    var importedOrRecovered = "imported"
    
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
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        let parser = DescriptorParser()
        descriptorStruct = parser.descriptor(walletDict["descriptor"] as! String)
        walletLabel.text = walletDict["label"] as? String ?? "no wallet label"
        walletBirthdate.text = "\(walletDict["blockheight"] as! Int32)"
        walletNetwork.text = descriptorStruct.chain
        walletBalance.text = "...fetching balance"
        walletName.text = reducedName(name: walletNameHash)
        
        if descriptorStruct.isMulti {
            walletType.text = "\(descriptorStruct.mOfNType) multi-sig"
            walletDerivation.text = descriptorStruct.derivationArray[1] + "/\(descriptorStruct.multiSigPaths[1])"
            walletDict["derivation"] = descriptorStruct.derivationArray[1]
        } else {
            walletType.text = "Single-sig"
            walletDerivation.text = descriptorStruct.derivation + "/0"
        }
        loadAddresses()
    }
    
    private func removeLoader() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.connectingView.removeConnectingView()
            vc.addressTable.reloadData()
        }
    }
    
    private func loadAddresses() {
        let descriptor = walletDict["descriptor"] as! String
        Reducer.makeCommand(walletName: walletNameHash, command: .deriveaddresses, param: "\"\(descriptor)\", [0,4]") { [unowned vc = self] (object, errorDesc) in
            if let result = object as? NSArray {
                for address in result {
                    vc.addresses.append(address as! String)
                }
                vc.walletDict["name"] = vc.walletNameHash
                vc.updateLabel(text: "fetching account balance from node...")
                let wallet = WalletStruct(dictionary: vc.walletDict)
                vc.nodeLogic?.loadExternalWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                    if success && dictToReturn != nil {
                        let s = HomeStruct(dictionary: dictToReturn!)
                        let doub = (s.coldBalance).doubleValue
                        vc.walletDict["lastBalance"] = doub
                        DispatchQueue.main.async {
                            vc.walletBalance.text = "\(doub)"
                        }
                        vc.removeLoader()
                    } else {
                        DispatchQueue.main.async {
                            vc.walletBalance.text = "account does not exist on node"
                            vc.updateLabel(text: "scanning for transaction history...")
                            vc.scanPaths()
                        }
                    }
                }
            } else {
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
            }
        }
    }
    
    private func scanPaths() {
        if words != nil {
            var cointType = "0"
            let derivation = walletDict["derivation"] as! String
            if derivation.contains("/1'/") {
                // its testnet
                cointType = "1"
            }
            CheckSubAccounts.check(derivation: derivation, words: words!, coinType: cointType) { [unowned vc = self] (paths) in
                if paths != nil {
                    var pathsWithHistory:[[String:Any]] = []
                    for (i, path) in paths!.enumerated() {
                        let hasHistory = path["hasHistory"] as! Bool
                        if hasHistory {
                            pathsWithHistory.append(path)
                        }
                        if i + 1 == paths!.count {
                            if pathsWithHistory.count > 0 {
                                var derivs = ""
                                for sub in pathsWithHistory {
                                    let path = sub["derivation"] as! String
                                    derivs += path + " "
                                }
                                vc.promptToRecoverOtherPaths(paths: derivs)
                            }
                            vc.removeLoader()
                        }
                    }
                } else {
                    vc.removeLoader()
                }
            }
        } else {
            removeLoader()
        }
    }

     private func promptToRecoverOtherPaths(paths: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Transaction history detected!", message: "We detected transaction history on derivations: \(paths), would you like to recover this account instead?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [unowned vc = self] action in
                let dict = ["words":vc.words!,"derivation":paths]
                DispatchQueue.main.async {
                    vc.updateDerivationBlock!((dict))
                    vc.navigationController?.popViewController(animated: true)
                }
             }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
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
        DispatchQueue.main.async { [unowned vc = self] in
            vc.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func deactivateAllAccountsAndActivateNewAccount(wallet: WalletStruct) {
        CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
            if wallets != nil {
                if wallets!.count > 0 {
                    for (i, w) in wallets!.enumerated() {
                        let walletStruct = WalletStruct(dictionary: w)
                        if wallet.id != nil && walletStruct.id != nil {
                            if walletStruct.id != wallet.id! {
                                CoreDataService.updateEntity(id: walletStruct.id!, keyToUpdate: "isActive", newValue: false, entityName: .wallets) { _ in }
                            } else {
                                CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "isActive", newValue: true, entityName: .wallets) { _ in }
                            }
                            if i + 1 == wallets!.count {
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .didCreateAccount, object: nil, userInfo: nil)
                                }
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .didCreateAccount, object: nil, userInfo: nil)
                    }
                }
            }
        }
    }
    
    func walletSuccessfullyCreated(wallet: WalletStruct) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.deactivateAllAccountsAndActivateNewAccount(wallet: wallet)
            let alert = UIAlertController(title: "Account \(vc.importedOrRecovered)!", message: "Your \(vc.importedOrRecovered) account will now show up in \"Accounts\", a blockchain rescan has been initiated", preferredStyle: .actionSheet)
            if wallet.label == "" {
                alert.addAction(UIAlertAction(title: "Add Label", style: .default, handler: { action in
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.performSegue(withIdentifier: "addLabelToRecoveredAccount", sender: vc)
                    }
                }))
            }
            alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { action in
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.navigationController?.popToRootViewController(animated: true)
                }
            }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func rescanFrom(param: String, wallet: WalletStruct) {
        Reducer.makeCommand(walletName: wallet.name ?? walletNameHash, command: .rescanblockchain, param: param) { [unowned vc = self] (object, errorDescription) in
            vc.connectingView.removeConnectingView()
            vc.walletSuccessfullyCreated(wallet: wallet)
        }
    }
    
    func rescan(wallet: WalletStruct) {
        updateLabel(text: "Initiating a rescan")
        Reducer.makeCommand(walletName: wallet.name ?? walletNameHash, command: .getblockchaininfo, param: "") { [unowned vc = self] (object, errorDescription) in
            if let dict = object as? NSDictionary {
                if let pruned = dict["pruned"] as? Bool {
                    if pruned {
                        if let pruneHeight = dict["pruneheight"] as? Int {
                            if wallet.blockheight == 0 {
                                showAlert(vc: vc, title: "Pruned Node", message: "We have initiated a rescan from your pruned node's blockheight \(pruneHeight) as that is as far back as we can go, if you have transactions that precede this blockheight they will not show up unless you reindex your node.")
                                vc.rescanFrom(param: "\(pruneHeight)", wallet: wallet)
                            } else if pruneHeight > wallet.blockheight {
                                showAlert(vc: vc, title: "Reindex required!", message: "Your pruned node can not rescan beyond its prune height, in order to rescan to the block where this wallet was born a full blockchain reindex is required. We have initiated a rescan from block \(pruneHeight).")
                                vc.rescanFrom(param: "\(pruneHeight)", wallet: wallet)
                            } else {
                                vc.rescanFrom(param: "\(wallet.blockheight)", wallet: wallet)
                            }
                        } else {
                            vc.showError(message: errorDescription ?? "unknown error")
                        }
                    } else {
                        Reducer.makeCommand(walletName: wallet.name ?? vc.walletNameHash, command: .rescanblockchain, param: "\(wallet.blockheight)") { [unowned vc = self] (object, errorDescription) in
                            vc.connectingView.removeConnectingView()
                            vc.walletSuccessfullyCreated(wallet: wallet)
                        }
                    }
                } else {
                    vc.showError(message: errorDescription ?? "unknown error")
                }
            } else {
                vc.showError(message: errorDescription ?? "unknown error")
            }
        }
    }
    
    func saveWallet(wallet: WalletStruct) {
        CoreDataService.saveEntity(dict: walletDict, entityName: .wallets) { [unowned vc = self] (success, errorDescription) in
            if success {
                vc.rescan(wallet: wallet)
            } else {
                vc.showError(message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
            }
        }
    }
    
    func showError(message: String) {
        connectingView.removeConnectingView()
        showAlert(vc: self, title: "Error", message: message)
    }
    
    func updateLabel(text: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.connectingView.label.text = text
        }
    }
    
    func parseWalletCreateError(wallet: WalletStruct, errorDescription: String?) {
        if errorDescription != nil {
            if errorDescription!.contains("already exists") {
                saveWallet(wallet: wallet)
            } else {
                showError(message: "Import error, error creating wallet: \(errorDescription!)")
            }
        } else {
            showError(message: "Import error: error creating wallet")
        }
    }
    
    private func importWallet() {
        connectingView.addConnectingView(vc: self, description: "creating account on your node")
        let wallet = WalletStruct(dictionary: walletDict)
        var addToKeypool = false
        var addToInternal = false
        if wallet.type == "DEFAULT" {
            addToKeypool = true
            addToInternal = true
        }
        let primaryDescParams = "[{ \"desc\": \"\(wallet.descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"Godion\", \"keypool\": \(addToKeypool), \"internal\": false }]"
        let changeDescParams = "[{ \"desc\": \"\(wallet.changeDescriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"keypool\": \(addToKeypool), \"internal\": \(addToInternal) }]"
        
        
        func saveSeed(seedDict: [String:Any]) {
            CoreDataService.saveEntity(dict: seedDict, entityName: .seeds) { [unowned vc = self] (success, errorDesc) in
                if success {
                    vc.importedOrRecovered = "recovered"
                    vc.words = nil
                    vc.saveWallet(wallet: wallet)
                } else {
                    vc.showError(message: "Error saving your seed.")
                }
            }
        }
        
        func encryptSeed() {
            let unencryptedSeed = words!.dataUsingUTF8StringEncoding
            Encryption.encryptData(dataToEncrypt: unencryptedSeed) { [unowned vc = self] (encryptedSeed, error) in
                if encryptedSeed != nil {
                    let dict = ["seed":encryptedSeed!,"id":UUID()] as [String:Any]
                    saveSeed(seedDict: dict)
                } else {
                    vc.showError(message: "Error encrypting your seed.")
                }
            }
        }
        
        func filter() {
            if words != nil {
                encryptSeed()
            } else {
                saveWallet(wallet: wallet)
            }
        }
        
        func parseImportChangeResult(dict: NSDictionary) {
            if let success = dict["success"] as? Bool {
                if success {
                    filter()
                } else {
                    showError(message: "Import error, error importing change descriptor")
                }
            } else {
                showError(message: "Import error, error importing change descriptor")
            }
        }
        
        func parseImportPrimaryResult(dict: NSDictionary) {
            if let success = dict["success"] as? Bool {
                if success {
                    importChangeDesc()
                } else {
                    showError(message: "Import error, error importing primary descriptor")
                }
            } else {
                showError(message: "Import error, error importing primary descriptor")
            }
        }
        
        func parseChangeResult(result: NSArray) {
            if let dict = result[0] as? NSDictionary {
                parseImportChangeResult(dict: dict)
            } else {
                showError(message: "Import error, error importing change descriptor")
            }
        }
        
        func parsePrimaryResult(result: NSArray) {
            if let dict = result[0] as? NSDictionary {
                parseImportPrimaryResult(dict: dict)
            } else {
                showError(message: "Import error, error importing primary descriptor")
            }
        }
        
        func importChangeDesc() {
            updateLabel(text: "importing change descriptor")
            Reducer.makeCommand(walletName: wallet.name ?? walletNameHash, command: .importmulti, param: changeDescParams) { [unowned vc = self] (object, errorDescription) in
                if let result = object as? NSArray {
                    if result.count > 0 {
                        parseChangeResult(result: result)
                    } else {
                        vc.showError(message: "Import error, error importing change descriptor")
                    }
                } else {
                    vc.showError(message: "Import error, error importing change descriptor: \(errorDescription ?? "unknown error")")
                }
            }
        }
        
        func importPrimaryDesc() {
            updateLabel(text: "importing primary descriptor")
            Reducer.makeCommand(walletName: wallet.name ?? walletNameHash, command: .importmulti, param: primaryDescParams) { [unowned vc = self] (object, errorDescription) in
                if let result = object as? NSArray {
                    if result.count > 0 {
                        parsePrimaryResult(result: result)
                    } else {
                        vc.showError(message: "Import error, error importing primary descriptor")
                    }
                } else {
                    vc.showError(message: "Import error, error importing primary descriptor: \(errorDescription ?? "unknown error")")
                }
            }
        }
        
        func createWallet() {
            let param = "\"\(wallet.name ?? walletNameHash)\", true, true, \"\", true"
            Reducer.makeCommand(walletName: "", command: .createwallet, param: param) { [unowned vc = self] (object, errorDescription) in
                if let _ = object as? NSDictionary {
                    importPrimaryDesc()
                } else {
                    vc.parseWalletCreateError(wallet: wallet, errorDescription: errorDescription)
                }
            }
        }
        
        createWallet()
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        if words == nil {
            importWallet()
        } else {
            importAccounts()
        }
    }
    
    private func importDescriptor(param: String, desc: String, completion: @escaping ((success: Bool, errorMessage: String?)) -> Void) {
        Reducer.makeCommand(walletName: walletNameHash, command: .importmulti, param: param) { (object, errorDescription) in
            if let result = object as? NSArray {
                if result.count > 0 {
                    if let dict = result[0] as? NSDictionary {
                        if let success = dict["success"] as? Bool {
                            if success {
                                completion((true, nil))
                            } else {
                                completion((false, errorDescription ?? "Import error, error importing descriptor"))
                            }
                        }
                    } else {
                        completion((false, errorDescription ?? "Import error, error importing descriptor"))
                    }
                } else {
                    completion((false, errorDescription ?? "Import error, error importing descriptor"))
                }
            } else {
                completion((false, errorDescription ?? "Import error, error importing descriptor"))
            }
        }
    }
    
    private func importPrimDescriptors(index: Int, wallet: WalletStruct) {
        if index < primaryDescriptors.count {
             updateLabel(text: "importing receive descriptor #\(index + 1) out of \(primaryDescriptors.count)")
            let descriptor = primaryDescriptors[index]
            var addToKeypool = false
            var addToInternal = false
            if descriptor.contains("/84'/1'/0'") || descriptor.contains("/84'/0'/0'") || descriptor.contains("/44'/1'/0'") || descriptor.contains("/44'/0'/0'") || descriptor.contains("/49'/1'/0'") || descriptor.contains("/49'/0'/0'") {
                if descriptor.contains("/0/*") {
                    addToKeypool = true
                    addToInternal = false
                } else if descriptor.contains("/1/*") {
                    addToKeypool = true
                    addToInternal = true
                }
            }
            var params = ""
            if addToInternal {
                params = "[{ \"desc\": \"\(descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"keypool\": true, \"internal\": true }]"
            } else {
                params = "[{ \"desc\": \"\(descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"Gordian\", \"keypool\": \(addToKeypool), \"internal\": \(addToInternal) }]"
            }
            importDescriptor(param: params, desc: descriptor) { [unowned vc = self] (success, errorMessage) in
                if success {
                    vc.importPrimDescriptors(index: index + 1, wallet: wallet)
                } else {
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error importing", message: errorMessage ?? "unknown error")
                }
            }
        } else {
            importChangeDescriptors(index: 0, wallet: wallet)
        }
    }
    
    private func importChangeDescriptors(index: Int, wallet: WalletStruct) {
        if index < changeDescriptors.count {
            updateLabel(text: "importing change descriptor #\(index + 1) out of \(changeDescriptors.count)")
            let descriptor = changeDescriptors[index]
            var addToKeypool = false
            var addToInternal = false
            if descriptor.contains("/84'/1'/0'") || descriptor.contains("/84'/0'/0'") || descriptor.contains("/44'/1'/0'") || descriptor.contains("/44'/0'/0'") || descriptor.contains("/49'/1'/0'") || descriptor.contains("/49'/0'/0'") {
                if descriptor.contains("/0/*") {
                    addToKeypool = true
                    addToInternal = false
                } else if descriptor.contains("/1/*") {
                    addToKeypool = true
                    addToInternal = true
                }
            }
            var params = ""
            if addToInternal {
                params = "[{ \"desc\": \"\(descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"keypool\": true, \"internal\": true }]"
            } else {
                params = "[{ \"desc\": \"\(descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"Gordian\", \"keypool\": \(addToKeypool), \"internal\": \(addToInternal) }]"
            }
            importDescriptor(param: params, desc: descriptor) { [unowned vc = self] (success, errorMessage) in
                if success {
                    vc.importChangeDescriptors(index: index + 1, wallet: wallet)
                } else {
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error importing", message: errorMessage ?? "unknown error")
                }
            }
        } else {
            // finished here...
            saveWallet(wallet: wallet)
        }
    }
    
    private func importAccounts() {
        connectingView.addConnectingView(vc: self, description: "creating account on your node")
        let wallet = WalletStruct(dictionary: walletDict)
        
        func createWallet() {
            let param = "\"\(wallet.name ?? walletNameHash)\", true, true, \"\", true"
            Reducer.makeCommand(walletName: "", command: .createwallet, param: param) { [unowned vc = self] (object, errorDescription) in
                if let _ = object as? NSDictionary {
                    vc.importPrimDescriptors(index: 0, wallet: wallet)
                } else {
                    vc.parseWalletCreateError(wallet: wallet, errorDescription: errorDescription)
                }
            }
        }
        
        createWallet()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segue.identifier
        if id == "addLabelToRecoveredAccount" {
            if let vc = segue.destination as? WalletCreatedSuccessViewController {
                vc.isColdcard = false
                vc.wallet = walletDict
                vc.isOnlyAddingLabel = true
            }
        }
    }

}
