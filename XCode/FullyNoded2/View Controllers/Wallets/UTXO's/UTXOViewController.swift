//
//  UTXOViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class UTXOViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate {
    
    var utxosToLock = [[String:Any]]()
    var utxosToUnlock = [[String:Any]]()
    var editButton = UIBarButtonItem()
    var walletName = ""
    var tapQRGesture = UITapGestureRecognizer()
    var tapTextViewGesture = UITapGestureRecognizer()
    let refresher = UIRefreshControl()
    var unlockedUtxoArray = [[String:Any]]()
    var lockedUtxoArray = [[String:Any]]()
    var address = ""
    var creatingView = ConnectingView()
    var isFirstTime = Bool()
    var utxo = [String:Any]()
    @IBOutlet var utxoTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(clickedEditButton(sender:)))
        navigationItem.setRightBarButton(editButton, animated: true)
        utxoTable.delegate = self
        utxoTable.dataSource = self
        utxoTable.tableFooterView = UIView(frame: .zero)
        utxoTable.allowsMultipleSelectionDuringEditing = true
        load()
    }
    
    @objc func load() {
        addSpinner()
        unlockedUtxoArray.removeAll()
        lockedUtxoArray.removeAll()
        loadData()
    }
    
    private func loadData() {
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            vc.walletName = wallet!.name!
            if wallet != nil && !error {
                vc.getUtxos()
            }
        }
    }
    
    private func getUtxos() {
        utxosToUnlock.removeAll()
        utxosToLock.removeAll()
        lockedUtxoArray.removeAll()
        unlockedUtxoArray.removeAll()
        DispatchQueue.main.async { [unowned vc = self] in
            vc.creatingView.label.text = "getting utxo's..."
        }
        Reducer.makeCommand(walletName: walletName, command: .listunspent, param: "0") { [unowned vc = self] (object, errorDesc) in
            if let resultArray = object as? NSArray {
                vc.parseUnspent(utxos: resultArray)
            } else {
                DispatchQueue.main.async {
                    vc.removeSpinner()
                    displayAlert(viewController: vc, isError: true, message: "error fetching utxos")
                }
            }
        }
    }
    
    @objc func clickedEditButton(sender: UIBarButtonItem) {
        updateEditButton()
    }
    
    private func updateEditButton() {
        utxoTable.setEditing(true, animated: true)
        editButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneEditing))
        navigationItem.setRightBarButton(editButton, animated: true)
    }
    
    @objc func doneEditing() {
        if utxosToLock.count > 0 || utxosToUnlock.count > 0 {
            promptToEdit()
        } else {
            cancelEditing()
        }
    }
    
    private func cancelEditing() {
        utxosToUnlock.removeAll()
        utxosToLock.removeAll()
        editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(clickedEditButton))
        DispatchQueue.main.async { [unowned vc = self] in
            vc.utxoTable.setEditing(false, animated: true)
            vc.navigationItem.setRightBarButton(vc.editButton, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return sectionZeroCount()
        } else {
            return sectionOneCount()
        }
    }
    
    private func sectionZeroCount() -> Int {
        if unlockedUtxoArray.count > 0 {
            return unlockedUtxoArray.count
        } else {
            return 1
        }
    }
    
    private func sectionOneCount() -> Int {
        if lockedUtxoArray.count > 0 {
            return lockedUtxoArray.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return unlockedCellHeight()
        } else {
            return lockedCellHeight()
        }
    }
    
    private func unlockedCellHeight() -> CGFloat {
        if unlockedUtxoArray.count > 0 {
            return 121
        } else {
            return 47
        }
    }
    
    private func lockedCellHeight() -> CGFloat {
        if lockedUtxoArray.count > 0 {
            return 81
        } else {
            return 47
        }
    }
    
    private func unlockedCell(_ indexPath: IndexPath) -> UITableViewCell {
        if unlockedUtxoArray.count > 0 {
            return unlockedUtxoCell(indexPath)
        } else {
            return noUnlockedUtxosCell(indexPath)
        }
    }
    
    private func lockedCell(_ indexPath: IndexPath) -> UITableViewCell {
        if lockedUtxoArray.count > 0 {
            return lockedUtxoCell(indexPath)
        } else {
            return noLockedUtxosCell(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return unlockedCell(indexPath)
        } else {
            return lockedCell(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView.isEditing {
            return UITableViewCell.EditingStyle.init(rawValue: 3)!
        }
        return .none
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && unlockedUtxoArray.count > 0 {
            utxosToLock.append(unlockedUtxoArray[indexPath.row])
        } else if indexPath.section == 1 && lockedUtxoArray.count > 0 {
            utxosToUnlock.append(lockedUtxoArray[indexPath.row])
        } else {
            showAlert(vc: self, title: "Oops", message: "You can not edit that cell.")
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && utxosToLock.count > 0 {
            let utxo = unlockedUtxoArray[indexPath.row]
            removeUtxoToLock(utxo)
        } else if indexPath.section == 1 && utxosToUnlock.count > 0 {
            let utxo = lockedUtxoArray[indexPath.row]
            removeUtxoToUnlock(utxo)
        } else {
            showAlert(vc: self, title: "Oops", message: "You can not edit that cell.")
        }
    }
    
    private func removeUtxoToLock(_ utxo: [String:Any]) {
        var indexToRemove:Int!
        for (i, utxoToRemove) in utxosToLock.enumerated() {
            if utxoToRemove["id"] as! UUID == utxo["id"] as! UUID {
                indexToRemove = i
            }
            if i + 1 == utxosToLock.count {
                utxosToLock.remove(at: indexToRemove)
                print("utxosToLock: \(utxosToLock)")
            }
        }
    }
    
    private func removeUtxoToUnlock(_ utxo: [String:Any]) {
        var indexToRemove:Int!
        for (i, utxoToRemove) in utxosToUnlock.enumerated() {
            if utxoToRemove["id"] as! UUID == utxo["id"] as! UUID {
                indexToRemove = i
            }
            if i + 1 == utxosToUnlock.count {
                utxosToUnlock.remove(at: indexToRemove)
            }
        }
    }
    
    private func unlockedUtxoCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = utxoTable.dequeueReusableCell(withIdentifier: "unlockedUtxoCell", for: indexPath)
        cell.selectionStyle = .blue
        if unlockedUtxoArray.count > 0 {
            let dict = unlockedUtxoArray[indexPath.row]
            let address = cell.viewWithTag(1) as! UILabel
            let amount = cell.viewWithTag(4) as! UILabel
            let confs = cell.viewWithTag(8) as! UILabel
            let label = cell.viewWithTag(11) as! UILabel
            let infoButton = cell.viewWithTag(12) as! UIButton
            infoButton.addTarget(self, action: #selector(getInfo(_:)), for: .touchUpInside)
            infoButton.restorationIdentifier = "\(indexPath.row)"
            
            for (key, value) in dict {
                switch key {
                case "address":
                    address.text = "\(value)"
                    
                case "amount":
                    let dbl = rounded(number: value as! Double)
                    amount.text = dbl.avoidNotation
                    
                case "confirmations":
                    if (value as! Int) == 0 {
                        confs.textColor = .systemRed
                    } else {
                        confs.textColor = .systemGreen
                    }
                    confs.text = "\(value) confs"
                    
                case "label":
                    label.text = (value as! String)
                    
                default:
                    break
                }
            }
            
        }
        return cell
    }
    
    private func lockedUtxoCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = utxoTable.dequeueReusableCell(withIdentifier: "lockedUtxoCell", for: indexPath)
        cell.selectionStyle = .blue
        let vout = cell.viewWithTag(1) as! UILabel
        let txid = cell.viewWithTag(2) as! UILabel
        let info = cell.viewWithTag(3) as! UIButton
        info.addTarget(self, action: #selector(getLockedInfo(_:)), for: .touchUpInside)
        info.restorationIdentifier = "\(indexPath.row)"
        if lockedUtxoArray[indexPath.row]["vout"] != nil {
            vout.text = "\(lockedUtxoArray[indexPath.row]["vout"] as! Int)"
        } else {
            vout.text = ""
        }
        txid.text = lockedUtxoArray[indexPath.row]["txid"] as? String ?? ""
        return cell
    }
    
    private func noLockedUtxosCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.text = "⚠︎ No locked UTXO's"
        cell.textLabel?.textAlignment = .left
        cell.textLabel?.textColor = .darkGray
        cell.backgroundColor = #colorLiteral(red: 0.04409969419, green: 0.05159802417, blue: 0.05712642766, alpha: 1)
        return cell
    }
    
    private func noUnlockedUtxosCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.text = "⚠︎ No unlocked UTXO's"
        cell.textLabel?.textAlignment = .left
        cell.textLabel?.textColor = .darkGray
        cell.backgroundColor = #colorLiteral(red: 0.04409969419, green: 0.05159802417, blue: 0.05712642766, alpha: 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
        
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        textLabel.textColor = .systemGray
        textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        
        let unlockAllButton = UIButton()
        unlockAllButton.setTitle("unlock all", for: .normal)
        unlockAllButton.setTitleColor(.systemTeal, for: .normal)
        unlockAllButton.titleLabel?.textAlignment = .right
        unlockAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        unlockAllButton.addTarget(self, action: #selector(unlockAll), for: .touchUpInside)
        unlockAllButton.frame = CGRect(x: header.frame.maxX - 95, y: 0, width: 80, height: 30)
        
        let lockAllButton = UIButton()
        lockAllButton.setTitle("  lock all", for: .normal)
        lockAllButton.setTitleColor(.systemTeal, for: .normal)
        lockAllButton.titleLabel?.textAlignment = .right
        lockAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        lockAllButton.addTarget(self, action: #selector(lockAll), for: .touchUpInside)
        lockAllButton.frame = CGRect(x: header.frame.maxX - 95, y: 0, width: 80, height: 30)
        
        if section == 0 {
            textLabel.text = "Unlocked"
            header.addSubview(lockAllButton)
        } else {
            textLabel.text = "Locked"
            header.addSubview(unlockAllButton)
        }
        
        header.addSubview(textLabel)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    @objc func unlockAll() {
        if lockedUtxoArray.count > 0 {
            for utxo in lockedUtxoArray {
                utxosToUnlock.append(utxo)
            }
            promptToEdit()
        } else {
            showAlert(vc: self, title: "No utxos to lock", message: "")
        }
    }
    
    @objc func lockAll() {
        if unlockedUtxoArray.count > 0 {
            for utxo in unlockedUtxoArray {
                utxosToLock.append(utxo)
            }
            promptToEdit()
        } else {
            showAlert(vc: self, title: "No utxos to unlock", message: "")
        }
    }
    
    @objc func getLockedInfo(_ sender: UIButton) {
        if sender.restorationIdentifier != nil {
            if let index = Int(sender.restorationIdentifier!) {
                showLockedDetail(lockedUtxoArray[index])
            }
        }
    }
    
    private func showLockedDetail(_ lockedUtxo: [String:Any]) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.utxo = lockedUtxo
            vc.performSegue(withIdentifier: "segueToLockedUtxo", sender: vc)
        }
    }
    
    private func promptToEdit() {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: vc.alertTitle(), message: "⚠︎ Locking utxo's makes them temporarily unspendable ⚠︎\n\n⚠︎ All utxo's will become unlocked automatically if your node reboots! ⚠︎", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [unowned vc = self] action in
                vc.creatingView.addConnectingView(vc: self, description: "")
                vc.updateUtxosToLock()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned vc = self] action in
                vc.cancelEditing()
            }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func alertTitle() -> String {
        var title = ""
        if utxosToLock.count > 0 && utxosToUnlock.count > 0 {
            title = "Unlock \(utxosToUnlock.count) utxo's and lock \(utxosToLock.count) utxo's?"
        } else if utxosToLock.count > 0 && utxosToUnlock.count == 0 {
            title = "Lock \(utxosToLock.count) utxo's?"
        } else if utxosToLock.count == 0 && utxosToUnlock.count > 0 {
            title = "Unlock \(utxosToUnlock.count) utxo's?"
        }
        return title
    }
    
    private func updateUtxosToLock() {
        if utxosToLock.count > 0 {
            DispatchQueue.main.async { [unowned vc = self] in
                vc.creatingView.label.text = "locking utxo's..."
            }
            CoinControl.lockUtxos(utxos: utxosToLock) { [unowned vc = self] success in
                if success {
                    displayAlert(viewController: vc, isError: false, message: "utxo's locked")
                    if vc.utxosToUnlock.count > 0 {
                        vc.updateUtxosToUnlock()
                    } else {
                        vc.cancelEditing()
                        vc.getUtxos()
                    }
                } else {
                    vc.cancelEditing()
                    vc.removeSpinner()
                    showAlert(vc: vc, title: "Error", message: "There was an error locking your utxo's")
                }
            }
        } else {
            updateUtxosToUnlock()
        }
    }
    
    private func updateUtxosToUnlock() {
        if utxosToUnlock.count > 0 {
            DispatchQueue.main.async { [unowned vc = self] in
                vc.creatingView.label.text = "unlocking utxo..."
            }
            CoinControl.unlockUtxos(utxos: utxosToUnlock) { [unowned vc = self] success in
                if success {
                    displayAlert(viewController: vc, isError: false, message: "utxo's unlocked")
                    vc.cancelEditing()
                    vc.getUtxos()
                } else {
                    vc.cancelEditing()
                    vc.removeSpinner()
                    showAlert(vc: vc, title: "Error", message: "There was an error unlocking your utxo's.")
                }
            }
        } else {
            cancelEditing()
            removeSpinner()
        }
    }
    
    private func process(_ utxos: [String]) -> String {
        var processedUtxos = (utxos.description).replacingOccurrences(of: "\"{", with: "{")
        processedUtxos = processedUtxos.replacingOccurrences(of: "}\"", with: "}")
        processedUtxos = processedUtxos.replacingOccurrences(of: "\"[", with: "[")
        processedUtxos = processedUtxos.replacingOccurrences(of: "]\"", with: "]")
        return processedUtxos.replacingOccurrences(of: "\\\"", with: "\"")
    }
    
    @objc func getInfo(_ sender: UIButton) {
        if sender.restorationIdentifier != nil {
            if let index = Int(sender.restorationIdentifier!) {
                utxo = unlockedUtxoArray[index]
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.performSegue(withIdentifier: "utxoInfo", sender: vc)
                }
            }
        }
    }
    
    private func parseUnspent(utxos: NSArray) {
        if utxos.count > 0 {
            unlockedUtxoArray = (utxos as NSArray).sortedArray(using: [NSSortDescriptor(key: "confirmations", ascending: true)]) as! [[String:AnyObject]]
            for (i, _) in unlockedUtxoArray.enumerated() {
                unlockedUtxoArray[i]["id"] = UUID()
            }
            getLockedUtxos()
        } else {
            getLockedUtxos()
        }
    }
    
    private func getLockedUtxos() {
        Reducer.makeCommand(walletName: walletName, command: .listlockunspent, param: "") { [unowned vc = self] (object, errorDescription) in
            if let lockedUtxos = object as? NSArray {
                if lockedUtxos.count > 0 {
                    vc.buildArray(lockedUtxos)
                } else {
                    vc.loadTable()
                    vc.removeSpinner()
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
                    let dict = ["txid":txid,"vout":vout,"id":UUID()] as [String : Any]
                    lockedUtxoArray.append(dict)
                }
            }
            if i + 1 == locked.count {
                loadTable()
                removeSpinner()
            }
        }
    }
    
    private func loadTable() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.utxoTable.reloadData()
        }
    }
        
    func removeSpinner() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.refresher.endRefreshing()
            vc.creatingView.removeConnectingView()
        }
    }
    
    func addSpinner() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.creatingView.addConnectingView(vc: self, description: "Getting UTXOs")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "utxoInfo":
            if let vc = segue.destination as? UtxoInfoViewController {
                vc.utxo = utxo
            }
        case "segueToLockedUtxo":
            if let vc = segue.destination as? LockedUtxosViewController {
                vc.utxo = utxo
            }
        default:
            break
        }
    }
    
}

extension Int {
    
    var avoidNotation: String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(for: self) ?? ""
        
    }
}



