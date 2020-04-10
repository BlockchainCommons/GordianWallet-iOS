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
        walletName.text = reducedName(name: wallet.name!)
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
        
        DispatchQueue.main.async {
                        
            let cell = tableView.cellForRow(at: indexPath)!
            
            UIView.animate(withDuration: 0.2, animations: {
                
                cell.alpha = 0
                
            }) { (_) in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    cell.alpha = 1
                    
                }) { [unowned vc = self] (_) in
                    
                    vc.confirm(wallet: wallet)
                    
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
        CoreDataService.retrieveEntity(entityName: .wallets) { [unowned vc = self] (entity, errorDescription) in
            
            if errorDescription == nil {
                
                if entity != nil {
                    
                    if entity!.count > 0 {
                        
                        getActiveWalletNow { (wallet, error) in
                            
                            if !error && wallet != nil {
                             
                                for w in entity! {
                                    
                                    if w["id"] != nil {
                                        
                                        if !(w["isArchived"] as! Bool) && (w["id"] as! UUID) != wallet!.id && wallet!.nodeId == (w["nodeId"] as! UUID) {
                                            
                                            vc.wallets.append(w)
                                            
                                        }
                                        
                                    }
                                                                                                    
                                }
                                
                                DispatchQueue.main.async {
                                    
                                    vc.walletTable.reloadData()
                                    
                                }
                                
                            } else {
                             
                                showAlert(vc: vc, title: "No active wallet", message: "")
                                
                            }
                            
                        }
                        
                    } else {
                        
                        showAlert(vc: vc, title: "No wallets", message: "")
                        
                    }
                    
                } else {
                    
                    showAlert(vc: vc, title: "Error", message: "We had an error trying to get your wallets")
                    
                }
                
            } else {
                
                showAlert(vc: vc, title: "Error", message: "We had an error trying to get your wallets: \(errorDescription!)")
                
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

            alert.addAction(UIAlertAction(title: "Yes, sweep now", style: .default, handler: { [unowned vc = self] action in
                
                vc.sweepNow(receivingWallet: wallet)
                
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
        
        let index = wallet.index + 1
        let param = "\"\(wallet.descriptor)\", [\(index),\(index)]"
        Reducer.makeCommand(walletName: "", command: .deriveaddresses, param: param) { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSArray {
                
                vc.updateIndex(wallet: wallet)
                
                if let address = result[0] as? String {
                    
                    vc.receivingAddress = address
                    vc.getInputs()
                    
                } else {
                    
                    vc.showError(title: "Error Fetching address", message: "")
                    
                }
                
            } else {
                
                vc.showError(title: "Error Fetching address", message: "\(errorDesc ?? "")")
                
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
        Reducer.makeCommand(walletName: wallet.name!, command: .getsweeptoaddress, param: param) { [unowned vc = self] (object, errorDesc) in
            if let address = object as? String {
                vc.receivingAddress = address
                vc.getInputs()
                
            } else {
                vc.showError(title: "Error Fetching address", message: "")
                
            }
            
        }
        
    }
    
    private func getInputs() {
        
        updateStatusLabel(text: "fetching utxos")
        
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            
            if !error && wallet != nil {
             
                Reducer.makeCommand(walletName: wallet!.name!, command: .listunspent, param: "0") { (object, errorDesc) in
                    
                    if let resultArray = object as? NSArray {
                        
                        vc.parseUnspent(utxos: resultArray, wallet: wallet!)
                        
                    } else {
                        
                        vc.showError(title: "Error Fetching address", message: "")
                        
                    }
                    
                }
                
            } else {
             
                vc.showError(title: "No active wallet", message: "")
                
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
        
        let param = "''\(processedInputs())'', ''{\"\(receivingAddress)\":\(rounded(number: self.totalAmount))}'', 0, ''{\"includeWatching\": true, \"replaceable\": true, \"conf_target\": \(feeTarget()), \"subtractFeeFromOutputs\": [0], \"changeAddress\": \"\(receivingAddress)\"}'', true"
        Reducer.makeCommand(walletName: wallet.name!, command: .walletcreatefundedpsbt, param: param) { [unowned vc = self] (object, errorDesc) in
            
            if let psbtDict = object as? NSDictionary {
                
                if let psbt = psbtDict["psbt"] as? String {
                    
                    vc.filterSigning(wallet: wallet, psbt: psbt)
                    
                } else {
                    
                    vc.showError(title: "Error building psbt", message: "")
                    
                }
                
            } else {
                
                vc.showError(title: "Error building psbt", message: "")
                
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
        
        let param = "\"\(psbt)\", true, \"ALL\", true"
        Reducer.makeCommand(walletName: wallet.name!, command: .walletprocesspsbt, param: param) { [unowned vc = self] (object, errorDesc) in
            
            if let dict = object as? NSDictionary {
                
                if let processedPsbt = dict["psbt"] as? String {
                    
                    vc.decodePsbt(psbt: processedPsbt, wallet: wallet)
                    
                } else {
                 
                    vc.showError(title: "Error", message: "Error decoding transaction: \(errorDesc ?? "")")
                    
                }
                
            }
            
        }
        
    }
    
    private func decodePsbt(psbt: String, wallet: WalletStruct) {
        
        updateStatusLabel(text: "decoding psbt")
        
        let param = "\"\(psbt)\""
        Reducer.makeCommand(walletName: wallet.name!, command: .decodepsbt, param: param) { [unowned vc = self] (object, errorDesc) in
            
            if let dict = object as? NSDictionary {
                
                vc.parsePsbt(decodePsbt: dict, psbt: psbt, wallet: wallet)
                
            } else {
                
                vc.showError(title: "Error", message: "Error decoding transaction")
                
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
            if let bip32path = BIP32Path(path) {
                
                KeyFetcher.privKey(path: bip32path) { [unowned vc = self] (privKey, error) in
                    
                    if !error {
                        
                        privateKeys.append(privKey!)
                        
                        if i + 1 == inputs.count {
                            
                            vc.signPsbt(psbt: psbt, privateKeys: privateKeys, wallet: wallet)
                            
                        }
                        
                    } else {
                        
                        vc.showError(title: "Error", message: "Failed fetching private key at path \(bip32path)")
                        
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
        signer.signTransactionOffline(unsignedTx: psbt) { [unowned vc = self] (signedTx) in

            if signedTx != nil {

                vc.signedTx = signedTx!
                vc.goConfirm()

            }

        }
        
    }
    
    private func signLegacy(psbt: String) {
        
        let signer = OfflineSignerLegacy()
        signer.signTransactionOffline(unsignedTx: psbt) { [unowned vc = self] (signedTx) in

            if signedTx != nil {

                vc.signedTx = signedTx!
                vc.goConfirm()

            }

        }
        
    }
    
    func signSegwitWrapped(psbt: String) {
     
        let signer = OfflineSignerP2SHSegwit()
        signer.signTransactionOffline(unsignedTx: psbt) { [unowned vc = self] (signedTx) in

            if signedTx != nil {

                vc.signedTx = signedTx!
                vc.goConfirm()

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
        
        CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "index", newValue: wallet.index + 1, entityName: .wallets) { [unowned vc = self] (success, errorDesc) in
            
            if !success {
                
                vc.showError(title: "Error", message: "error updating index: \(errorDesc ?? "")")
                
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
                vc.doneBlock = { [unowned thisVc = self] result in
                 
                    DispatchQueue.main.async {
                        
                        thisVc.dismiss(animated: true) {
                            
                            thisVc.doneBlock!(true)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }
    

}
