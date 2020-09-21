//
//  CreateRawTxViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class CreateRawTxViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UINavigationControllerDelegate {
    
    var walletName:String!
    var spendable = Double()
    var rawTxUnsigned = String()
    var incompletePsbt = String()
    var rawTxSigned = String()
    var amountAvailable = Double()
    var address = String()
    let nextButton = UIButton()
    var amount = String()
    let rawDisplayer = RawDisplayer()
    var isFirstTime = Bool()
    var outputs = [Any]()
    var outputsString = ""
    var recipients = [String]()
    
    @IBOutlet weak var addOutlet: UIButton!
    @IBOutlet var addressInput: UITextView!
    @IBOutlet var amountInput: UITextField!
    @IBOutlet var amountLabel: UILabel!
    @IBOutlet var actionOutlet: UIButton!
    @IBOutlet var receivingLabel: UILabel!
    @IBOutlet var outputsTable: UITableView!
    @IBOutlet weak var availableBalance: UILabel!
    @IBOutlet weak var createOutlet: UIButton!
    @IBOutlet weak var feeSliderOutlet: UISlider!
    @IBOutlet weak var blockTargetOutlet: UILabel!
    @IBOutlet weak var scannerButton: UIBarButtonItem!
    @IBOutlet weak var spendChangeSwitch: UISwitch!
    @IBOutlet weak var spendDustSwitch: UISwitch!
    @IBOutlet weak var doNotSpendChangeLabel: UILabel!
    @IBOutlet weak var doNotSpendDustLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let creatingView = ConnectingView()
    var outputArray = [[String:String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        amountInput.delegate = self
        addressInput.delegate = self
        outputsTable.delegate = self
        outputsTable.dataSource = self
        navigationController?.delegate = self
        outputsTable.tableFooterView = UIView(frame: .zero)
        outputsTable.alpha = 0
        availableBalance.alpha = 0
        addTapGesture()
        addressInput.layer.borderWidth = 1.0
        addressInput.layer.borderColor = UIColor.darkGray.cgColor
        addressInput.clipsToBounds = true
        addressInput.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        imageView.layer.magnificationFilter = .nearest
        feeSliderOutlet.addTarget(self, action: #selector(setFee), for: .allEvents)
        feeSliderOutlet.maximumValue = 2 * -1
        feeSliderOutlet.minimumValue = 432 * -1
        let ud = UserDefaults.standard
        
        if ud.object(forKey: "feeTarget") != nil {
            let numberOfBlocks = ud.object(forKey: "feeTarget") as! Int
            feeSliderOutlet.value = Float(numberOfBlocks) * -1
            updateFeeLabel(label: blockTargetOutlet, numberOfBlocks: numberOfBlocks)
        } else {
            blockTargetOutlet.text = "Minimum fee set"
            feeSliderOutlet.value = 432 * -1
        }
        
        let doNotSpendChangeIsOn = ud.object(forKey: "doNotSpendChange") as? Bool ?? false
        spendChangeSwitch.setOn(doNotSpendChangeIsOn, animated: true)
        if spendChangeSwitch.isOn {
            doNotSpendChangeLabel.textColor = .lightGray
        } else {
            doNotSpendChangeLabel.textColor = .darkGray
        }
        
        let doNotSpendDustIsOn = ud.object(forKey: "doNotSpendDust") as? Bool ?? false
        spendDustSwitch.setOn(doNotSpendDustIsOn, animated: true)
        if spendDustSwitch.isOn {
            doNotSpendDustLabel.textColor = .lightGray
        } else {
            doNotSpendDustLabel.textColor = .darkGray
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        getActiveWalletNow { (wallet, error) in
            if wallet != nil {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.imageView.image = LifeHash.image(wallet!.descriptor)
                }
            }
        }
        
        amount = ""
        outputs.removeAll()
        outputArray.removeAll()
        outputsString = ""
        outputsTable.reloadData()
        incompletePsbt = ""
        rawTxSigned = ""
        outputsTable.alpha = 0
        updateAvailableBalance()
        
        if amountInput.text != "" && addressInput.text != "" {
            createOutlet.alpha = 1
            addOutlet.alpha = 1
        } else {
            createOutlet.alpha = 0
            addOutlet.alpha = 0
        }
    }
    
    private func sweepAction() {
        print("sweepAction")
        DispatchQueue.main.async { [unowned vc = self] in
            vc.creatingView.label.text = "sweeping..."
            Sweeper.sweepTo(receivingAddress: vc.addressInput.text!) { [unowned vc = self] (psbt, errorDesc) in
                if psbt != nil {
                    vc.signSweepedPsbt(psbt: psbt!)
                } else {
                    vc.creatingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: errorDesc ?? "Unkown sweeping error.")
                }
            }
        }
    }
    
    @IBAction func sweepButtonAction(_ sender: Any) {
        addressInput.resignFirstResponder()
        if addressInput.text != "" {
            checkForLockedUtxos()
        } else {
            showAlert(vc: self, title: "Error", message: "You need to enter a recipient address first.")
        }
    }
    
    private func checkForLockedUtxos() {
        creatingView.addConnectingView(vc: self, description: "checking for locked utxo's...")
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                if wallet!.name != nil {
                    vc.walletName = wallet!.name!
                    vc.listLockUnspent(walletName: wallet!.name!)
                } else {
                    vc.creatingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "No active wallet")
                }
            } else {
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "No active wallet")
            }
        }
    }
    
    private func listLockUnspent(walletName: String) {
        Reducer.makeCommand(walletName: walletName, command: .listlockunspent, param: "") { [unowned vc = self] (object, errorDescription) in
            if let lockedUtxos = object as? NSArray {
                if lockedUtxos.count > 0 {
                    vc.creatingView.removeConnectingView()
                    vc.promptIfUserWantsToSweepLockedUtxos(lockedUtxos: lockedUtxos)
                } else {
                    vc.sweepAction()
                }
            } else {
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "There was an error looking up your locked utxos.")
            }
        }
    }
    
    private func promptIfUserWantsToSweepLockedUtxos(lockedUtxos: NSArray) {
        DispatchQueue.main.async { [unowned vc = self] in
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            let alert = UIAlertController(title: "You have locked utxo's, would you like to sweep them too??", message: "", preferredStyle: alertStyle)
            alert.addAction(UIAlertAction(title: "Sweep all utxo's", style: .default, handler: { [unowned vc = self] action in
                vc.unlockAllUtxosToSweep(lockedUtxos: lockedUtxos)
            }))
            alert.addAction(UIAlertAction(title: "Keep them locked!", style: .default, handler: { [unowned vc = self] action in
                vc.creatingView.addConnectingView(vc: vc, description: "Sweeping unlocked utxo's...")
                vc.sweepAction()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func unlockAllUtxosToSweep(lockedUtxos: NSArray) {
        creatingView.addConnectingView(vc: self, description: "unlocking all utxo's")
        if let locked = lockedUtxos as? [[String:Any]] {
            CoinControl.unlockUtxos(utxos: locked) { [unowned vc = self] success in
                if success {
                    vc.sweepAction()
                } else {
                    vc.creatingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "There was an error unlocking your utxos.")
                }
            }
        }
    }
    
    private func signSweepedPsbt(psbt: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.creatingView.label.text = "signing psbt..."
        }
        PSBTSigner.sign(psbt: psbt) { [unowned vc = self] (success, psbt, rawTx) in
            if psbt != nil {
                vc.confirmUnsigned(psbt: psbt!)
            } else if rawTx != nil {
                vc.confirm(raw: rawTx!)
            } else {
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "There was an error signing your psbt, no data wa returned.")
            }
        }
    }
    
    private func updateAvailableBalance() {
        getActiveWalletNow() { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                vc.walletName = wallet!.name!
                
                func getBalance() {
                    NodeLogic.sharedInstance.loadWalletData(wallet: wallet!) { (success, dictToReturn, errorDesc) in
                        if success && dictToReturn != nil {
                            let s = HomeStruct(dictionary: dictToReturn!)
                            let btc = (s.coldBalance).doubleValue
                            let fiat = s.fiatBalance
                            DispatchQueue.main.async { [unowned vc = self] in
                                vc.availableBalance.text = "\(btc) btc / \(fiat) available"
                                vc.availableBalance.alpha = 1
                            }
                        }
                    }
                }
                
                if vc.spendChangeSwitch.isOn || vc.spendDustSwitch.isOn {
                    vc.lockUtxosNow { _ in
                        vc.creatingView.removeConnectingView()
                        getBalance()
                    }
                } else {
                    vc.creatingView.removeConnectingView()
                    getBalance()
                }
                
            } else {
                vc.creatingView.removeConnectingView()
            }
        }
    }
    
    @IBAction func spendChangeAction(_ sender: Any) {
        let ud = UserDefaults.standard
        ud.set(spendChangeSwitch.isOn, forKey: "doNotSpendChange")
        if spendChangeSwitch.isOn {
            creatingView.addConnectingView(vc: self, description: "locking *all* change utxos...")
            doNotSpendChangeLabel.textColor = .lightGray
            updateAvailableBalance()
        } else {
            doNotSpendChangeLabel.textColor = .darkGray
            unlockChangeUtxosNow { [unowned vc = self] success in
                if success {
                    displayAlert(viewController: vc, isError: false, message: "change utxo's unlocked")
                    vc.updateAvailableBalance()
                } else {
                    vc.updateAvailableBalance()
                }
            }
        }
    }
    
    @IBAction func spendDustAction(_ sender: Any) {
        let ud = UserDefaults.standard
        ud.set(spendDustSwitch.isOn, forKey: "doNotSpendDust")
        if spendDustSwitch.isOn {
            creatingView.addConnectingView(vc: self, description: "locking *all* dust utxos...")
            doNotSpendDustLabel.textColor = .lightGray
            updateAvailableBalance()
        } else {
            doNotSpendDustLabel.textColor = .darkGray
            unlockDustUtxosNow { [unowned vc = self] success in
                if success {
                    displayAlert(viewController: vc, isError: false, message: "dust utxo's unlocked")
                    vc.updateAvailableBalance()
                } else {
                    vc.updateAvailableBalance()
                }
            }
        }
    }
    
    @IBAction func scannerAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "scanBip21Segue", sender: vc)
        }
    }
    
    private func unlockChangeUtxosNow(completion: @escaping ((Bool)) -> Void) {
        creatingView.addConnectingView(vc: self, description: "unlocking *all* change utxos...")
        var utxosToUnlock = [[String:Any]]()
        Reducer.makeCommand(walletName: walletName ?? "", command: .listlockunspent, param: "") { (object, errorDescription) in
            if let utxos = object as? NSArray {
                if utxos.count > 0 {
                    for (i, utxo) in utxos.enumerated() {
                        let dict = utxo as! [String:Any]
                        let txid = dict["txid"] as! String
                        let vout = dict["vout"] as! Int
                        CoreDataService.retrieveEntity(entityName: .lockedUtxos) { [unowned vc = self] (lockedUtxos, errorDescription) in
                            if lockedUtxos != nil {
                                if lockedUtxos!.count > 0 {
                                    for (x, lockedUtxo) in lockedUtxos!.enumerated() {
                                        let str = LockedUtxoStruct.init(dictionary: lockedUtxo)
                                        if vc.isChange(str.desc) && txid == str.txid && vout == str.vout {
                                            utxosToUnlock.append(dict)
                                        }
                                        if i + 1 == utxos.count && x + 1 == lockedUtxos!.count {
                                            CoinControl.unlockUtxos(utxos: utxosToUnlock) { success in
                                                completion(success)
                                            }
                                        }
                                    }
                                } else {
                                    showAlert(vc: vc, title: "Error", message: "We can not unlock change utxo's that were locked outside of FN2.")
                                    completion(false)
                                }
                            } else {
                                showAlert(vc: vc, title: "Error", message: "We can not unlock change utxo's that were locked outside of FN2.")
                                completion(false)
                            }
                        }
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    private func unlockDustUtxosNow(completion: @escaping ((Bool)) -> Void) {
        creatingView.addConnectingView(vc: self, description: "unlocking *all* dust utxos...")
        var utxosToUnlock = [[String:Any]]()
        Reducer.makeCommand(walletName: walletName ?? "", command: .listlockunspent, param: "") { (object, errorDescription) in
            if let utxos = object as? NSArray {
                if utxos.count > 0 {
                    for (i, utxo) in utxos.enumerated() {
                        let dict = utxo as! [String:Any]
                        let txid = dict["txid"] as! String
                        let vout = dict["vout"] as! Int
                        CoreDataService.retrieveEntity(entityName: .lockedUtxos) { [unowned vc = self] (lockedUtxos, errorDescription) in
                            if lockedUtxos != nil {
                                if lockedUtxos!.count > 0 {
                                    for (x, lockedUtxo) in lockedUtxos!.enumerated() {
                                        let str = LockedUtxoStruct.init(dictionary: lockedUtxo)
                                        if str.amount < 0.00010000 && txid == str.txid && vout == str.vout {
                                            utxosToUnlock.append(dict)
                                        }
                                        if i + 1 == utxos.count && x + 1 == lockedUtxos!.count {
                                            CoinControl.unlockUtxos(utxos: utxosToUnlock) { success in
                                                completion(success)
                                            }
                                        }
                                    }
                                } else {
                                    showAlert(vc: vc, title: "Error", message: "We can not unlock dust utxo's that were locked outside of FN2.")
                                    completion(false)
                                }
                            } else {
                                showAlert(vc: vc, title: "Error", message: "We can not unlock dust utxo's that were locked outside of FN2.")
                                completion(false)
                            }
                        }
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    private func lockUtxosNow(completion: @escaping ((Bool)) -> Void) {
        var utxosToLock = [[String:Any]]()
        Reducer.makeCommand(walletName: walletName ?? "", command: .listunspent, param: "0") { (object, errorDescription) in
            if let utxos = object as? NSArray {
                if utxos.count > 0 {
                    for (i, utxo) in utxos.enumerated() {
                        let dict = utxo as! [String:Any]
                        let desc = dict["desc"] as! String
                        let amount = dict["amount"] as! Double
                        DispatchQueue.main.async { [unowned vc = self] in
                            if vc.spendChangeSwitch.isOn && vc.isChange(desc) {
                                utxosToLock.append(dict)
                            } else if vc.spendDustSwitch.isOn && amount < 0.00010000 {
                                utxosToLock.append(dict)
                            }
                            if i + 1 == utxos.count {
                                CoinControl.lockUtxos(utxos: utxosToLock, completion: completion)
                            }
                        }
                    }
                } else {
                    completion(true)
                }
            }
        }
    }
    
    private func isChange(_ desc: String) -> Bool {
        if desc.contains("/1/") {
            return true
        } else {
            return false
        }
    }
    
    func addOut() {
        
        if amountInput.text != "" && addressInput.text != "" && amountInput.text != "0.0" {
            
            let dict = ["address":addressInput.text!, "amount":amountInput.text!] as [String : String]
            
            outputArray.append(dict)
            recipients.append(addressInput.text!)
            
            DispatchQueue.main.async { [unowned vc = self] in
                vc.amountInput.text = ""
                vc.addressInput.text = ""
                vc.outputsTable.reloadData()
                
            }
            
        } else {
            
            displayAlert(viewController: self,
                         isError: true,
                         message: "You need to fill out a recipient and amount first then tap this button, this button is used for adding multiple recipients aka \"batching\".")
            
        }
        
    }
    
    @IBAction func addOutput(_ sender: Any) {
        outputsTable.alpha = 1
        addOut()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Recipients:"
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 30
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)//UIFont.init(name: "System", size: 12)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return outputArray.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 85
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = view.backgroundColor
        
        if outputArray.count > 0 {
            
            if outputArray.count > 1 {
                
                tableView.separatorColor = UIColor.white
                tableView.separatorStyle = .singleLine
                
            }
            
            let address = outputArray[indexPath.row]["address"]!
            let amount = outputArray[indexPath.row]["amount"]!
            
            cell.textLabel?.text = "Value: \(String(describing: amount))\n\n\(String(describing: address))"
            
        } else {
            
           cell.textLabel?.text = ""
            
        }
        
        return cell
        
    }
    
    func addTapGesture() {
        
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(self.dismissKeyboard (_:)))
        
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        
    }
    
    // MARK: User Actions
    
    @IBAction func coinControlAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToCoinControl", sender: vc)
        }
    }
    
    func confirm(raw: String) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.creatingView.removeConnectingView()
            vc.amount = ""
            vc.amountInput.text = ""
            vc.addressInput.text = ""
            vc.outputs.removeAll()
            vc.outputArray.removeAll()
            vc.outputsString = ""
            vc.outputsTable.reloadData()
            vc.rawTxSigned = raw
            vc.performSegue(withIdentifier: "goConfirm", sender: vc)
            
        }
        
    }
    
    func confirmUnsigned(psbt: String) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.creatingView.removeConnectingView()
            vc.amount = ""
            vc.amountInput.text = ""
            vc.addressInput.text = ""
            vc.outputs.removeAll()
            vc.outputArray.removeAll()
            vc.outputsString = ""
            vc.outputsTable.reloadData()
            vc.incompletePsbt = psbt
            vc.performSegue(withIdentifier: "goConfirm", sender: vc)
            
        }
    }
    
    @IBAction func tryRawNow(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.addressInput.resignFirstResponder()
            self.amountInput.resignFirstResponder()
            
        }
        
        func noNodeOrWallet() {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.outputs.removeAll()
                vc.outputArray.removeAll()
                vc.outputsString = ""
                vc.outputsTable.reloadData()
                
            }
            
            displayAlert(viewController: self, isError: true, message: "no active node or no active wallet!")
            
        }
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                getActiveWalletNow { (wallet, error) in
                    
                    if !error && wallet != nil {
                        vc.tryRaw()
                        
                    } else {
                        noNodeOrWallet()
                    }
                }
            } else {
                noNodeOrWallet()
            }
        }
    }
    
    @objc func tryRaw() {
        
        creatingView.addConnectingView(vc: self, description: "Creating psbt")
        
        if amountInput.text != "" && addressInput.text != "" && amountInput.text != "0.0" {
            let dict = ["address":addressInput.text!, "amount":amountInput.text!] as [String : String]
            
            outputArray.append(dict)
            recipients.append(addressInput.text!)
            
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            //vc.amountInput.text = ""
            //vc.addressInput.text = ""
            vc.scannerButton.tintColor = .clear
            vc.createOutlet.alpha = 0
            vc.addOutlet.alpha = 0
            vc.outputsTable.reloadData()
            
        }
            
        func convertOutputs() {
            
            for output in outputArray {
                
                if let amount = output["amount"] {
                    
                    if let address = output["address"] {
                        
                        if address != "" {
                            
                            // .doubleValue extension now handles commas and decimals for Russian localization converting String to double
                            let out = [address:amount.doubleValue]
                            outputs.append(out)
                            
                        }
                        
                    }
                    
                }
                
            }
            
            outputsString = outputs.description
            outputsString = outputsString.replacingOccurrences(of: "[", with: "")
            outputsString = outputsString.replacingOccurrences(of: "]", with: "")
            getRawTx()
            
        }
        
        if outputArray.count == 0 {
            
            if self.amountInput.text != "" && self.amountInput.text != "0.0" && self.addressInput.text != "" {
                
                let dict = ["address":addressInput.text!, "amount":amountInput.text!] as [String : String]
                
                outputArray.append(dict)
                convertOutputs()
                
            } else {
                
                creatingView.removeConnectingView()
                
                displayAlert(viewController: self,
                             isError: true,
                             message: "You need to fill out an amount and a recipient")
                
            }
            
        } else if outputArray.count > 0 {
            
            convertOutputs()
            
        }
        
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        
        amountInput.resignFirstResponder()
        addressInput.resignFirstResponder()
        
    }
    
    //MARK: Textfield methods
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField.text?.contains("."))! {
           let decimalCount = (textField.text?.components(separatedBy: ".")[1])?.count
            
            if decimalCount! > 7 {
                
                if let char = string.cString(using: String.Encoding.utf8) {
                    let isBackSpace = strcmp(char, "\\b")
                    
                    if (isBackSpace == -92) {
                        print("Backspace was pressed")
                        
                    } else {
                        DispatchQueue.main.async { [unowned vc = self] in
                            displayAlert(viewController: self, isError: true, message: "Only 8 decimal places allowed")
                            let txt = vc.amountInput.text!.dropLast()
                            vc.amountInput.text = "\(txt)"
                            
                        }
                    }
                }
            }
        }
        
        return true
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView == addressInput && addressInput.text != "" {
            
            processBIP21(url: addressInput.text!)
            
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        textField.resignFirstResponder()
        
        if addressInput.text != "" {
            
            if amountInput.text != "" && amountInput.text != "0.0" && addressInput.text != "" {
                
                createOutlet.alpha = 1
                addOutlet.alpha = 1
                
            }
            
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.endEditing(true)
        return true
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        amount = ""
        outputs.removeAll()
        outputArray.removeAll()
        outputsString = ""
        outputsTable.reloadData()
        rawTxSigned = ""
        outputsTable.alpha = 0
        
    }
    
    //MARK: Helpers
    
    func rounded(number: Double) -> Double {
        
        return Double(round(100000000*number)/100000000)
        
    }
    
    func processBIP21(url: String) {
        
        let addressParser = AddressParser()
        let errorBool = addressParser.parseAddress(url: url).errorBool
        let errorDescription = addressParser.parseAddress(url: url).errorDescription
        
        if !errorBool {
            
            let address = addressParser.parseAddress(url: url).address
            let amount = "\(addressParser.parseAddress(url: url).amount)"
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.addressInput.resignFirstResponder()
                vc.amountInput.resignFirstResponder()
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    if amount != "0.0" {
                        
                        vc.amountInput.text = amount
                        
                    }
                    
                    if address != "" {
                        
                        vc.addressInput.text = address
                        
                    }
                    
                    if vc.amountInput.text != "" && vc.amountInput.text != "0.0" && vc.addressInput.text != "" {
                        
                        vc.createOutlet.alpha = 1
                        vc.addOutlet.alpha = 1
                        
                    }
                    
                }
                                                
            }
            
        } else {
            
            displayAlert(viewController: self, isError: true, message: errorDescription)
            
        }
        
    }
    
    enum error: Error {
        
        case noCameraAvailable
        case videoInputInitFail
        
    }
    
    //MARK: Result Parsers
    
    func getRawTx() {
        
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            
            if wallet != nil && !error {
                
                if wallet!.type == "MULTI" {
                    
                    vc.createMultiSig(wallet: wallet!)
                    
                } else if wallet!.type == "DEFAULT" {
                    
                    vc.createSingleSig()
                    
                } else {
                    
                    let descParser = DescriptorParser()
                    let descStr = descParser.descriptor(wallet!.descriptor)
                    
                    if descStr.isMulti {
                        
                        vc.createMultiSig(wallet: wallet!)
                        
                    } else {
                        
                        vc.createSingleSig()
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func createMultiSig(wallet: WalletStruct) {
        
        var amount = Double()
        for output in outputArray {
            
            let outputAmount = Double(output["amount"]!)!
            amount += outputAmount
            
        }
        
        MultiSigTxBuilder.build(outputs: outputs) { [unowned vc = self] (signedTx, unsignedPsbt, errorDescription) in
            
            if signedTx != nil {
                
                vc.confirm(raw: signedTx!)
                
            } else if unsignedPsbt != nil {
                
                vc.confirmUnsigned(psbt: unsignedPsbt!)
                
            } else {
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    vc.amount = ""
                    vc.outputArray.removeAll()
                    vc.outputsTable.reloadData()
                    vc.rawTxSigned = ""
                    vc.outputsTable.alpha = 0
                    vc.outputsString = ""
                    vc.outputs.removeAll()
                    vc.creatingView.removeConnectingView()
                    
                    displayAlert(viewController: vc,
                                 isError: true,
                                 message: errorDescription!)
                    
                }
                
            }
            
        }
        
    }
    
    func createSingleSig() {
        
        SingleSigBuilder.build(outputs: outputs) { [unowned vc = self] (signedTx, psbt, errorDescription) in
            
            if signedTx != nil {
                
                vc.confirm(raw: signedTx!)
                
            } else if psbt != nil {
                
                vc.confirmUnsigned(psbt: psbt!)
                
            } else {
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    vc.amount = ""
                    vc.outputArray.removeAll()
                    vc.outputsTable.reloadData()
                    vc.rawTxSigned = ""
                    vc.outputsTable.alpha = 0
                    vc.outputsString = ""
                    vc.outputs.removeAll()
                    vc.creatingView.removeConnectingView()
                    
                    displayAlert(viewController: vc,
                                 isError: true,
                                 message: errorDescription!)
                    
                }
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            outputArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if outputArray.count == 0 {
                outputsTable.alpha = 0
                
                if amountInput.text == "" && addressInput.text == "" {
                    createOutlet.alpha = 0
                    addOutlet.alpha = 0
                    
                }
                
            }
            
        }
        
    }
    
    func updateFeeLabel(label: UILabel, numberOfBlocks: Int) {
        
        let seconds = ((numberOfBlocks * 10) * 60)
        let ud = UserDefaults.standard
        
        func updateFeeSetting() {
            
            ud.set(numberOfBlocks, forKey: "feeTarget")
            
        }
        
        DispatchQueue.main.async {
            
            if seconds < 86400 {
                
                if seconds < 3600 {
                    
                    DispatchQueue.main.async {
                        
                        label.text = "\(seconds / 60) minutes (\(numberOfBlocks) blocks)"
                        
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        
                        label.text = "\(seconds / 3600) hours (\(numberOfBlocks) blocks)"
                        
                    }
                    
                }
                
            } else {
                
                DispatchQueue.main.async {
                    
                    label.text = "\(seconds / 86400) days (\(numberOfBlocks) blocks)"
                    
                }
                
            }
            
            updateFeeSetting()
            
        }
            
    }
    
    @objc func setFee(_ sender: UISlider) {
        
        let numberOfBlocks = Int(sender.value) * -1
        updateFeeLabel(label: blockTargetOutlet, numberOfBlocks: numberOfBlocks)
            
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segue.identifier
        switch id {
        case "scanBip21Segue":
            if let vc = segue.destination as? ScannerViewController {
                vc.isScanningInvoice = true
                vc.returnStringBlock = { [unowned thisVc = self] result in
                    thisVc.processBIP21(url: result)
                }
            }
            
        case "goConfirm":
            if let vc = segue.destination as? ConfirmViewController {
                vc.signedRawTx = rawTxSigned
                vc.recipients = recipients
                vc.unsignedPsbt = incompletePsbt
            }
            
        default:
            break
            
        }
    }
    
}



