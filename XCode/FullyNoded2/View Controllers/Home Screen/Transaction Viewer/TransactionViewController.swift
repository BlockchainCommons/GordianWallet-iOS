//
//  TransactionViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class TransactionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var miningFeeText = ""
    var fee = Double()
    var amountText = ""
    var walletName = ""
    var inputArray = [[String:Any]]()
    var inputTableArray = [[String:Any]]()
    var outputArray = [[String:Any]]()
    var index = Int()
    var inputTotal = Double()
    var outputTotal = Double()
    var txDict:NSDictionary?
    var txStruct:TransactionStruct?
    var inputs = [String]()
    var outputs = [String]()
    var txid = ""
    let creatingView = ConnectingView()
    @IBOutlet weak var transactionTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transactionTable.delegate = self
        transactionTable.dataSource = self
        creatingView.addConnectingView(vc: self, description: "getting transaction")
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadData()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func loadData() {
        getTransaction(param: "\"\(txid)\", true")
    }
    
    private func reloadTable() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.transactionTable.reloadData()
        }
    }
    
    private func roundedToTwo(number: Double) -> Double {
        return Double(round(100*number)/100)
    }
    
    private func parseTxDict(dict: NSDictionary) {
        txDict = dict
        decodeTx(walletName: walletName, param: "\"\(dict["hex"] as! String)\", true")
    }
    
    private func fetchLocalData() {
        CoreDataService.retrieveEntity(entityName: .transactions) { [unowned vc = self] (transactions, errorDescription) in
            if transactions != nil {
                for tx in transactions! {
                    let txStr = TransactionStruct(dictionary: tx)
                    if txStr.txid == vc.txid {
                        vc.txStruct = txStr
                    }
                }
            }
        }
    }

    func getTransaction(param: String) {
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            vc.walletName = wallet!.name!
            Reducer.makeCommand(walletName: wallet!.name!, command: .gettransaction, param: param) { [unowned vc = self] (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    vc.fetchLocalData()
                    vc.parseTxDict(dict: dict)
                } else {
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "error")
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 11
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 6: return inputArray.count
        case 7: return outputArray.count
        default: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 44
        case 6, 7: return 76
        default: return 44
        }
    }
    
    private func memoCell(indexPath: IndexPath) -> UITableViewCell {
        let memoCell = transactionTable.dequeueReusableCell(withIdentifier: "editMemoCell", for: indexPath)
        memoCell.selectionStyle = .none
        let textField = memoCell.viewWithTag(1) as! UITextField
        textField.delegate = self
        textField.text = txStruct?.memo
        return memoCell
    }
    
    private func standardCell(indexPath: IndexPath, text: String) -> UITableViewCell {
        let standardCell = transactionTable.dequeueReusableCell(withIdentifier: "standardCell", for: indexPath)
        standardCell.selectionStyle = .none
        let label = standardCell.viewWithTag(1) as! UILabel
        label.text = text
        return standardCell
    }
    
    private func inputsCell(indexPath: IndexPath) -> UITableViewCell {
        let inputCell = transactionTable.dequeueReusableCell(withIdentifier: "inputsOutputsCell", for: indexPath)
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
    }
    
    private func outputsCell(indexPath: IndexPath) -> UITableViewCell {
        let outputCell = transactionTable.dequeueReusableCell(withIdentifier: "inputsOutputsCell", for: indexPath)
        let outputIndexLabel = outputCell.viewWithTag(1) as! UILabel
        let outputAmountLabel = outputCell.viewWithTag(2) as! UILabel
        let outputAddressLabel = outputCell.viewWithTag(3) as! UILabel
        let changeLabel = outputCell.viewWithTag(4) as! UILabel
        changeLabel.textColor = .darkGray
        let output = outputArray[indexPath.row]
        let address = (output["address"] as! String)
        outputAddressLabel.textColor = .lightGray
        outputAmountLabel.textColor = .lightGray
        outputIndexLabel.textColor = .lightGray
        changeLabel.alpha = 0
        outputIndexLabel.text = "Output #\(output["index"] as! Int)"
        outputAmountLabel.text = "\((output["amount"] as! String)) btc"
        outputAddressLabel.text = address
        outputAddressLabel.adjustsFontSizeToFitWidth = true
        outputCell.selectionStyle = .none
        return outputCell
    }
    
    private func miningFeeCell(indexPath: IndexPath) -> UITableViewCell {
        let miningFeeCell = transactionTable.dequeueReusableCell(withIdentifier: "standardCell", for: indexPath)
        let label = miningFeeCell.viewWithTag(1) as! UILabel
        label.text = miningFeeText
        return miningFeeCell
    }
    
    private func rbfEnabled(indexPath: IndexPath) -> UITableViewCell {
        let rbfEnabled = transactionTable.dequeueReusableCell(withIdentifier: "standardCell", for: indexPath)
        let label = rbfEnabled.viewWithTag(1) as! UILabel
        if txDict?["bip125-replaceable"] as? String == "no" {
            label.text = "BIP125 - Not replaceable"
        } else {
            label.text = "BIP125 - Replaceable"
        }
        return rbfEnabled
    }
    
    private func rawHex(indexPath: IndexPath) -> UITableViewCell {
        let rawHexCell = transactionTable.dequeueReusableCell(withIdentifier: "standardCell", for: indexPath)
        let label = rawHexCell.viewWithTag(1) as! UILabel
        label.text = txDict?["hex"] as? String ?? ""
        label.adjustsFontSizeToFitWidth = false
        return rawHexCell
    }
    
    private func getAmountText() {
        if let btcAmount = txDict?["amount"] as? Double {
            let fiatConverter = FiatConverter.sharedInstance
            fiatConverter.getFxRate { [unowned vc = self] currentFxRate in
                if currentFxRate != nil {
                    let usdCurrentValue = vc.roundedToTwo(number: btcAmount * currentFxRate!)
                    let miningFeePresent = vc.roundedToTwo(number: vc.fee * currentFxRate!)
                    if let fxRateAtTheTime = vc.txStruct?.fxRate {
                        let usdValueAtTheTime = vc.roundedToTwo(number: btcAmount * fxRateAtTheTime)
                        vc.amountText = "\(btcAmount) btc - $\(usdCurrentValue.withCommas()) current - $\(usdValueAtTheTime.withCommas()) at creation"
                        let miningFeePast = vc.roundedToTwo(number: vc.fee * fxRateAtTheTime)
                        vc.miningFeeText = "\(vc.fee.avoidNotation) btc - $\(miningFeePresent) current - $\(miningFeePast) at creation"
                        vc.reloadTable()
                        vc.creatingView.removeConnectingView()
                    } else {
                        vc.amountText = "\(btcAmount) btc - $\(usdCurrentValue.withCommas()) current"
                        vc.miningFeeText = "\(vc.fee.avoidNotation) btc - $\(miningFeePresent) current"
                        vc.reloadTable()
                        vc.creatingView.removeConnectingView()
                    }
                }
            }
        }
    }
    
    private func dateFromUnix(unix: Int32) -> String {
        let date = Date(timeIntervalSince1970: Double(unix))
        return formattedDate(date: date)
    }
    
    private func dateUnix(unix: Int32) -> Date {
        return Date(timeIntervalSince1970: Double(unix))
    }
    
    private func getDate() -> String {
        var date = ""
        if txStruct?.date != nil {
            date = formattedDate(date: txStruct!.date!)
        } else {
            if txDict != nil {
                date = dateFromUnix(unix: txDict!["time"] as! Int32)
            }
        }
        return date
    }
    
    private func toggleCategory(indexPath: IndexPath) -> UITableViewCell {
        if txStruct?.outgoing ?? false {
            return standardCell(indexPath: indexPath, text: "Outgoing")
        } else {
            return standardCell(indexPath: indexPath, text: "Incoming")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return memoCell(indexPath: indexPath)
        case 1: return standardCell(indexPath: indexPath, text: txid)
        case 2: return toggleCategory(indexPath: indexPath)
        case 3: return standardCell(indexPath: indexPath, text: amountText)
        case 4: return standardCell(indexPath: indexPath, text: "\(txDict?["confirmations"] as? Int ?? 0)")
        case 5: return standardCell(indexPath: indexPath, text: getDate())
        case 6: return inputsCell(indexPath: indexPath)
        case 7: return outputsCell(indexPath: indexPath)
        case 8: return miningFeeCell(indexPath: indexPath)
        case 9: return rbfEnabled(indexPath: indexPath)
        case 10: return rawHex(indexPath: indexPath)
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        textLabel.textColor = .lightGray
        textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        let copyButton = UIButton()
        let copyImage = UIImage(systemName: "doc.on.doc")!
        copyButton.tintColor = .systemTeal
        copyButton.setImage(copyImage, for: .normal)
        switch section {
        case 0:
            textLabel.text = "MEMO - tap to edit"
        case 1:
            textLabel.text = "ID"
            copyButton.frame = CGRect(x: header.frame.maxX - 25, y: 0, width: 15, height: 18)
            copyButton.addTarget(self, action: #selector(copyTxid), for: .touchUpInside)
            copyButton.center.y = textLabel.center.y
            header.addSubview(copyButton)
        case 2:
            textLabel.text = "CATEGORY"
        case 3:
            textLabel.text = "AMOUNT"
        case 4:
            textLabel.text = "CONFIRMATIONS"
        case 5:
            textLabel.text = "DATE"
        case 6:
            textLabel.text = "INPUTS"
        case 7:
            textLabel.text = "OUTPUTS"
        case 8:
            textLabel.text = "FEE"
        case 9:
            textLabel.text = "RBF"
        case 10:
            textLabel.text = "RAW HEX"
            copyButton.frame = CGRect(x: header.frame.maxX - 25, y: 0, width: 15, height: 18)
            copyButton.addTarget(self, action: #selector(copyHex), for: .touchUpInside)
            copyButton.center.y = textLabel.center.y
            header.addSubview(copyButton)
        default:
            break
        }
        header.addSubview(textLabel)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func decodeTx(walletName: String, param: String) {
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
        parsePrevTx(method: .gettransaction, param: "\"\(txid)\", true", vout: vout)
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
            let outputDict:[String:Any] = [
                "index": number,
                "amount": amount.avoidNotation,
                "address": addressString
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
            fee = inputTotal - outputTotal
            getAmountText()
        }
    }
    
    func parsePrevTx(method: BTC_CLI_COMMAND, param: String, vout: Int) {
        
        func decodeRaw() {
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
        
        func getRawTx() {
            let fetcher = TransactionFetcher.sharedInstance
            fetcher.fetch(txid: txid) { [unowned vc = self] rawHex in
                if rawHex != nil {
                    vc.parsePrevTx(method: .decoderawtransaction, param: "\"\(rawHex!)\"", vout: vout)
                }  else {
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "Error parsing inputs")
                }
            }
        }
        
        switch method {
        case .decoderawtransaction:
            decodeRaw()
        case .gettransaction:
            getRawTx()
        default:
            break
        }
        
    }
    
    @objc func copyTxid() {
        DispatchQueue.main.async { [unowned vc = self] in
            let pasteBoard = UIPasteboard.general
            pasteBoard.string = vc.txid
            displayAlert(viewController: vc, isError: false, message: "Transaction ID copied to clipboard")
        }
    }
    
    @objc func copyHex() {
        DispatchQueue.main.async { [unowned vc = self] in
            let pasteBoard = UIPasteboard.general
            pasteBoard.string = vc.txDict?["hex"] as? String ?? ""
            displayAlert(viewController: vc, isError: false, message: "Transaction hex copied to clipboard")
        }
    }
    
    private func updateExistsingTx(id: UUID, memo: String) {
        CoreDataService.updateEntity(id: id, keyToUpdate: "memo", newValue: memo, entityName: .transactions) { [unowned vc = self] (success, errorDescription) in
            if success{
                displayAlert(viewController: vc, isError: false, message: "Transaction memo updated")
            }
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
    
    private func saveTransactionDict(dict: [String:Any]) {
        CoreDataService.saveEntity(dict: dict, entityName: .transactions) { [unowned vc = self] (success, errorDescription) in
            if !success {
                showAlert(vc: vc, title: "", message: "There was an error saving the transaction locally, when it confirms you can tap the transaction on the home screen to add a memo to it. Let us know about the issue so we can fix it. Thank you.")
            } else {
                displayAlert(viewController: vc, isError: false, message: "Transaction saved successfully")
            }
        }
    }
    
    private func saveNewTx(memo: String) {
        print("saveNewTx")
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                var dict = [String:Any]()
                dict["id"] = UUID()
                dict["date"] = vc.dateUnix(unix: vc.txDict!["time"] as! Int32)
                dict["txid"] = vc.txid
                dict["memo"] = memo
                dict["accountLabel"] = wallet!.label
                dict["descriptor"] = wallet?.descriptor
                dict["xpub"] = vc.xpub(wallet!.descriptor)
                dict["miningFeeBtc"] = vc.fee
                dict["fingerprint"] = vc.fingerprint(wallet!.descriptor)
                if (vc.txDict!["amount"] as! Double) < 0 {
                    dict["btcSent"] = vc.txDict!["amount"] as! Double
                    dict["outgoing"] = true
                    dict["incoming"] = false
                } else {
                    dict["btcReceived"] = vc.txDict!["amount"] as! Double
                    dict["incoming"] = true
                    dict["outgoing"] = false
                }
                dict["derivation"] = wallet!.derivation
                vc.saveTransactionDict(dict: dict)
            } else {
                showAlert(vc: vc, title: "", message: "There was an error saving the transaction locally, when it confirms you can tap the transaction on the home screen to add a memo to it. Let us know about the issue so we can fix it. Thank you.")
            }
        }
    }
    
    private func updateTx(memo: String) {
        print("updateTx")
        CoreDataService.retrieveEntity(entityName: .transactions) { [unowned vc = self] (transactions, errorDescription) in
            if transactions != nil {
                if transactions!.count > 0 {
                    var exists = false
                    for (i, transaction) in transactions!.enumerated() {
                        let transactionStruct = TransactionStruct(dictionary: transaction)
                        if transactionStruct.txid == vc.txid {
                            exists = true
                        }
                        if i + 1 == transactions!.count {
                            if exists {
                                if transactionStruct.id != nil {
                                    vc.updateExistsingTx(id: transactionStruct.id!, memo: memo)
                                }
                            } else {
                                vc.saveNewTx(memo: memo)
                            }
                        }
                    }
                } else {
                    vc.saveNewTx(memo: memo)
                }
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != "" {
            updateTx(memo: textField.text!)
        }
    }
    
    private func formattedDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm"
        let strDate = dateFormatter.string(from: date)
        return strDate
    }

}
