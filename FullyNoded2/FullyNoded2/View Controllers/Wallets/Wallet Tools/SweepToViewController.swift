//
//  SweepToViewController.swift
//  FullyNoded2
//
//  Created by Peter on 19/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class SweepToViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var doneBlock: ((Bool) -> Void)?
    let connectingView = ConnectingView()
    var signedTx = ""
    var inputs = [String]()
    var totalAmount = 0.0
    var receivingAddress = ""
    var wallets = [[String:Any]]()
    @IBOutlet var walletTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        walletTable.delegate = self
        walletTable.dataSource = self
        walletTable.clipsToBounds = true
        walletTable.layer.cornerRadius = 8
        walletTable.setContentOffset(.zero, animated: true)
        loadWallets()

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return wallets.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "walletCell", for: indexPath)
        
        cell.selectionStyle = .blue
        cell.clipsToBounds = true
        cell.layer.cornerRadius = 8
        
        let walletLabel = cell.viewWithTag(1) as! UILabel
        let walletName = cell.viewWithTag(2) as! UILabel
        let walletDerivation = cell.viewWithTag(3) as! UILabel
        let walletBirthdate = cell.viewWithTag(4) as! UILabel
        let walletType = cell.viewWithTag(5) as! UILabel
        let walletNetwork = cell.viewWithTag(6) as! UILabel
        let walletBalance = cell.viewWithTag(7) as! UILabel
        
        let wallet = WalletStruct(dictionary: wallets[indexPath.section])
        walletLabel.text = wallet.label
        walletName.text = reducedName(name: wallet.name)
        walletBalance.text = "\(wallet.lastBalance)"
        walletDerivation.text = wallet.derivation + "/0"
        walletBirthdate.text = getDate(unixTime: wallet.birthdate)
        walletType.text = wallet.type
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet.descriptor)
        
        switch wallet.type {
            
        case "DEFAULT":
            
            walletType.text = "Single-sig"
            
        case "MULTI":
            
            walletType.text = "Multi-sig \(str.mOfNType)"
            
        default:
            break
        }
        
        if wallet.derivation.contains("1") {
            
            walletNetwork.text = "Testnet"
            
        } else {
            
            walletNetwork.text = "Mainnet"
            
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 30
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30)
        return header
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let wallet = WalletStruct(dictionary: wallets[indexPath.section])
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
            let cell = tableView.cellForRow(at: indexPath)!
            
            UIView.animate(withDuration: 0.2, animations: {
                
                cell.alpha = 0
                
            }) { (_) in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    cell.alpha = 1
                    
                }) { (_) in
                    
                    self.confirm(wallet: wallet)
                    
                }
                
            }
            
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    private func loadWallets() {
        
        wallets.removeAll()
        let cd = CoreDataService()
        cd.retrieveEntity(entityName: .wallets) { (entity, errorDescription) in
            
            if errorDescription == nil {
                
                if entity != nil {
                    
                    if entity!.count > 0 {
                        
                        getActiveWalletNow { (wallet, error) in
                            
                            if !error && wallet != nil {
                             
                                for w in entity! {
                                    
                                    if !(w["isArchived"] as! Bool) && (w["id"] as! UUID) != wallet!.id && wallet!.nodeId == (w["nodeId"] as! UUID) {
                                        
                                        self.wallets.append(w)
                                        
                                    }
                                                                
                                }
                                
                                DispatchQueue.main.async {
                                    
                                    self.walletTable.reloadData()
                                    
                                }
                                
                            } else {
                             
                                showAlert(vc: self, title: "No active wallet", message: "")
                                
                            }
                            
                        }
                        
                    } else {
                        
                        showAlert(vc: self, title: "No wallets", message: "")
                        
                    }
                    
                } else {
                    
                    showAlert(vc: self, title: "Error", message: "We had an error trying to get your wallets")
                    
                }
                
            } else {
                
                showAlert(vc: self, title: "Error", message: "We had an error trying to get your wallets: \(errorDescription!)")
                
            }
            
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
    
    private func confirm(wallet: WalletStruct) {
        
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Sweep funds to the selected wallet?", message: "Tapping yes means the current active wallet will be emptied and all funds sent to the selected wallet.", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Yes, sweep now", style: .default, handler: { action in
                
                self.sweepNow(receivingWallet: wallet)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    private func sweepNow(receivingWallet: WalletStruct) {
        
        connectingView.addConnectingView(vc: self, description: "getting receiving address")
        
        let parser = DescriptorParser()
        let str = parser.descriptor(receivingWallet.descriptor)
        
        if str.isMulti {
            
            self.getMsigAddress(wallet: receivingWallet)
            
        } else {
            
            self.filterDerivation(str: str, wallet: receivingWallet)
            
        }
        
    }
    
    private func getMsigAddress(wallet: WalletStruct) {
        
        let reducer = Reducer()
        let index = wallet.index + 1
        let param = "\"\(wallet.descriptor)\", [\(index),\(index)]"
        
        reducer.makeCommand(walletName: wallet.name, command: .deriveaddresses, param: param) {
            
            if !reducer.errorBool {
                
                self.updateIndex(wallet: wallet)
                
                if let address = reducer.arrayToReturn?[0] as? String {
                    
                    self.receivingAddress = address
                    self.getInputs()
                    
                } else {
                    
                    self.showError(title: "Error Fetching address", message: "")
                    
                }
                
            } else {
                
                self.showError(title: "Error Fetching address", message: "\(reducer.errorDescription)")
                
            }
            
        }
        
    }
    
    private func filterDerivation(str: DescriptorStruct, wallet: WalletStruct) {
        
        var param = ""
        
        if str.isP2PKH || str.isBIP44 || wallet.derivation.contains("44") {
            
            param = "\"\", \"legacy\""
            
        } else if str.isP2WPKH || str.isBIP84 || wallet.derivation.contains("84")  {
            
            param = "\"\", \"bech32\""
            
        } else if str.isP2SHP2WPKH || str.isBIP49 || wallet.derivation.contains("49")  {
            
            param = "\"\", \"p2sh-segwit\""
            
        }
        
        getAddress(param: param, wallet: wallet)
        
    }
    
    private func getAddress(param: String, wallet: WalletStruct) {
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: wallet.name, command: .getnewaddress, param: param) {
            
            if !reducer.errorBool {
                
                if let address = reducer.stringToReturn {
                    
                    self.receivingAddress = address
                    self.getInputs()
                    
                } else {
                    
                    self.showError(title: "Error Fetching address", message: "")
                    
                }
                
            } else {
                
                self.showError(title: "Error Fetching address", message: reducer.errorDescription)
                
            }
            
        }
        
    }
    
    private func getInputs() {
        
        updateStatusLabel(text: "fetching utxos")
        
        getActiveWalletNow { (wallet, error) in
            
            if !error && wallet != nil {
             
                let reducer = Reducer()
                reducer.makeCommand(walletName: wallet!.name, command: .listunspent, param: "0") {
                    
                    if !reducer.errorBool {
                        
                        if let resultArray = reducer.arrayToReturn {
                            
                            self.parseUnspent(utxos: resultArray, wallet: wallet!)
                            
                        } else {
                            
                            self.showError(title: "Error Fetching address", message: "")
                            
                        }
                        
                    } else {
                        
                        self.showError(title: "Error Fetching address", message: reducer.errorDescription)
                        
                    }
                    
                }
                
            } else {
             
                self.showError(title: "No active wallet", message: "")
                
            }
            
        }
        
    }
    
    private func parseUnspent(utxos: NSArray, wallet: WalletStruct) {
        
        updateStatusLabel(text: "parsing utxos")
        
        for utxo in utxos {
            
            let dict = utxo as! NSDictionary
            let amount = dict["amount"] as! Double
            let txid = dict["txid"] as! String
            let vout = dict["vout"] as! Int
            totalAmount += amount
            let input = "{\"txid\":\"\(txid)\", \"vout\":\(vout)}"
            inputs.append(input)
            
        }
        
        buildPsbt(wallet: wallet)
        
    }
    
    private func buildPsbt(wallet: WalletStruct) {
        
        updateStatusLabel(text: "building psbt")
        
        let reducer = Reducer()
        let param = "''\(processedInputs())'', ''{\"\(receivingAddress)\":\(rounded(number: self.totalAmount))}'', 0, ''{\"includeWatching\": true, \"replaceable\": true, \"conf_target\": \(feeTarget()), \"subtractFeeFromOutputs\": [0], \"changeAddress\": \"\(receivingAddress)\"}'', true"
        reducer.makeCommand(walletName: wallet.name, command: .walletcreatefundedpsbt, param: param) {
            
            if !reducer.errorBool {
                
                if let psbtDict = reducer.dictToReturn {
                    
                    if let psbt = psbtDict["psbt"] as? String {
                        
                        self.filterSigning(wallet: wallet, psbt: psbt)
                        
                    } else {
                        
                        self.showError(title: "Error building psbt", message: "")
                        
                    }
                    
                } else {
                    
                    self.showError(title: "Error building psbt", message: "")
                    
                }
                
            } else {
                
                self.showError(title: "Error", message: reducer.errorDescription)
                
            }
            
        }
        
    }
    
    private func filterSigning(wallet: WalletStruct, psbt: String) {
        
        updateStatusLabel(text: "device signing psbt")
        
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet.descriptor)
     
        if wallet.type == "DEFAULT" || wallet.type == "CUSTOM" {
            
            if str.isHot || String(data: wallet.seed, encoding: .utf8) != "no seed" || wallet.xprv != nil {
                
                if str.isP2WPKH || str.isBIP84 {
                    
                    signSegwit(psbt: psbt)
                    
                } else if str.isP2SHP2WPKH || str.isBIP49 {
                    
                    signSegwitWrapped(psbt: psbt)
                    
                } else if str.isP2PKH || str.isBIP44 {
                    
                    signLegacy(psbt: psbt)
                    
                }
                
            } else {
               
                self.showError(title: "Error", message: "Unable to sign that as it is a cold wallet")
                
            }
            
            
        } else if wallet.type == "MULTI" {
         
            processPsbt(psbt: psbt, wallet: wallet)
            
        }
        
    }
    
    private func processPsbt(psbt: String, wallet: WalletStruct) {
        
        updateStatusLabel(text: "node signing psbt")
        
        let reducer = Reducer()
        let param = "\"\(psbt)\", true, \"ALL\", true"
        reducer.makeCommand(walletName: wallet.name, command: .walletprocesspsbt, param: param) {
            
            if !reducer.errorBool {
                
                if let dict = reducer.dictToReturn {
                    
                    if let processedPsbt = dict["psbt"] as? String {
                        
                        self.decodePsbt(psbt: processedPsbt, wallet: wallet)
                        
                    } else {
                     
                        self.showError(title: "Error", message: "Error decoding transaction: \(reducer.errorDescription)")
                        
                    }
                    
                }
                
            } else {
                
                self.showError(title: "Error", message: "Error decoding transaction: \(reducer.errorDescription)")
                
            }
            
        }
        
    }
    
    private func decodePsbt(psbt: String, wallet: WalletStruct) {
        
        updateStatusLabel(text: "decoding psbt")
        
        let reducer = Reducer()
        let param = "\"\(psbt)\""
        reducer.makeCommand(walletName: wallet.name, command: .decodepsbt, param: param) {
            
            if !reducer.errorBool {
                
                if let dict = reducer.dictToReturn {
                    
                    self.parsePsbt(decodePsbt: dict, psbt: psbt, wallet: wallet)
                    
                } else {
                    
                    self.showError(title: "Error", message: "Error decoding transaction")
                    
                }
                
            } else {
                
                self.showError(title: "Error", message: "Error decoding transaction: \(reducer.errorDescription)")
                
            }
            
        }
        
    }
    
    private func parsePsbt(decodePsbt: NSDictionary, psbt: String, wallet: WalletStruct) {
        
        updateStatusLabel(text: "parsing psbt")
        
        var privateKeys = [String]()
        let inputs = decodePsbt["inputs"] as! NSArray
        for (i, input) in inputs.enumerated() {
            
            let dict = input as! NSDictionary
            let bip32derivs = dict["bip32_derivs"] as! NSArray
            let bip32deriv = bip32derivs[0] as! NSDictionary
            let path = bip32deriv["path"] as! String
            let keyFetcher = KeyFetcher()
            if let bip32path = BIP32Path(path) {
                
                keyFetcher.privKey(path: bip32path) { (privKey, error) in
                    
                    if !error {
                        
                        privateKeys.append(privKey!)
                        
                        if i + 1 == inputs.count {
                            
                            self.signPsbt(psbt: psbt, privateKeys: privateKeys, wallet: wallet)
                            
                        }
                        
                    } else {
                        
                        self.showError(title: "Error", message: "Failed fetching private key at path \(bip32path)")
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    private func signPsbt(psbt: String, privateKeys: [String], wallet: WalletStruct) {
        
        updateStatusLabel(text: "signing psbt")
        
        let chain = network(path: wallet.derivation)
        
        do {
            
            var localPSBT = try PSBT(psbt, chain)
            
            for (i, key) in privateKeys.enumerated() {
                
                let pk = Key(key, chain)
                localPSBT.sign(pk!)
                
                if i + 1 == privateKeys.count {
                    
                    let final = localPSBT.finalize()
                    let complete = localPSBT.complete
                    
                    if final {
                        
                        if complete {
                            
                            if let hex = localPSBT.transactionFinal?.description {
                                
                                self.signedTx = hex
                                self.goConfirm()
                                
                                
                            } else {
                                
                                self.fallbackToNormalSigning(psbt: psbt, wallet: wallet)
                                
                            }
                            
                        } else {
                            
                            self.fallbackToNormalSigning(psbt: psbt, wallet: wallet)
                            
                        }
                                                
                    }
                    
                }
                
            }
            
        } catch {
            
            self.showError(title: "Error", message: "Local PSBT creation failed")
            
        }
        
    }
    
    private func fallbackToNormalSigning(psbt: String, wallet: WalletStruct) {
        
        if wallet.derivation.contains("84") {
            
            signSegwitWrapped(psbt: psbt)
            
        } else if wallet.derivation.contains("44") {
            
            signLegacy(psbt: psbt)
            
        } else if wallet.derivation.contains("49") {
            
            signSegwitWrapped(psbt: psbt)
            
        }
        
    }
    
    private func signSegwit(psbt: String) {
        
        let signer = NativeSegwitOfflineSigner()
        signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

            if signedTx != nil {

                self.signedTx = signedTx!
                self.goConfirm()

            }

        }
        
    }
    
    private func signLegacy(psbt: String) {
        
        let signer = OfflineSignerLegacy()
        signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

            if signedTx != nil {

                self.signedTx = signedTx!
                self.goConfirm()

            }

        }
        
    }
    
    func signSegwitWrapped(psbt: String) {
     
        let signer = OfflineSignerP2SHSegwit()
        signer.signTransactionOffline(unsignedTx: psbt) { (signedTx) in

            if signedTx != nil {

                self.signedTx = signedTx!
                self.goConfirm()

            }

        }
        
    }
    
    private func goConfirm() {
     
        DispatchQueue.main.async {
            
            self.connectingView.removeConnectingView()
            self.performSegue(withIdentifier: "goConfirmSweep", sender: self)
            
        }
        
    }
    
    private func updateIndex(wallet: WalletStruct) {
        
        let cd = CoreDataService()
        cd.updateEntity(id: wallet.id, keyToUpdate: "index", newValue: wallet.index + 1, entityName: .wallets) {
            
            if cd.errorBool {
                
                self.showError(title: "Error", message: "error updating index: \(cd.errorDescription)")
                
            }
            
        }
        
    }
    
    private func rounded(number: Double) -> Double {
        
        return Double(round(100000000*number)/100000000)
        
    }
    
    private func feeTarget() -> Int {
     
        return UserDefaults.standard.object(forKey: "feeTarget") as? Int ?? 432
        
    }
    
    private func processedInputs() -> String {
     
        var processedInputs = (inputs.description).replacingOccurrences(of: "\"{", with: "{")
        processedInputs = processedInputs.replacingOccurrences(of: "\\\"", with: "\"")
        return processedInputs.replacingOccurrences(of: "}\"", with: "}")
        
    }
    
    private func updateStatusLabel(text: String) {
     
        DispatchQueue.main.async {
            
            self.connectingView.label.text = text
            
        }
        
    }
    
    private func showError(title: String, message: String) {
        
        self.connectingView.removeConnectingView()
        showAlert(vc: self, title: title, message: message)
        
    }
    
    private func reducedName(name: String) -> String {
        
        let first = String(name.prefix(5))
        let last = String(name.suffix(5))
        return "\(first)*****\(last).dat"
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch segue.identifier {
            
        case "goConfirmSweep":
            
            if let vc = segue.destination as? ConfirmViewController {
                
                vc.sweeping = true
                vc.signedRawTx = self.signedTx
                vc.doneBlock = { result in
                 
                    DispatchQueue.main.async {
                        
                        self.dismiss(animated: true) {
                            
                            self.doneBlock!(true)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }
    

}
