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
    @IBOutlet weak var scanSubAccountsOutlet: UIButton!
    
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
        
        if words == nil {
            scanSubAccountsOutlet.alpha = 0
        } else {
            scanSubAccountsOutlet.alpha = 1
        }
        
        loadAddresses()
    }
    
    @IBAction func scanSubAccountsAction(_ sender: Any) {
        scanSubAccounts()
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
                vc.removeLoader()
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
    
    private func scanSubAccounts() {
        if words != nil {
            connectingView.addConnectingView(vc: self, description: "scanning subaccounts, this can take a minute...")
            var accountLessPath = ""
            var cointType = "0"
            let derivation = walletDict["derivation"] as! String
            if derivation.contains("/1'/") {
                // its testnet
                cointType = "1"
            }
            if derivation.contains("84") {
                accountLessPath = "m/84'/\(cointType)'"
            } else if derivation.contains("49") {
                accountLessPath = "m/49'/\(cointType)'"
            } else if derivation.contains("44") {
                accountLessPath = "m/44'/\(cointType)'"
            }
            CheckSubAccounts.check(words: words!, derivation: accountLessPath) { [unowned vc = self] (subAccounts) in
                if subAccounts != nil {
                    var subAccountsWithHistory:[[String:Any]] = []
                    for (i, subAccount) in subAccounts!.enumerated() {
                        let hasHistory = subAccount["hasHistory"] as! Bool
                        if hasHistory {
                            subAccountsWithHistory.append(subAccount)
                        }
                        if i + 1 == subAccounts!.count {
                            vc.connectingView.removeConnectingView()
                            if subAccountsWithHistory.count > 0 {
                                var derivs = ""
                                for sub in subAccountsWithHistory {
                                    let path = sub["derivation"] as! String
                                    derivs += path + " "
                                }
                                vc.promptToRecoverSubAccounts(accounts: derivs)
                            } else {
                               showAlert(vc: vc, title: "No sub account history detected", message: "Only the first 5 addresses for sub accounts 0 - 10 are scanned for history.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func promptToRecoverSubAccounts(accounts: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Transaction history detected on sub accounts!", message: "We detected transaction history on sub accounts: \(accounts)", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func importSubAccounts() {
        
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
    
    private func importWallet() {
        connectingView.addConnectingView(vc: self, description: "creating account on your node")
        let wallet = WalletStruct(dictionary: walletDict)
        var importedOrRecovered = "imported"
        var addToKeypool = false
        var addToInternal = false
        if wallet.type == "DEFAULT" {
            addToKeypool = true
            addToInternal = true
        }
        let primaryDescParams = "[{ \"desc\": \"\(wallet.descriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"label\": \"StandUp\", \"keypool\": \(addToKeypool), \"internal\": false }]"
        let changeDescParams = "[{ \"desc\": \"\(wallet.changeDescriptor)\", \"timestamp\": \"now\", \"range\": [0,2500], \"watchonly\": true, \"keypool\": \(addToKeypool), \"internal\": \(addToInternal) }]"
        
        func showError(message: String) {
            connectingView.removeConnectingView()
            showAlert(vc: self, title: "Error", message: message)
        }
        
        func updateLabel(text: String) {
            DispatchQueue.main.async { [unowned vc = self] in
                vc.connectingView.label.text = text
            }
        }
        
        func deactivateAllAccountsAndActivateNewAccount() {
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
        
        func walletSuccessfullyCreated() {
            DispatchQueue.main.async { [unowned vc = self] in
                deactivateAllAccountsAndActivateNewAccount()
                let alert = UIAlertController(title: "Account \(importedOrRecovered)!", message: "Your \(importedOrRecovered) account will now show up in \"Accounts\", a blockchain rescan has been initiated", preferredStyle: .actionSheet)
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
        
        func rescanFrom(param: String) {
            Reducer.makeCommand(walletName: wallet.name ?? walletNameHash, command: .rescanblockchain, param: param) { [unowned vc = self] (object, errorDescription) in
                vc.connectingView.removeConnectingView()
                walletSuccessfullyCreated()
            }
        }
        
        func rescan() {
            updateLabel(text: "Initiating a rescan")
            Reducer.makeCommand(walletName: wallet.name ?? walletNameHash, command: .getblockchaininfo, param: "") { [unowned vc = self] (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    if let pruned = dict["pruned"] as? Bool {
                        if pruned {
                            if let pruneHeight = dict["pruneheight"] as? Int {
                                if wallet.blockheight == 0 {
                                    showAlert(vc: vc, title: "Pruned Node", message: "We have initiated a rescan from your pruned node's blockheight \(pruneHeight) as that is as far back as we can go, if you have transactions that precede this blockheight they will not show up unless you reindex your node.")
                                    rescanFrom(param: "\(pruneHeight)")
                                } else if pruneHeight > wallet.blockheight {
                                    showAlert(vc: vc, title: "Reindex required!", message: "Your pruned node can not rescan beyond its prune height, in order to rescan to the block where this wallet was born a full blockchain reindex is required. We have initiated a rescan from block \(pruneHeight).")
                                    rescanFrom(param: "\(pruneHeight)")
                                } else {
                                    rescanFrom(param: "\(wallet.blockheight)")
                                }
                            } else {
                                showError(message: errorDescription ?? "unknown error")
                            }
                        } else {
                            Reducer.makeCommand(walletName: wallet.name ?? vc.walletNameHash, command: .rescanblockchain, param: "\(wallet.blockheight)") { [unowned vc = self] (object, errorDescription) in
                                vc.connectingView.removeConnectingView()
                                walletSuccessfullyCreated()
                            }
                        }
                    } else {
                        showError(message: errorDescription ?? "unknown error")
                    }
                } else {
                    showError(message: errorDescription ?? "unknown error")
                }
            }
        }
        
        func saveWallet() {
            CoreDataService.saveEntity(dict: walletDict, entityName: .wallets) { (success, errorDescription) in
                if success {
                    rescan()
                } else {
                    showError(message: "Import error, unable to save that wallet: \(errorDescription ?? "unknown error")")
                }
            }
        }
        
        func saveSeed(seedDict: [String:Any]) {
            CoreDataService.saveEntity(dict: seedDict, entityName: .seeds) { [unowned vc = self] (success, errorDesc) in
                if success {
                    importedOrRecovered = "recovered"
                    vc.words = nil
                    saveWallet()
                } else {
                    showError(message: "Error saving your seed.")
                }
            }
        }
        
        func encryptSeed() {
            let unencryptedSeed = words!.dataUsingUTF8StringEncoding
            Encryption.encryptData(dataToEncrypt: unencryptedSeed) { (encryptedSeed, error) in
                if encryptedSeed != nil {
                    let dict = ["seed":encryptedSeed!,"id":UUID()] as [String:Any]
                    saveSeed(seedDict: dict)
                } else {
                    showError(message: "Error encrypting your seed.")
                }
            }
        }
        
        func filter() {
            if words != nil {
                encryptSeed()
            } else {
                saveWallet()
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
            Reducer.makeCommand(walletName: wallet.name ?? walletNameHash, command: .importmulti, param: changeDescParams) { (object, errorDescription) in
                if let result = object as? NSArray {
                    if result.count > 0 {
                        parseChangeResult(result: result)
                    } else {
                        showError(message: "Import error, error importing change descriptor")
                    }
                } else {
                    showError(message: "Import error, error importing change descriptor: \(errorDescription ?? "unknown error")")
                }
            }
        }
        
        func importPrimaryDesc() {
            updateLabel(text: "importing primary descriptor")
            Reducer.makeCommand(walletName: wallet.name ?? walletNameHash, command: .importmulti, param: primaryDescParams) { (object, errorDescription) in
                if let result = object as? NSArray {
                    if result.count > 0 {
                        parsePrimaryResult(result: result)
                    } else {
                        showError(message: "Import error, error importing primary descriptor")
                    }
                } else {
                    showError(message: "Import error, error importing primary descriptor: \(errorDescription ?? "unknown error")")
                }
            }
        }
        
        func parseWalletCreateError(errorDescription: String?) {
            if errorDescription != nil {
                if errorDescription!.contains("already exists") {
                    saveWallet()
                } else {
                    showError(message: "Import error, error creating wallet: \(errorDescription!)")
                }
            } else {
                showError(message: "Import error: error creating wallet")
            }
        }
        
        func createWallet() {
            let param = "\"\(wallet.name ?? walletNameHash)\", true, true, \"\", true"
            Reducer.makeCommand(walletName: "", command: .createwallet, param: param) { (object, errorDescription) in
                if let _ = object as? NSDictionary {
                    importPrimaryDesc()
                } else {
                    parseWalletCreateError(errorDescription: errorDescription)
                }
            }
        }
        
        createWallet()
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        importWallet()
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
