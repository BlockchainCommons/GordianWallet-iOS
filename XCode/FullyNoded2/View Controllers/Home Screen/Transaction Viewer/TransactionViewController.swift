//
//  TransactionViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class TransactionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var walletName = ""
    var recipients = [String]()
    var inputArray = [[String:Any]]()
    var inputTableArray = [[String:Any]]()
    var outputArray = [[String:Any]]()
    var index = Int()
    var inputTotal = Double()
    var outputTotal = Double()
    var outputsString = ""
    var inputsString = ""
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
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadData()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func loadData() {
        executeNodeCommand(method: .gettransaction, param: "\"\(txid)\", true")
    }
    
    private func reloadTable() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.transactionTable.reloadData()
        }
    }
    
    private func parseTxDict(dict: NSDictionary) {
        print("dict = \(dict)")
        txDict = dict
        decodeTx(walletName: walletName, param: "\"\(dict["hex"] as! String)\"")
        //reloadTable()
        //creatingView.removeConnectingView()
        
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

    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
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
    
    // MARK: - TABLE STRUCTURE
    /// - Memo - editable textfield
    /// - Txid - copy button
    /// - Incoming or Outgoing
    /// - Amount sent or recieved
    /// - Number of confs
    /// - Date received or sent
    /// - Inputs with addresses and amounts (like verify view)
    /// - Outputs with addresses and amounts (like verify view)
    /// - USD value sent/receieved at time of tx and USD value now
    /// - Mining fee in btc and sats per byte and Mining fee in USD when sent and now
    /// - ETA if unconfirmed
    /// - RBF enabled - ideally with option to bump fee (future feature)
    /// - Raw hex with a copy button
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 13
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
        label.adjustsFontSizeToFitWidth = true
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
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return memoCell(indexPath: indexPath)
        case 1: return standardCell(indexPath: indexPath, text: txStruct?.txid ?? "")
        case 2:
            if txStruct?.outgoing ?? false {
                return standardCell(indexPath: indexPath, text: "Outgoing")
            } else {
                return standardCell(indexPath: indexPath, text: "Incoming")
            }
        case 3: return standardCell(indexPath: indexPath, text: "\(txDict?["amount"] as? Double ?? 0.0)")
        case 4: return standardCell(indexPath: indexPath, text: "\(txDict?["confirmations"] as? Int ?? 0)")
        case 5: return standardCell(indexPath: indexPath, text: formattedDate(date: txStruct?.date ?? Date.distantPast))
        case 6: return inputsCell(indexPath: indexPath)
        case 7: return outputsCell(indexPath: indexPath)
        default:
            return UITableViewCell()
        }
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
            textLabel.text = "MEMO - tap to edit"
        case 1:
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
            textLabel.text = "ID"
            let copyButton = UIButton()
            let copyImage = UIImage(systemName: "doc.on.doc")!
            copyButton.tintColor = .systemTeal
            copyButton.setImage(copyImage, for: .normal)
            copyButton.addTarget(self, action: #selector(copyTxid), for: .touchUpInside)
            copyButton.frame = CGRect(x: header.frame.maxX - 25, y: 0, width: 15, height: 18)
            copyButton.center.y = textLabel.center.y
            header.addSubview(copyButton)
        case 2:
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
            textLabel.text = "CATEGORY"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        case 3:
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
            textLabel.text = "AMOUNT"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        case 4:
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
            textLabel.text = "CONFIRMATIONS"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        case 5:
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
            textLabel.text = "DATE"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        case 6:
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
            textLabel.text = "INPUTS"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        case 7:
            header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
            textLabel.text = "OUTPUTS"
            textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
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
            
            reloadTable()
            creatingView.removeConnectingView()
            
        }
        
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
        
        switch method {
            
        case .decoderawtransaction:
            
            decodeRaw(walletName: walletName)
            
        case .getrawtransaction:
            
            getRawTx(walletName: walletName)
            
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != "" {
            /// Update Core Data here.
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

// MARK: - EXAMPLE DICT:

// SELF TRANSFER:

/*
 amount = 0;
 "bip125-replaceable" = no;
 blockhash = 0000000000000129cfc07a52c223038ae6222b4b939aba214b43b46a4d1a0430;
 blockheight = 1745666;
 blockindex = 55;
 blocktime = 1589861211;
 confirmations = 16;
 details =     (
             {
         abandoned = 0;
         address = tb1qxkcsr5g5ewlfpr3dr0sp24yq00jzn06k4ja4jp;
         amount = "-0.0001";
         category = send;
         fee = "-1.41e-06";
         involvesWatchonly = 1;
         label = "";
         vout = 0;
     },
             {
         address = tb1qxkcsr5g5ewlfpr3dr0sp24yq00jzn06k4ja4jp;
         amount = "0.0001";
         category = receive;
         involvesWatchonly = 1;
         label = "";
         vout = 0;
     }
 );
 fee = "-1.41e-06";
 hex = 02000000000101843047c0c02602d568ac3a098ad3c0a743d5c22fc998a27839f7b6b9e69845fd0000000000fdffffff02102700000000000016001435b101d114cbbe908e2d1be01554807be429bf56a31a0f000000000016001430e8aadbfada5b1970688c3454aa3a340c9f1d620247304402207ad4c8bf7a19459c49ce9a0737614ee21725027b1abf2f71bc72564098f79ee902203aa8758c12df24436e6b34925750f8ca5cfe1c0f3da134f71c781ad94e3fe289012103944cd4052d6f6d06d20336fb05f52df3484b0fc9886928beff7a76da50e63a3c00000000;
 time = 1589861160;
 timereceived = 1589861160;

 txid = 0d4f845f0abe7d1f72b02ea9773fa13541faffcf90a7f3eef1279b27b070bd3d;
 walletconflicts =     (
 );
 */

// RECEIVE
/*
 amount = "0.01";
 "bip125-replaceable" = no;
 blockhash = 0000000000000f4f2390da07249bd74835cd783518301fc118334f8b9cd8c60e;
 blockheight = 1745646;
 blockindex = 89;
 blocktime = 1589854767;
 confirmations = 36;
 details =     (
             {
         address = tb1qczflynvkcu8jswm5jh455shc3zxafptrlj7lxz;
         amount = "0.01";
         category = receive;
         involvesWatchonly = 1;
         label = "";
         vout = 0;
     }
 );
 hex = 02000000000101b502f62636b8cb17e628e81fe53f8a75da932ceec058b8b02a2ca6780e18c54a010000001716001410f2ef432f5435d5a945a97366d3c298c8e08bc8feffffff0240420f0000000000160014c093f24d96c70f283b7495eb4a42f8888dd485631617230000000000160014fcd60aed2043e043d145ceb9c2b16328ea74b0d90247304402201cd922dcd4f509a7b8064042980c8aaff81c78e34774b0ce08b85b26bcc3e5a1022003f66dc2da05ce53cfbccce9c647ca07b5a65c1315cefe5f2f96806110722d8e01210320e5bd6dfe5021e9e6c97d342e012888961add06e32aa778244036db97098b50eca21a00;
 time = 1589854112;
 timereceived = 1589854112;
 txid = fd4598e6b9b6f73978a298c92fc2d543a7c0d38a093aac68d50226c0c0473084;
 walletconflicts =     (
 );
 */
