//
//  LockedUtxosViewController.swift
//  FullyNoded2
//
//  Created by Peter on 08/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class LockedUtxosViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    var walletName:String!
    var index:Int!
    var creatingView = ConnectingView()
    let refresher = UIRefreshControl()
    var lockedUtxos = [[String:Any]]()
    @IBOutlet weak var lockedTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        lockedTable.delegate = self
        lockedTable.dataSource = self
        loadData()
    }
    
    private func loadData() {
        creatingView.addConnectingView(vc: self, description: "getting locked utxos...")
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                vc.walletName = wallet!.name!
                vc.getLockedUtxos(wallet: vc.walletName)
            } else {
                vc.removeSpinner()
                showAlert(vc: vc, title: "Error", message: "no active wallet")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return lockedUtxos.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 102
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "lockedUtxoCell", for: indexPath)
        cell.selectionStyle = .none
        
        let confs = cell.viewWithTag(8) as! UILabel
        confs.text = (lockedUtxos[indexPath.section]["confirmations"] as? String ?? "") + " " + "confs"
        
        let label = cell.viewWithTag(11) as! UILabel
        label.text = lockedUtxos[indexPath.section]["label"] as? String ?? "no label"
        
        let amount = cell.viewWithTag(4) as! UILabel
        amount.text = lockedUtxos[indexPath.section]["amount"] as? String ?? ""
        
        let address = cell.viewWithTag(1) as! UILabel
        address.text = lockedUtxos[indexPath.section]["address"] as? String ?? ""
        
        let unlockButton = cell.viewWithTag(12) as! UIButton
        unlockButton.restorationIdentifier = "\(indexPath.section)"
        unlockButton.addTarget(self, action: #selector(unlock(_:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func unlock(_ sender: UIButton) {
        if sender.restorationIdentifier != nil {
            if let index = Int(sender.restorationIdentifier!) {
                promptToUnlock(lockedUtxos[index])
            }
        }
    }
    
    private func promptToUnlock(_ utxo: [String:Any]) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Unlock UTXO?", message: "Unlocking this utxo will make it spendable.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "unlock", style: .default, handler: { [unowned vc = self] action in
                vc.unlockUtxo(utxo)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func unlockUtxo(_ utxo: [String:Any]) {
        creatingView.addConnectingView(vc: self, description: "unlocking utxo...")
        let txid = utxo["txid"] as! String
        let vout = utxo["vout"] as! Int
        let param = "true, ''[{\"txid\":\"\(txid)\",\"vout\":\(vout)}]''"
        Reducer.makeCommand(walletName: walletName, command: .lockunspent, param: param) { [unowned vc = self] (object, errorDescription) in
            if let _ = object as? Bool {
                displayAlert(viewController: vc, isError: false, message: "utxo unlocked")
                vc.getLockedUtxos(wallet: vc.walletName)
            } else {
                vc.removeSpinner()
                showAlert(vc: vc, title: "Error", message: "There was an error unlocking your utxo: \(errorDescription ?? "unknown")")
            }
        }
    }
    
    private func getLockedUtxos(wallet: String) {
        lockedUtxos.removeAll()
        Reducer.makeCommand(walletName: wallet, command: .listlockunspent, param: "") { [unowned vc = self] (object, errorDescription) in
            if let lockedUtxos = object as? NSArray {
                if lockedUtxos.count > 0 {
                    vc.buildArray(lockedUtxos)
                } else {
                    vc.loadTable()
                    vc.removeSpinner()
                    showAlert(vc: vc, title: "No locked utxo's", message: "")
                }
            } else {
                showAlert(vc: vc, title: "Error", message: "error fetching locked utxos")
                vc.removeSpinner()
            }
        }
    }
    
    private func buildArray(_ locked: NSArray) {
        for (i, utxo) in locked.enumerated() {
            if let lockedUtxo = utxo as? NSDictionary {
                if let txid = lockedUtxo["txid"] as? String, let vout = lockedUtxo["vout"] as? Int {
                    let dict = ["txid":txid,"vout":vout] as [String : Any]
                    lockedUtxos.append(dict)
                }
            }
            if i + 1 == locked.count {
                if lockedUtxos.count > 0 {
                    fetchTransactions(index: 0)
                } else {
                    removeSpinner()
                    showAlert(vc: self, title: "No locked utxo's", message: "")
                }
            }
        }
    }
    
    private func fetchTransactions(index: Int) {
        if index < lockedUtxos.count {
            getTransaction(index: index)
        } else {
            loadTable()
            removeSpinner()
        }
    }
    
    private func getTransaction(index: Int) {
        let utxo = lockedUtxos[index]
        let txid = utxo["txid"] as! String
        let vout = utxo["vout"] as! Int
        Reducer.makeCommand(walletName: walletName, command: .gettransaction, param: "\"\(txid)\"") { [unowned vc = self] (object, errorDescription) in
            if let transaction = object as? NSDictionary {
                vc.parseTransaction(transaction: transaction, index: index, vout: vout)
            }
        }
    }
    
    private func parseTransaction(transaction: NSDictionary, index: Int, vout: Int) {
        if let details = transaction["details"] as? NSArray {
            for output in details {
                if let dict = output as? NSDictionary, let txVout = dict["vout"] as? Int {
                    if vout == txVout {
                        if let amount = dict["amount"] as? Double {
                            lockedUtxos[index]["amount"] = rounded(number: amount).avoidNotation
                        }
                        if let confs = transaction["confirmations"] as? Int {
                            lockedUtxos[index]["confirmations"] = "\(confs)"
                        }
                        if let address = dict["address"] as? String {
                            lockedUtxos[index]["address"] = address
                        }
                        if let label = dict["label"] as? String {
                            lockedUtxos[index]["label"] = label
                        }
                        fetchTransactions(index: (index + 1))
                    }
                } else {
                    removeSpinner()
                    showAlert(vc: self, title: "Error", message: "There was an error parsing your locked utxo's.")
                }
            }
        } else {
            removeSpinner()
            showAlert(vc: self, title: "Error", message: "There was an error parsing your locked utxo's.")
        }
    }
    
    private func loadTable() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.lockedTable.reloadData()
        }
    }
    
    private func removeSpinner() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.refresher.endRefreshing()
            vc.creatingView.removeConnectingView()
        }
    }

}
