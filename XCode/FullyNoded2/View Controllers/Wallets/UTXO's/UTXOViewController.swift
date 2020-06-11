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
        return sectionZeroCount() + sectionOneCount()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
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
        if indexPath.section < unlockedUtxoArray.count || indexPath.section == 0 {
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
            return 121
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
            return lockedUtxoCell1(indexPath)
        } else {
            return noLockedUtxosCell(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < unlockedUtxoArray.count || indexPath.section == 0 {
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
        if tableView.isEditing {
            if indexPath.section < unlockedUtxoArray.count && unlockedUtxoArray.count > 0 {
                utxosToLock.append(unlockedUtxoArray[indexPath.section])
            } else if indexPath.section >= unlockedUtxoArray.count && lockedUtxoArray.count > 0 && indexPath.section != 0 {
                if unlockedUtxoArray.count > 0 {
                    utxosToUnlock.append(lockedUtxoArray[indexPath.section - unlockedUtxoArray.count])
                } else {
                    utxosToUnlock.append(lockedUtxoArray[indexPath.section - 1])
                }
            } else {
                showAlert(vc: self, title: "Oops", message: "You can not edit that cell.")
            }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            if indexPath.section < unlockedUtxoArray.count && utxosToLock.count > 0 {
                let utxo = unlockedUtxoArray[indexPath.section]
                removeUtxoToLock(utxo)
            } else if indexPath.section >= unlockedUtxoArray.count && utxosToUnlock.count > 0 && indexPath.section != 0 {
                if unlockedUtxoArray.count > 0 {
                    let utxo = lockedUtxoArray[indexPath.section - unlockedUtxoArray.count]
                    removeUtxoToUnlock(utxo)
                } else {
                    let utxo = lockedUtxoArray[indexPath.section - 1]
                    removeUtxoToUnlock(utxo)
                }
            } else {
                showAlert(vc: self, title: "Oops", message: "You can not edit that cell.")
            }
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
            let dict = unlockedUtxoArray[indexPath.section]
            let address = cell.viewWithTag(1) as! UILabel
            let amount = cell.viewWithTag(4) as! UILabel
            let confs = cell.viewWithTag(8) as! UILabel
            let label = cell.viewWithTag(11) as! UILabel
            let infoButton = cell.viewWithTag(12) as! UIButton
            let change = cell.viewWithTag(13) as! UILabel
            let dust = cell.viewWithTag(14) as! UILabel
            change.alpha = 0
            dust.alpha = 0
            infoButton.addTarget(self, action: #selector(getInfo(_:)), for: .touchUpInside)
            infoButton.restorationIdentifier = "\(indexPath.section)"
            
            if isChange(dict["desc"] as? String ?? "") {
                change.alpha = 1
            }
            
            for (key, value) in dict {
                switch key {
                case "address":
                    address.text = "\(value)"
                    
                case "amount":
                    let dbl = rounded(number: value as! Double)
                    amount.text = dbl.avoidNotation
                    if (dict["amount"] as! Double) < 0.00010000 {
                        dust.alpha = 1
                    }
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
    
    private func lockedUtxoCell1(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = utxoTable.dequeueReusableCell(withIdentifier: "lockedUtxoCell1", for: indexPath)
        cell.selectionStyle = .blue
        
        if lockedUtxoArray.count > 0 {
            var section:Int!
            if unlockedUtxoArray.count > 0 {
                section = indexPath.section - unlockedUtxoArray.count
            } else {
                section = indexPath.section - 1
            }
            let dict = lockedUtxoArray[section]
            let address = cell.viewWithTag(1) as! UILabel
            let amount = cell.viewWithTag(4) as! UILabel
            let confs = cell.viewWithTag(8) as! UILabel
            let label = cell.viewWithTag(11) as! UILabel
            let infoButton = cell.viewWithTag(12) as! UIButton
            let change = cell.viewWithTag(13) as! UILabel
            let dust = cell.viewWithTag(14) as! UILabel
            change.alpha = 0
            dust.alpha = 0
            infoButton.addTarget(self, action: #selector(getInfo(_:)), for: .touchUpInside)
            infoButton.restorationIdentifier = "\(String(describing: section))"
            address.text = dict["address"] as? String ?? "?"
            label.text = dict["label"] as? String ?? "?"
            if dict["amount"] != nil {
                amount.text = (dict["amount"] as! Double).avoidNotation
                if (dict["amount"] as! Double) < 0.00010000 {
                    dust.alpha = 1
                }
            } else {
                amount.text = "?"
            }
            
            if dict["confs"] != nil {
                let confirmations = dict["confs"] as! Int
                if confirmations == 0 {
                    confs.textColor = .systemRed
                } else {
                    confs.textColor = .systemGreen
                }
                confs.text = "\(confirmations) confs"
            } else {
                confs.text = "?"
            }
            if isChange(dict["desc"] as? String ?? "") {
                change.alpha = 1
            }
        }
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
        
        var sectionCount:Int!
        if unlockedUtxoArray.count > 0 {
            sectionCount = unlockedUtxoArray.count
        } else {
            sectionCount = 1
        }
        
        if section == 0 {
            textLabel.text = "Unlocked"
            header.addSubview(lockAllButton)
        } else if section == sectionCount {
            textLabel.text = "Locked"
            header.addSubview(unlockAllButton)
        }
        
        header.addSubview(textLabel)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if unlockedUtxoArray.count > 0 {
            if section == 0 {
                return 30
            } else if section < unlockedUtxoArray.count {
                return 5
            } else if section == unlockedUtxoArray.count {
                return 30
            } else {
                return 5
            }
        } else if lockedUtxoArray.count > 0 {
            if section == 1 || section == 0 {
                return 30
            } else {
                return 5
            }
        } else {
            return 5
        }
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
        var savedLockedUtxos = [[String:Any]]()
        CoreDataService.retrieveEntity(entityName: .lockedUtxos) { [unowned vc = self] (savedUtxos, errorDescription) in
            if savedUtxos != nil {
                savedLockedUtxos = savedUtxos!
            }
            for (i, utxo) in locked.enumerated() {
                if let lockedUtxo = utxo as? NSDictionary {
                    if let txid = lockedUtxo["txid"] as? String, let vout = lockedUtxo["vout"] as? Int {
                        let fallbackDict = ["txid":txid,"vout":vout,"id":UUID()] as [String : Any]
                        var notSaved = true
                        for (x, saved) in savedLockedUtxos.enumerated() {
                            let lockedStruct = LockedUtxoStruct.init(dictionary: saved)
                            if lockedStruct.txid == txid && lockedStruct.vout == vout {
                                notSaved = false
                                vc.lockedUtxoArray.append(saved)/// we have is stored locally already and can display metadata
                            }
                            if x + 1 == savedLockedUtxos.count {
                                if notSaved {
                                    vc.lockedUtxoArray.append(fallbackDict)/// we do not have it stored locally and can not display metadata
                                }
                                if i + 1 == locked.count {
                                    vc.loadTable()
                                    vc.removeSpinner()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loadTable() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.utxoTable.reloadData()
        }
    }
        
    private func removeSpinner() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.refresher.endRefreshing()
            vc.creatingView.removeConnectingView()
        }
    }
    
    private func addSpinner() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.creatingView.addConnectingView(vc: self, description: "Getting UTXOs")
        }
    }
    
    private func isChange(_ desc: String) -> Bool {
        if desc.contains("/1/") {
            return true
        } else {
            return false
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



