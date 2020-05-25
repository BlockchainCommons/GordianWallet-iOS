//
//  ConfirmViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit
import AuthenticationServices

class ConfirmViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, UITextFieldDelegate {
    
    var memo = ""
    var txFee = Double()
    var fxRate = Double()
    var txid = ""
    var psbtDict:NSDictionary!
    var doneBlock: ((Bool) -> Void)?
    let creatingView = ConnectingView()
    var unsignedPsbt = ""
    var signedRawTx = ""
    var outputsString = ""
    var inputsString = ""
    var inputArray = [[String:Any]]()
    var inputTableArray = [[String:Any]]()
    var outputArray = [[String:Any]]()
    var index = Int()
    var inputTotal = Double()
    var outputTotal = Double()
    var miningFee = ""
    var recipients = [String]()
    var addressToVerify = ""
    var sweeping = Bool()
    @IBOutlet var confirmTable: UITableView!
    @IBOutlet var broadcastButton: UIButton!
    @IBOutlet weak var exportTx: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        confirmTable.delegate = self
        confirmTable.dataSource = self
        
        if unsignedPsbt == "" {
            
            exportTx.alpha = 1
            creatingView.addConnectingView(vc: self, description: "verifying signed transaction")
            executeNodeCommand(method: .decoderawtransaction, param: "\"\(signedRawTx)\"")
            
        } else {
            
            exportTx.alpha = 0
            let exportImage = UIImage(systemName: "arrowshape.turn.up.right")!
            broadcastButton.setImage(exportImage, for: .normal)
            broadcastButton.setTitle("  Export PSBT", for: .normal)
            creatingView.addConnectingView(vc: self, description: "verifying psbt")
            executeNodeCommand(method: .decodepsbt, param: "\"\(unsignedPsbt)\"")
            
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func exportSignedTx(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            let activityViewController = UIActivityViewController(activityItems: [vc.signedRawTx], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = vc.view
            vc.present(activityViewController, animated: true) {}
        }
    }
    
    @IBAction func sendNow(_ sender: Any) {
        
        if unsignedPsbt == "" {
            
            DispatchQueue.main.async {
                            
                let alert = UIAlertController(title: "Broadcast transaction?", message: "We use blockstream's esplora Tor V3 api to broadcast your transactions for improved privacy. Once you broadcast there is no going back!", preferredStyle: .actionSheet)

                alert.addAction(UIAlertAction(title: "Yes, broadcast now", style: .default, handler: { [unowned vc = self] action in
                    
                    #if !targetEnvironment(simulator)
                    vc.showAuth()
                    #else
                    vc.broadcast()
                    #endif
                                        
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                alert.popoverPresentationController?.sourceView = self.view
                self.present(alert, animated: true, completion: nil)
                
            }
            
        } else {
            
            showPsbtOptions()
            
        }
        
    }
    
    func showPsbtOptions() {
        
        DispatchQueue.main.async {
                        
            let alert = UIAlertController(title: "Export as:", message: "", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: ".psbt data file", style: .default, handler: { [unowned vc = self] action in
                
                vc.convertPSBTtoData(string: vc.unsignedPsbt)
                
            }))
            
            alert.addAction(UIAlertAction(title: "base64 encoded text", style: .default, handler: { [unowned vc = self] action in
                
                DispatchQueue.main.async {
                    
                    let textToShare = [vc.unsignedPsbt]
                    
                    let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                          applicationActivities: nil)
                    
                    activityViewController.popoverPresentationController?.sourceView = vc.view
                    vc.present(activityViewController, animated: true) {}
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "plain text", style: .default, handler: { [unowned vc = self] action in
                
                DispatchQueue.main.async {
                    
                    let textToShare = ["\(String(describing: vc.psbtDict))"]
                    
                    let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
                    
                    activityViewController.popoverPresentationController?.sourceView = vc.view
                    vc.present(activityViewController, animated: true) {}
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "signatures and keys", style: .default, handler: { [unowned vc = self] action in
                
                DispatchQueue.main.async {
                    let inputs = vc.psbtDict["inputs"] as! NSArray
                    var sigsAndKeys:[[String:String]] = []
                    for (i, input) in inputs.enumerated() {
                        let inputDict = input as! NSDictionary
                        let bip32derivs = inputDict["bip32_derivs"] as! NSArray
                        let partialSignatures = inputDict["partial_signatures"] as! NSDictionary
                        var pubkeySigner = ""
                        var signature = ""
                        for (key, value) in partialSignatures {
                            pubkeySigner = key as! String
                            signature = value as! String
                        }
                        for bip32deriv in bip32derivs {
                            let bip32derivDict = bip32deriv as! NSDictionary
                            let pubkey = bip32derivDict["pubkey"] as! String
                            let masterFingerprint = bip32derivDict["master_fingerprint"] as! String
                            if pubkey == pubkeySigner {
                                CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                                    if wallets != nil {
                                        var signingXpub = ""
                                        for wallet in wallets! {
                                            let walletStruct = WalletStruct(dictionary: wallet)
                                            if walletStruct.type == "MULTI" {
                                                let descriptorParser = DescriptorParser()
                                                let descriptorStruct = descriptorParser.descriptor(walletStruct.descriptor)
                                                let keys = descriptorStruct.keysWithPath
                                                for key in keys {
                                                    if key.contains(masterFingerprint) {
                                                        let arr1 = key.split(separator: "]")
                                                        let arr2 = "\(arr1[1])".split(separator: "/")
                                                        signingXpub = "\(arr2[0])"
                                                    }
                                                }
                                            }
                                        }
                                        let dict = ["xpub":signingXpub, "signature":signature]
                                        sigsAndKeys.append(dict)
                                    }
                                }
                            }
                        }
                        if i + 1 == inputs.count {
                            DispatchQueue.main.async {
                                let textToShare = ["\(sigsAndKeys)"]
                                let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
                                activityViewController.popoverPresentationController?.sourceView = vc.view
                                vc.present(activityViewController, animated: true) {}
                            }
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func convertPSBTtoData(string: String) {
     
        if let data = Data(base64Encoded: string) {
         
            DispatchQueue.main.async {
                
                let activityViewController = UIActivityViewController(activityItems: [data],
                                                                      applicationActivities: nil)
                
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true) {}
                
            }
            
        }
        
    }

    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
            
            func send(walletName: String) {
                
                Reducer.makeCommand(walletName: walletName, command: .sendrawtransaction, param: param) { [unowned vc = self] (object, errorDesc) in
                    
                    if let result = object as? String {
                        
                        DispatchQueue.main.async {
                            
                            UIPasteboard.general.string = result
                            vc.creatingView.removeConnectingView()
                            vc.navigationItem.title = "Sent ✓"
                            vc.broadcastButton.alpha = 0
                            
                            displayAlert(viewController: vc,
                                         isError: false,
                                         message: "Transaction sent ✓")
                            
                            if vc.sweeping {
                                
                                NotificationCenter.default.post(name: .didSweep, object: nil, userInfo: nil)
                                
                            }
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDesc ?? "")
                        
                    }
                    
                }
                
            }
            
            func decodePsbt(walletName: String) {
                
                Reducer.makeCommand(walletName: walletName, command: .decodepsbt, param: param) { [unowned vc = self] (object, errorDesc) in
                    
                    if let dict = object as? NSDictionary {
                        
                        vc.psbtDict = dict
                        
                        if let txDict = dict["tx"] as? NSDictionary {
                            
                            vc.txid = txDict["txid"] as! String
                            vc.parseTransaction(tx: txDict)
                            
                        }
                        
                    } else {
                        
                       vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDesc ?? "")
                        
                    }
                    
                }
                
            }
            
            func decodeTx(walletName: String) {
                
                Reducer.makeCommand(walletName: walletName, command: .decoderawtransaction, param: param) { [unowned vc = self] (object, errorDesc) in
                    
                    if let dict = object as? NSDictionary {
                        
                        vc.txid = dict["txid"] as! String
                        vc.parseTransaction(tx: dict)
                        
                    } else {
                        
                       vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDesc ?? "")
                        
                    }
                    
                }
                
            }
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil {
                
                if wallet!.name != nil {
                    
                    switch method {
                        
                    case .sendrawtransaction:
                        send(walletName: wallet!.name!)
                        
                    case .decodepsbt:
                        decodePsbt(walletName: wallet!.name!)
                        
                    case .decoderawtransaction:
                        decodeTx(walletName: wallet!.name!)
                        
                    default:
                        
                        break
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func parseTransaction(tx: NSDictionary) {
        
        let inputs = tx["vin"] as! NSArray
        let outputs = tx["vout"] as! NSArray
        parseOutputs(outputs: outputs)
        parseInputs(inputs: inputs, completion: getFirstInputInfo)
        
    }
    
    func getFirstInputInfo() {
        
        index = 0
        getInputInfo(index: index)
        
    }
    
    func getInputInfo(index: Int) {
        
        let dict = inputArray[index]
        let txid = dict["txid"] as! String
        let vout = dict["vout"] as! Int
        
        parsePrevTx(method: .getrawtransaction,
                    param: "\"\(txid)\"",
                    vout: vout)
        
    }
    
    func parseInputs(inputs: NSArray, completion: @escaping () -> Void) {
        
        for (index, i) in inputs.enumerated() {
            
            let input = i as! NSDictionary
            let txid = input["txid"] as! String
            let vout = input["vout"] as! Int
            let dict = ["inputNumber":index + 1, "txid":txid, "vout":vout as Any] as [String : Any]
            inputArray.append(dict)
            
            if index + 1 == inputs.count {
                
                completion()
                
            }
            
        }
        
    }
    
    func parseOutputs(outputs: NSArray) {
        
        for (i, o) in outputs.enumerated() {
            
            let output = o as! NSDictionary
            let scriptpubkey = output["scriptPubKey"] as! NSDictionary
            let addresses = scriptpubkey["addresses"] as? NSArray ?? []
            let amount = output["value"] as! Double
            let number = i + 1
            var addressString = ""
            
            if addresses.count > 1 {
                
                for a in addresses {
                    
                    addressString += a as! String + " "
                    
                }
                
            } else {
                
                addressString = addresses[0] as! String
                
            }
            
            outputTotal += amount
            outputsString += "Output #\(number):\nAmount: \(amount.avoidNotation)\nAddress: \(addressString)\n\n"
            var isChange = true
            
            for recipient in recipients {
                
                if addressString == recipient {
                    
                    isChange = false
                    
                }
                
            }
            
            if sweeping {
                
                isChange = false
                
            }
            
            let outputDict:[String:Any] = [
            
                "index": number,
                "amount": amount.avoidNotation,
                "address": addressString,
                "isChange": isChange
            
            ]
            
            outputArray.append(outputDict)
            
        }
        
    }
    
    func parsePrevTxOutput(outputs: NSArray, vout: Int) {
        
        for o in outputs {
            
            let output = o as! NSDictionary
            let n = output["n"] as! Int
            
            if n == vout {
                
                //this is our inputs output, get amount and address
                let scriptpubkey = output["scriptPubKey"] as! NSDictionary
                let addresses = scriptpubkey["addresses"] as! NSArray
                let amount = output["value"] as! Double
                var addressString = ""
                
                if addresses.count > 1 {
                    
                    for a in addresses {
                        
                        addressString += a as! String + " "
                        
                    }
                    
                } else {
                    
                    addressString = addresses[0] as! String
                    
                }
                
                inputTotal += amount
                inputsString += "Input #\(index + 1):\nAmount: \(amount.avoidNotation)\nAddress: \(addressString)\n\n"
                
                let inputDict:[String:Any] = [
                
                    "index": index + 1,
                    "amount": amount.avoidNotation,
                    "address": addressString
                
                ]
                
                inputTableArray.append(inputDict)
                
            }
            
        }
        
        if index + 1 < inputArray.count {
            
            index += 1
            getInputInfo(index: index)
            
        } else if index + 1 == inputArray.count {
            
            txFee = inputTotal - outputTotal
            let txfeeString = txFee.avoidNotation
            let fiatConverter = FiatConverter.sharedInstance
            fiatConverter.getFxRate { [unowned vc = self] exchangeRate in
                
                if exchangeRate != nil {
                    
                    vc.fxRate = exchangeRate!
                    let fiatFee = exchangeRate! * vc.txFee
                    let roundedFiatFee = Double(round(100*fiatFee)/100)
                    vc.miningFee = "\(txfeeString) btc / $\(roundedFiatFee)"
                    vc.loadTableData()
                    
                } else {
                    vc.miningFee = "\(txfeeString) btc / error fetching fx rate"
                    vc.loadTableData()
                    
                }
                
            }
            
            
        }
        
    }
    
    func loadTableData() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.confirmTable.reloadData()
            
        }
        
        creatingView.removeConnectingView()
    }
    
    func parsePrevTx(method: BTC_CLI_COMMAND, param: String, vout: Int) {
        
        func decodeRaw(walletName: String) {
            
            Reducer.makeCommand(walletName: walletName, command: .decoderawtransaction, param: param) { [unowned vc = self] (object, errorDescription) in
                
                if let txDict = object as? NSDictionary {
                    
                    if let outputs = txDict["vout"] as? NSArray {
                        
                        vc.parsePrevTxOutput(outputs: outputs, vout: vout)
                        
                    }
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "Error parsing inputs")
                    
                }
                
            }
            
        }
        
        func getRawTx(walletName: String) {
            
            Reducer.makeCommand(walletName: walletName, command: .getrawtransaction, param: param) { [unowned vc = self] (object, errorDescription) in
                
                if let rawTransaction = object as? String {
                    
                    vc.parsePrevTx(method: .decoderawtransaction,
                                param: "\"\(rawTransaction)\"",
                                vout: vout)
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "Error parsing inputs")
                    
                }
                
            }
            
        }
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil {
                
                if wallet!.name != nil {
                    
                    switch method {
                        
                    case .decoderawtransaction:
                        
                        decodeRaw(walletName: wallet!.name!)
                        
                    case .getrawtransaction:
                        
                        getRawTx(walletName: wallet!.name!)
                        
                    default:
                        
                        break
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 6
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
        case 2:
            
            return inputArray.count
            
        case 3:
            
            return outputArray.count
            
        case 4, 5, 0, 1:
            
            return 1
            
        default:
            
            return 0
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
        case 2, 3:
            
            return 78
            
        case 0, 1, 4, 5:
            
            return 44
            
        default:
            
            return 0
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        case 0:
            let memoCell = tableView.dequeueReusableCell(withIdentifier: "memoCell", for: indexPath)
            let textField = memoCell.viewWithTag(1) as! UITextField
            textField.delegate = self
            if unsignedPsbt != "" {
                memoCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
            }
            return memoCell
            
        case 1:
            
            let txidCell = tableView.dequeueReusableCell(withIdentifier: "miningFeeCell", for: indexPath)
            
            if unsignedPsbt != "" {
            
                txidCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            }
            
            let txidLabel = txidCell.viewWithTag(1) as! UILabel
            txidLabel.text = txid
            txidCell.selectionStyle = .none
            txidLabel.textColor = .lightGray
            txidLabel.adjustsFontSizeToFitWidth = true
            return txidCell
            
        case 2:
            
            let inputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath)
            
            if unsignedPsbt != "" {
                
                inputCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            } else {
                
                
            }
            
            let inputIndexLabel = inputCell.viewWithTag(1) as! UILabel
            let inputAmountLabel = inputCell.viewWithTag(2) as! UILabel
            let inputAddressLabel = inputCell.viewWithTag(3) as! UILabel
            let input = inputTableArray[indexPath.row]
            inputIndexLabel.text = "Input #\(input["index"] as! Int)"
            inputAmountLabel.text = "\((input["amount"] as! String)) btc"
            inputAddressLabel.text = (input["address"] as! String)
            inputAddressLabel.adjustsFontSizeToFitWidth = true
            inputCell.selectionStyle = .none
            inputIndexLabel.textColor = .lightGray
            inputAmountLabel.textColor = .lightGray
            inputAddressLabel.textColor = .lightGray
            return inputCell
            
        case 3:
            
            let outputCell = tableView.dequeueReusableCell(withIdentifier: "outputCell", for: indexPath)
            
            if unsignedPsbt != "" {
            
                outputCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            }
            
            let outputIndexLabel = outputCell.viewWithTag(1) as! UILabel
            let outputAmountLabel = outputCell.viewWithTag(2) as! UILabel
            let outputAddressLabel = outputCell.viewWithTag(3) as! UILabel
            let changeLabel = outputCell.viewWithTag(4) as! UILabel
            changeLabel.textColor = .darkGray
            let output = outputArray[indexPath.row]
            let address = (output["address"] as! String)
            let isChange = (output["isChange"] as! Bool)
            
            if isChange {
                
                outputAddressLabel.textColor = .darkGray
                outputAmountLabel.textColor = .darkGray
                outputIndexLabel.textColor = .darkGray
                changeLabel.alpha = 1
                
            } else {
                
                outputAddressLabel.textColor = .lightGray
                outputAmountLabel.textColor = .lightGray
                outputIndexLabel.textColor = .lightGray
                changeLabel.alpha = 0
                
            }
            
            outputIndexLabel.text = "Output #\(output["index"] as! Int)"
            outputAmountLabel.text = "\((output["amount"] as! String)) btc"
            outputAddressLabel.text = address
            outputAddressLabel.adjustsFontSizeToFitWidth = true
            outputCell.selectionStyle = .none
            return outputCell
            
        case 4:
            
            let miningFeeCell = tableView.dequeueReusableCell(withIdentifier: "miningFeeCell", for: indexPath)
            
            if unsignedPsbt != "" {
            
                miningFeeCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            }
            
            let miningLabel = miningFeeCell.viewWithTag(1) as! UILabel
            miningLabel.text = miningFee
            miningFeeCell.selectionStyle = .none
            miningLabel.textColor = .lightGray
            return miningFeeCell
            
        case 5:
            
            let etaCell = tableView.dequeueReusableCell(withIdentifier: "miningFeeCell", for: indexPath)
            
            if unsignedPsbt != "" {
            
                etaCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            }
            
            let etaLabel = etaCell.viewWithTag(1) as! UILabel
            etaLabel.text = eta()
            etaLabel.textColor = .lightGray
            etaCell.selectionStyle = .none
            return etaCell
            
        default:
            
            return UITableViewCell()
            
        }
        
    }
    
    private func eta() -> String {
        var eta = ""
        let ud = UserDefaults.standard
        let numberOfBlocks = ud.object(forKey: "feeTarget") as? Int ?? 432
        let seconds = ((numberOfBlocks * 10) * 60)
        
        if seconds < 86400 {
            
            if seconds < 3600 {
                eta = "\(seconds / 60) minutes"
                
            } else {
                eta = "\(seconds / 3600) hours"
                
            }
            
        } else {
            eta = "\(seconds / 86400) days"
            
        }
        
        let todaysDate = Date()
        let futureDate = Date(timeInterval: Double(seconds), since: todaysDate)
        eta += " / \(formattedDate(date: futureDate))"
        
        return eta
        
    }
    
    private func formattedDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm"
        let strDate = dateFormatter.string(from: date)
        return strDate
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
                
        let header = UIView()
        header.backgroundColor = UIColor.clear
        
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        textLabel.textColor = .lightGray
        
        switch section {
            
        case 0:
            
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
            textLabel.text = "TRANSACTION MEMO - tap to add"
            
        case 1:
             
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 20)
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 20)
            textLabel.text = "TRANSACTION ID"
            let copyButton = UIButton()
            let copyImage = UIImage(systemName: "doc.on.doc")!
            copyButton.tintColor = .systemTeal
            copyButton.setImage(copyImage, for: .normal)
            copyButton.addTarget(self, action: #selector(copyTxid), for: .touchUpInside)
            copyButton.frame = CGRect(x: header.frame.maxX - 60, y: 0, width: 15, height: 18)
            copyButton.center.y = textLabel.center.y
            header.addSubview(copyButton)
                            
        case 2:
             
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 20)
            textLabel.text = "INPUTS"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 20)
                            
        case 3:
            
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 20)
            textLabel.text = "OUTPUTS"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 20)
            
        case 4:
            
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 20)
            textLabel.text = "MINING FEE"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 20)
        
        case 5:
            
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 20)
            textLabel.text = "ESTIMATED TIME TO CONFIRMATION"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 20)
                            
        default:
            
            break
            
        }
        
        header.addSubview(textLabel)
        return header
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            
            return 30
            
        } else {
            
            return 20
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 || indexPath.section == 1 {
            
            let cell = tableView.cellForRow(at: indexPath)!
            let addressLabel = cell.viewWithTag(3) as! UILabel
            self.addressToVerify = addressLabel.text!
            
            DispatchQueue.main.async {
                                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    cell.alpha = 0
                    
                }) { _ in
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        
                        cell.alpha = 1
                        
                    }) { [unowned vc = self] _ in
                        
                        DispatchQueue.main.async {
                            
                            vc.performSegue(withIdentifier: "verify", sender: vc)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    private func broadcast() {
        
        self.creatingView.addConnectingView(vc: self, description: "broadcasting transaction")
        let broadcaster = Broadcaster.sharedInstance
        broadcaster.send(rawTx: self.signedRawTx) { [unowned vc = self] txid in
            
            if txid != nil {
                
                DispatchQueue.main.async {
                    
                    UIPasteboard.general.string = txid!
                    vc.creatingView.removeConnectingView()
                    vc.navigationItem.title = "Sent ✓"
                    vc.broadcastButton.alpha = 0
                    vc.saveTx()
                    
                    displayAlert(viewController: vc,
                                 isError: false,
                                 message: "Transaction sent ✓")
                    
                    if vc.sweeping {
                        
                        NotificationCenter.default.post(name: .didSweep, object: nil, userInfo: nil)
                        
                    }
                    
                }
            } else {
                
                DispatchQueue.main.async {
                                
                    let alert = UIAlertController(title: "There was an error broadcasting your transaction with blockstream's node.", message: "Broadcast the transaction with your node?", preferredStyle: .actionSheet)

                    alert.addAction(UIAlertAction(title: "Yes, broadcast now", style: .default, handler: { [unowned vc = self] action in
                        
                        vc.executeNodeCommand(method: .sendrawtransaction, param: "\"\(vc.signedRawTx)\"")
                                            
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    alert.popoverPresentationController?.sourceView = self.view
                    self.present(alert, animated: true, completion: nil)
                    
                }
            }
        }
    }
    
    @objc func copyTxid() {
        DispatchQueue.main.async { [unowned vc = self] in
            let pasteBoard = UIPasteboard.general
            pasteBoard.string = vc.txid
            displayAlert(viewController: vc, isError: false, message: "Transaction ID copied to clipboard")
        }
        
    }
    
    private func xpub(_ descriptor: String) -> String {
        let descriptorParser = DescriptorParser()
        let descriptorStruct = descriptorParser.descriptor(descriptor)
        if descriptorStruct.isMulti {
            return (descriptorStruct.multiSigKeys).description
        } else {
            return descriptorStruct.accountXpub
        }
    }
    
    private func fingerprint(_ descriptor: String) -> String {
        let descriptorParser = DescriptorParser()
        let descriptorStruct = descriptorParser.descriptor(descriptor)
        return descriptorStruct.fingerprint
    }
        
    private func saveTx() {
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                var txDict = [String:Any]()
                txDict["id"] = UUID()
                txDict["date"] = Date()
                txDict["txid"] = vc.txid
                txDict["memo"] = vc.memo
                txDict["accountLabel"] = wallet!.label
                txDict["incoming"] = false
                txDict["outgoing"] = true
                txDict["descriptor"] = wallet?.descriptor
                txDict["fxRate"] = vc.fxRate
                txDict["xpub"] = vc.xpub(wallet!.descriptor)
                txDict["miningFeeBtc"] = vc.txFee
                txDict["fingerprint"] = vc.fingerprint(wallet!.descriptor)
                txDict["btcReceived"] = 0.0
                txDict["btcSent"] = vc.outputTotal
                txDict["derivation"] = wallet!.derivation
                vc.saveTransactionDict(dict: txDict)
            } else {
                showAlert(vc: vc, title: "", message: "There was an error saving the transaction locally, when it confirms you can tap the transaction on the home screen to add a memo to it. Let us know about the issue so we can fix it. Thank you.")
            }
        }
    }
    
    private func saveTransactionDict(dict: [String:Any]) {
        CoreDataService.saveEntity(dict: dict, entityName: .transactions) { [unowned vc = self] (success, errorDescription) in
            if !success {
                showAlert(vc: vc, title: "", message: "There was an error saving the transaction locally, when it confirms you can tap the transaction on the home screen to add a memo to it. Let us know about the issue so we can fix it. Thank you.")
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != "" {
            memo = textField.text!
        }
    }
    
    func showAuth() {
        
        DispatchQueue.main.async {
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
            
        }
        
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let data = KeyChain.getData("userIdentifier") {
            if let username = String(data: data, encoding: .utf8) {
                
                switch authorization.credential {
                    
                case _ as ASAuthorizationAppleIDCredential:
                    
                    let authorizationProvider = ASAuthorizationAppleIDProvider()
                    authorizationProvider.getCredentialState(forUserID: username) { [unowned vc = self] (state, error) in
                        
                        switch (state) {
                        case .authorized:
                            print("Account Found - Signed In")
                            vc.broadcast()
                        case .revoked:
                            print("No Account Found")
                            fallthrough
                        case .notFound:
                            print("No Account Found")
                        default:
                            break
                        }
                        
                    }
                    
                default:
                    
                    break
                    
                }
                
            }
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        switch id {
            
        case "verify":
            
            if let vc = segue.destination as? VerifyViewController {
                
                vc.address = self.addressToVerify
                
            }
            
        default:
            
            break
            
        }
        
    }

}

