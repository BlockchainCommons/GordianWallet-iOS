//
//  WalletsViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 10/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    var name = ""
    var node:NodeStruct!
    var wallets = [[String:Any]]()
    var wallet:WalletStruct!
    var sortedWallets = [[String:Any]]()
    let dateFormatter = DateFormatter()
    let creatingView = ConnectingView()
    var editButton = UIBarButtonItem()
    var addButton = UIBarButtonItem()
    let cd = CoreDataService()
    var nodes = [[String:Any]]()
    var recoveryPhrase = ""
    var descriptor = ""
    @IBOutlet var walletTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        walletTable.delegate = self
        walletTable.dataSource = self
        editButton = UIBarButtonItem.init(barButtonSystemItem: .edit, target: self, action: #selector(editWallets))
        addButton = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(createWallet))
        self.navigationItem.setRightBarButton(addButton, animated: true)
        self.navigationItem.setLeftBarButton(editButton, animated: true)
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        refresh()
        
        DispatchQueue.main.async {
            
            self.walletTable.setContentOffset(.zero, animated: true)
            
        }
        
    }
    
    @objc func editWallets() {
        
        walletTable.setEditing(!walletTable.isEditing, animated: true)
        
        if walletTable.isEditing {
            
            editButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(editWallets))
            
        } else {
            
            editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editWallets))
            
        }
        
        self.navigationItem.setLeftBarButton(editButton, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        if tableView.isEditing {
            
            return .delete
            
        }

        return .none
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let id = sortedWallets[indexPath.section]["id"] as! UUID
            cd.updateEntity(id: id, keyToUpdate: "isArchived", newValue: true, entityName: .wallets) {
                
                if !self.cd.errorBool {
                                        
                    DispatchQueue.main.async {
                        
                        self.sortedWallets.remove(at: indexPath.section)
                        tableView.deleteSections(IndexSet.init(arrayLiteral: indexPath.section), with: .fade)
                        
                    }
                    
                } else {
                    
                    displayAlert(viewController: self, isError: true, message: "error deleting node")
                    
                }
                
            }
                        
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
        
    }
    
    func onionAddress(wallet: WalletStruct) -> String {
        
        var rpcOnion = ""
    
        for n in nodes {
            
            let s = NodeStruct(dictionary: n)
            
            if s.id == wallet.nodeId {
                
                rpcOnion = s.onionAddress
                
            }
            
        }
        
        return rpcOnion
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        nodes.removeAll()
        
    }
    
    func refresh() {
        print("refresh")
        
        sortedWallets.removeAll()
        
        let enc = Encryption()
        cd.retrieveEntity(entityName: .nodes) { (nodes, errorDescription) in
            
            if errorDescription == nil && nodes != nil {
                
                self.nodes = nodes!
                
                for (i, n) in nodes!.enumerated() {
                    
                    enc.decryptData(dataToDecrypt: (n["onionAddress"] as! Data)) { (decryptedOnionAddress) in
                        
                        if decryptedOnionAddress != nil {
                            
                            self.nodes[i]["onionAddress"] = String(bytes: decryptedOnionAddress!, encoding: .utf8)
                            
                        }
                        
                        enc.decryptData(dataToDecrypt: (n["label"] as! Data)) { (decryptedLabel) in
                        
                            if decryptedLabel != nil {
                                
                                self.nodes[i]["label"] = String(bytes: decryptedLabel!, encoding: .utf8)
                                
                            }
                            
                        }
                        
                        if i + 1 == nodes!.count {
                            
                            self.cd.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                                
                                if errorDescription == nil {
                                    
                                    if wallets!.count == 0 {
                                        
                                        self.createWallet()
                                        
                                    } else {
                                        
                                        for (i, w) in wallets!.enumerated() {
                                            
                                            let s = WalletStruct(dictionary: w)
                                            
                                            if !s.isArchived {
                                                
                                                self.sortedWallets.append(w)
                                                
                                            }
                                            
                                            if i + 1 == wallets!.count {
                                                
                                                self.sortedWallets = self.sortedWallets.sorted{ ($0["lastUsed"] as? Date ?? Date()) > ($1["lastUsed"] as? Date ?? Date()) }
                                                
                                                DispatchQueue.main.async {
                                                    
                                                    self.walletTable.reloadData()
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    
                                    displayAlert(viewController: self, isError: true, message: errorDescription!)
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                                        
                }
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if sortedWallets.count == 0 {
            
            return 1
            
        } else {
            
            return sortedWallets.count
            
        }
        
    }
    
    private func singleSigCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let d = sortedWallets[indexPath.section]
        let wallet = WalletStruct.init(dictionary: d)
        
        let cell = walletTable.dequeueReusableCell(withIdentifier: "singleSigWalletCell", for: indexPath)
        cell.selectionStyle = .none
        
        let balanceLabel = cell.viewWithTag(1) as! UILabel
        let isActive = cell.viewWithTag(2) as! UISwitch
        let exportKeysButton = cell.viewWithTag(3) as! UIButton
        let verifyAddresses = cell.viewWithTag(4) as! UIButton
        let refreshData = cell.viewWithTag(5) as! UIButton
        let showInvoice = cell.viewWithTag(6) as! UIButton
        let makeItCold = cell.viewWithTag(7) as! UIButton
        let networkLabel = cell.viewWithTag(8) as! UILabel
        let utxosButton = cell.viewWithTag(9) as! UIButton
        let derivationLabel = cell.viewWithTag(11) as! UILabel
        let getWalletInfoButton = cell.viewWithTag(12) as! UIButton
        let updatedLabel = cell.viewWithTag(13) as! UILabel
        let createdLabel = cell.viewWithTag(14) as! UILabel
        //let nodeSeedLabel = cell.viewWithTag(15) as! UILabel
        let shareSeedButton = cell.viewWithTag(16) as! UIButton
        let rpcOnionLabel = cell.viewWithTag(19) as! UILabel
        let walletFileLabel = cell.viewWithTag(20) as! UILabel
        let seedOnDeviceView = cell.viewWithTag(21)!
        //let seedOnNodeView = cell.viewWithTag(22)!
        let isActiveLabel = cell.viewWithTag(24) as! UILabel
        let stackView = cell.viewWithTag(25)!
        let nodeView = cell.viewWithTag(26)!
        let nodeLabel = cell.viewWithTag(27) as! UILabel
        let deviceXprv = cell.viewWithTag(28) as! UILabel
        let bannerView = cell.viewWithTag(32)!
        
        if wallet.isActive {
            
            isActive.isOn = true
            isActiveLabel.text = "Active"
            isActiveLabel.textColor = .lightGray
            cell.contentView.alpha = 1
            bannerView.backgroundColor = #colorLiteral(red: 0, green: 0.1631944358, blue: 0.3383367703, alpha: 1)
            
        } else if !wallet.isActive {
            
            isActive.isOn = false
            isActiveLabel.text = "Inactive"
            isActiveLabel.textColor = .darkGray
            cell.contentView.alpha = 0.6
            bannerView.backgroundColor = #colorLiteral(red: 0.1051254794, green: 0.1292803288, blue: 0.1418488324, alpha: 1)
            
        }
        
        isActive.addTarget(self, action: #selector(makeActive(_:)), for: .valueChanged)
        isActive.restorationIdentifier = "\(indexPath.section)"
        
        if isActive.isOn {
            
            utxosButton.addTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            makeItCold.addTarget(self, action: #selector(makeCold(_:)), for: .touchUpInside)
            showInvoice.addTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            shareSeedButton.addTarget(self, action: #selector(export(_:)), for: .touchUpInside)
            exportKeysButton.addTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            getWalletInfoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.addTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            refreshData.addTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        } else {
            
            utxosButton.removeTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            makeItCold.removeTarget(self, action: #selector(makeCold(_:)), for: .touchUpInside)
            showInvoice.removeTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            shareSeedButton.removeTarget(self, action: #selector(export(_:)), for: .touchUpInside)
            exportKeysButton.removeTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            getWalletInfoButton.removeTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.removeTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            refreshData.removeTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        }
        
        makeItCold.restorationIdentifier = "\(indexPath.section)"
        shareSeedButton.restorationIdentifier = "\(indexPath.section)"
        exportKeysButton.restorationIdentifier = "\(indexPath.section)"
        getWalletInfoButton.restorationIdentifier = "\(indexPath.section)"
        verifyAddresses.restorationIdentifier = "\(indexPath.section)"
        refreshData.restorationIdentifier = "\(indexPath.section)"
        
        nodeView.layer.cornerRadius = 8
        stackView.layer.cornerRadius = 8
        seedOnDeviceView.layer.cornerRadius = 8
        //seedOnNodeView.layer.cornerRadius = 8
        networkLabel.layer.cornerRadius = 8
        utxosButton.layer.cornerRadius = 8
        
        let derivation = wallet.derivation
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.text = "\(wallet.lastBalance.avoidNotation) BTC"
        
        if derivation.contains("1") {
            
            networkLabel.text = "Testnet"
            networkLabel.textColor = .systemOrange
            balanceLabel.textColor = .systemOrange
            
        } else {
            
            networkLabel.text = "Mainnet"
            networkLabel.textColor = .systemGreen
            balanceLabel.textColor = .systemGreen
            
        }
                    
        if derivation.contains("84") {
            
            derivationLabel.text = "BIP84"
            
            
        } else if derivation.contains("44") {
            
            derivationLabel.text = "BIP44"
            
        } else if derivation.contains("49") {
            
            derivationLabel.text = "BIP49"
            
        }
        
        deviceXprv.text = "xprv \(wallet.derivation)"
        updatedLabel.text = "\(formatDate(date: wallet.lastUsed))"
        createdLabel.text = "\(getDate(unixTime: wallet.birthdate))"
        walletFileLabel.text = wallet.name + ".dat"
        
        for n in nodes {
            
            let s = NodeStruct(dictionary: n)
            
            if s.id == wallet.nodeId {
                
                let rpcOnion = s.onionAddress
                let first10 = String(rpcOnion.prefix(5))
                let last15 = String(rpcOnion.suffix(15))
                rpcOnionLabel.text = "\(first10)*****\(last15)"
                nodeLabel.text = s.label
                //nodeSeedLabel.text = "1 Watch-only \(s.label)"
                
            }
            
        }
        
        return cell
        
    }
    
    private func multiSigWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let d = sortedWallets[indexPath.section]
        let wallet = WalletStruct.init(dictionary: d)
        
        let cell = walletTable.dequeueReusableCell(withIdentifier: "multiSigWalletCell", for: indexPath)
        cell.selectionStyle = .none
        
        let balanceLabel = cell.viewWithTag(1) as! UILabel
        let isActive = cell.viewWithTag(2) as! UISwitch
        let exportKeysButton = cell.viewWithTag(3) as! UIButton
        let verifyAddresses = cell.viewWithTag(4) as! UIButton
        let refreshData = cell.viewWithTag(5) as! UIButton
        let showInvoice = cell.viewWithTag(6) as! UIButton
        let makeItCold = cell.viewWithTag(7) as! UIButton
        let networkLabel = cell.viewWithTag(8) as! UILabel
        let utxosButton = cell.viewWithTag(9) as! UIButton
        let derivationLabel = cell.viewWithTag(11) as! UILabel
        let getWalletInfoButton = cell.viewWithTag(12) as! UIButton
        let updatedLabel = cell.viewWithTag(13) as! UILabel
        let createdLabel = cell.viewWithTag(14) as! UILabel
        let nodeSeedLabel = cell.viewWithTag(15) as! UILabel
        let shareSeedButton = cell.viewWithTag(16) as! UIButton
        let rpcOnionLabel = cell.viewWithTag(19) as! UILabel
        let walletFileLabel = cell.viewWithTag(20) as! UILabel
        let seedOnDeviceView = cell.viewWithTag(21)!
        let seedOnNodeView = cell.viewWithTag(22)!
        let seedOfflineView = cell.viewWithTag(23)!
        let isActiveLabel = cell.viewWithTag(24) as! UILabel
        let stackView = cell.viewWithTag(25)!
        let nodeView = cell.viewWithTag(26)!
        let nodeLabel = cell.viewWithTag(27) as! UILabel
        let deviceXprv = cell.viewWithTag(29) as! UILabel
        let nodeKeys = cell.viewWithTag(30) as! UILabel
        let offlineXprv = cell.viewWithTag(31) as! UILabel
        let bannerView = cell.viewWithTag(33)!
        
        isActive.addTarget(self, action: #selector(makeActive(_:)), for: .valueChanged)
        isActive.restorationIdentifier = "\(indexPath.section)"
        
        if wallet.isActive {
            
            isActive.isOn = true
            isActiveLabel.text = "Active"
            isActiveLabel.textColor = .lightGray
            cell.contentView.alpha = 1
            bannerView.backgroundColor = #colorLiteral(red: 0, green: 0.1631944358, blue: 0.3383367703, alpha: 1)
            
        } else if !wallet.isActive {
            
            isActive.isOn = false
            isActiveLabel.text = "Inactive"
            isActiveLabel.textColor = .darkGray
            cell.contentView.alpha = 0.6
            bannerView.backgroundColor = #colorLiteral(red: 0.1051254794, green: 0.1292803288, blue: 0.1418488324, alpha: 1)
            
        }
        
        if isActive.isOn {
            
            utxosButton.addTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            makeItCold.addTarget(self, action: #selector(makeCold(_:)), for: .touchUpInside)
            showInvoice.addTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            shareSeedButton.addTarget(self, action: #selector(export(_:)), for: .touchUpInside)
            exportKeysButton.addTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            getWalletInfoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.addTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            refreshData.addTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
            
        } else {
            
            utxosButton.removeTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            makeItCold.removeTarget(self, action: #selector(makeCold(_:)), for: .touchUpInside)
            showInvoice.removeTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            shareSeedButton.removeTarget(self, action: #selector(export(_:)), for: .touchUpInside)
            exportKeysButton.removeTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            getWalletInfoButton.removeTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.removeTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            refreshData.removeTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        }
        
        makeItCold.restorationIdentifier = "\(indexPath.section)"
        shareSeedButton.restorationIdentifier = "\(indexPath.section)"
        exportKeysButton.restorationIdentifier = "\(indexPath.section)"
        getWalletInfoButton.restorationIdentifier = "\(indexPath.section)"
        verifyAddresses.restorationIdentifier = "\(indexPath.section)"
        refreshData.restorationIdentifier = "\(indexPath.section)"
        
        nodeView.layer.cornerRadius = 8
        stackView.layer.cornerRadius = 8
        seedOnDeviceView.layer.cornerRadius = 8
        seedOnNodeView.layer.cornerRadius = 8
        seedOfflineView.layer.cornerRadius = 8
        networkLabel.layer.cornerRadius = 8
        utxosButton.layer.cornerRadius = 8
        
        let derivation = wallet.derivation
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.text = "\(wallet.lastBalance.avoidNotation) BTC"
        
        if derivation.contains("1") {
            
            networkLabel.text = "Testnet"
            networkLabel.textColor = .systemOrange
            balanceLabel.textColor = .systemOrange
            
        } else {
            
            networkLabel.text = "Mainnet"
            networkLabel.textColor = .systemGreen
            balanceLabel.textColor = .systemGreen
            
        }
        
        if derivation.contains("84") {
            
            derivationLabel.text = "BIP84"
            
        } else if derivation.contains("44") {
            
            derivationLabel.text = "BIP44"
            
        } else if derivation.contains("49") {
            
            derivationLabel.text = "BIP49"
            
        }
        
        deviceXprv.text = "xprv \(wallet.derivation)"
        nodeKeys.text = "keys \(wallet.derivation)/0 to /1999"
        offlineXprv.text = "xprv \(wallet.derivation)"
        
        updatedLabel.text = "\(formatDate(date: wallet.lastUsed))"
        createdLabel.text = "\(getDate(unixTime: wallet.birthdate))"
        walletFileLabel.text = wallet.name + ".dat"
        
        for n in nodes {
            
            let s = NodeStruct(dictionary: n)
            
            if s.id == wallet.nodeId {
                
                let rpcOnion = s.onionAddress
                let first10 = String(rpcOnion.prefix(5))
                let last15 = String(rpcOnion.suffix(15))
                rpcOnionLabel.text = "\(first10)*****\(last15)"
                nodeLabel.text = s.label
                nodeSeedLabel.text = "1 Seedless \(s.label)"
                
            }
            
        }
        
        return cell
        
    }
    
    private func customWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let d = sortedWallets[indexPath.section]
        let wallet = WalletStruct.init(dictionary: d)
        
        let cell = walletTable.dequeueReusableCell(withIdentifier: "coldWalletCell", for: indexPath)
        cell.selectionStyle = .none
        
        let parser = DescriptorParser()
        let descStr = parser.descriptor(wallet.descriptor)
        
        let balanceLabel = cell.viewWithTag(1) as! UILabel
        let isActive = cell.viewWithTag(2) as! UISwitch
        let exportKeysButton = cell.viewWithTag(3) as! UIButton
        let verifyAddresses = cell.viewWithTag(4) as! UIButton
        let refreshData = cell.viewWithTag(5) as! UIButton
        let showInvoice = cell.viewWithTag(6) as! UIButton
        let rescanButton = cell.viewWithTag(7) as! UIButton
        let networkLabel = cell.viewWithTag(8) as! UILabel
        let utxosButton = cell.viewWithTag(9) as! UIButton
        let derivationLabel = cell.viewWithTag(11) as! UILabel
        let getWalletInfoButton = cell.viewWithTag(12) as! UIButton
        let updatedLabel = cell.viewWithTag(13) as! UILabel
        let createdLabel = cell.viewWithTag(14) as! UILabel
        //let nodeSeedLabel = cell.viewWithTag(15) as! UILabel
        let exportSeedButton = cell.viewWithTag(17) as! UIButton
        let rpcOnionLabel = cell.viewWithTag(19) as! UILabel
        let walletFileLabel = cell.viewWithTag(20) as! UILabel
        //let seedOnNodeView = cell.viewWithTag(22)!
        let isActiveLabel = cell.viewWithTag(24) as! UILabel
        let stackView = cell.viewWithTag(25)!
        let nodeView = cell.viewWithTag(26)!
        let nodeLabel = cell.viewWithTag(27) as! UILabel
        let keysOnNodeLabel = cell.viewWithTag(28) as! UILabel
        let typeLabel = cell.viewWithTag(29) as! UILabel
        let bannerView = cell.viewWithTag(32)!
        
        if wallet.isActive {
            
            isActive.isOn = true
            isActiveLabel.text = "Active"
            isActiveLabel.textColor = .lightGray
            cell.contentView.alpha = 1
            bannerView.backgroundColor = #colorLiteral(red: 0, green: 0.1631944358, blue: 0.3383367703, alpha: 1)
            
        } else if !wallet.isActive {
            
            isActive.isOn = false
            isActiveLabel.text = "Inactive"
            isActiveLabel.textColor = .darkGray
            cell.contentView.alpha = 0.6
            bannerView.backgroundColor = #colorLiteral(red: 0.1051254794, green: 0.1292803288, blue: 0.1418488324, alpha: 1)
            
        }
        
        isActive.addTarget(self, action: #selector(makeActive(_:)), for: .valueChanged)
        isActive.restorationIdentifier = "\(indexPath.section)"
        
        if isActive.isOn {
            
            utxosButton.addTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            exportSeedButton.addTarget(self, action: #selector(export(_:)), for: .touchUpInside)
            rescanButton.addTarget(self, action: #selector(rescan(_:)), for: .touchUpInside)
            showInvoice.addTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            exportKeysButton.addTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            getWalletInfoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.addTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            refreshData.addTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        } else {
            
            utxosButton.removeTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            exportSeedButton.removeTarget(self, action: #selector(export(_:)), for: .touchUpInside)
            rescanButton.removeTarget(self, action: #selector(rescan(_:)), for: .touchUpInside)
            showInvoice.removeTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            exportKeysButton.removeTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            getWalletInfoButton.removeTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.removeTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            refreshData.removeTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        }
        
        rescanButton.restorationIdentifier = "\(indexPath.section)"
        exportSeedButton.restorationIdentifier = "\(indexPath.section)"
        exportKeysButton.restorationIdentifier = "\(indexPath.section)"
        getWalletInfoButton.restorationIdentifier = "\(indexPath.section)"
        verifyAddresses.restorationIdentifier = "\(indexPath.section)"
        refreshData.restorationIdentifier = "\(indexPath.section)"
        
        nodeView.layer.cornerRadius = 8
        stackView.layer.cornerRadius = 8
        //seedOnNodeView.layer.cornerRadius = 8
        networkLabel.layer.cornerRadius = 8
        utxosButton.layer.cornerRadius = 8
        
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.text = "\(wallet.lastBalance.avoidNotation) BTC"
        
        if descStr.chain == "Testnet" {
            
            networkLabel.text = "Testnet"
            networkLabel.textColor = .systemOrange
            balanceLabel.textColor = .systemOrange
            
        } else if descStr.chain == "Mainnet" {
            
            networkLabel.text = "Mainnet"
            networkLabel.textColor = .systemGreen
            balanceLabel.textColor = .systemGreen
            
        }
        
        derivationLabel.text = descStr.format
        
        if descStr.isMulti {
            
            typeLabel.text = descStr.mOfNType
            
        } else {
            
            typeLabel.text = "Single-Sig"
            
        }
        
        updatedLabel.text = "\(formatDate(date: wallet.lastUsed))"
        createdLabel.text = "\(getDate(unixTime: wallet.birthdate))"
        walletFileLabel.text = wallet.name + ".dat"
        
        for n in nodes {
            
            let s = NodeStruct(dictionary: n)
            
            if s.id == wallet.nodeId {
                
                let rpcOnion = s.onionAddress
                let first10 = String(rpcOnion.prefix(5))
                let last15 = String(rpcOnion.suffix(15))
                rpcOnionLabel.text = "\(first10)*****\(last15)"
                nodeLabel.text = s.label
                
                if descStr.isHot {
                    
                    //nodeSeedLabel.text = "\(s.label) is Hot"
                    keysOnNodeLabel.text = "2,000 private keys on \(s.label)"
//                    cell.backgroundColor = #colorLiteral(red: 0.3412515863, green: 0.07937019594, blue: 0.06658586931, alpha: 1)
//                    seedOnNodeView.backgroundColor = #colorLiteral(red: 0.3983185279, green: 0.09264314329, blue: 0.07772091475, alpha: 1)
//                    nodeView.backgroundColor = #colorLiteral(red: 0.3983185279, green: 0.09264314329, blue: 0.07772091475, alpha: 1)
//                    stackView.backgroundColor = #colorLiteral(red: 0.3983185279, green: 0.09264314329, blue: 0.07772091475, alpha: 1)
//                    balanceLabel.textColor = .lightGray
                    
                } else {
                    
                    //nodeSeedLabel.text = "\(s.label) is Cold"
                    keysOnNodeLabel.text = "2,000 public keys on \(s.label)"
//                    cell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
//                    seedOnNodeView.backgroundColor = #colorLiteral(red: 0, green: 0.1579723669, blue: 0.3275103109, alpha: 1)
//                    nodeView.backgroundColor = #colorLiteral(red: 0, green: 0.1579723669, blue: 0.3275103109, alpha: 1)
//                    stackView.backgroundColor = #colorLiteral(red: 0, green: 0.1579723669, blue: 0.3275103109, alpha: 1)
                    
                }
                
            }
            
        }
        
        return cell
        
    }
    
    private func noWalletCell() -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.backgroundColor = .black
        cell.textLabel?.text = "⚠︎ No wallets created yet, tap the +"
        cell.textLabel?.textColor = .lightGray
        cell.textLabel?.font = .systemFont(ofSize: 17)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if sortedWallets.count > 0 {
            
            let d = sortedWallets[indexPath.section]
            let wallet = WalletStruct.init(dictionary: d)
                
            switch wallet.type {
                
            case "DEFAULT":
                
                return singleSigCell(indexPath)
                
            case "MULTI":
                
                return multiSigWalletCell(indexPath)
                
            case "CUSTOM":
                
                return customWalletCell(indexPath)
                
            default:
                
                return UITableViewCell()
                
            }
            
        } else {
            
            return noWalletCell()
            
        }
        
    }
    
    @objc func goUtxos(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "seeUtxos", sender: self)
            
        }
    }
    
    @objc func makeCold(_ sender: UIButton) {
        
        let index = Int(sender.restorationIdentifier!)!
        let wallet = WalletStruct(dictionary: self.sortedWallets[index])
        
        impact()
        
        DispatchQueue.main.async {
                        
            let alert = UIAlertController(title: "⚠︎ WARNING!", message: "This button WILL DELETE the devices seed FOREVER, and make this wallet a watch-only wallet, there is no going back after this! Make sure you have securely recorded your words, descriptors and recovery command before deleting the seed otherwise you will NOT be able to spend from this wallet.", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "⚠︎ DELETE SEED", style: .destructive, handler: { action in
                
                let cd = CoreDataService()
                cd.updateEntity(id: wallet.id, keyToUpdate: "seed", newValue: "no seed".dataUsingUTF8StringEncoding, entityName: .wallets) {
                    
                    if !cd.errorBool {
                        
                        cd.updateEntity(id: wallet.id, keyToUpdate: "type", newValue: "CUSTOM", entityName: .wallets) {}
                        
                        showAlert(vc: self, title: "Seed deleted", message: "")
                        
                        DispatchQueue.main.async {
                            
                            self.walletTable.reloadSections(IndexSet(arrayLiteral: index), with: .fade)
                            
                        }
                        
                    } else {
                        
                        showAlert(vc: self, title: "Error", message: "\(cd.errorDescription)")
                        
                    }
                    
                }

            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    private func impact() {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
        }
        
    }
    
    @objc func invoice(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "invoice", sender: self)
            
        }
        
    }
    
    @objc func refreshData(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
            
            sender.tintColor = .clear
            sender.loadingIndicator(show: true)
            
        }
        
        let index = Int(sender.restorationIdentifier!)!
        let wallet = WalletStruct(dictionary: self.sortedWallets[index])
        
        let nodeLogic = NodeLogic()
        nodeLogic.wallet = wallet
        nodeLogic.loadWalletData {
            
            if !nodeLogic.errorBool {
                
                let dict = nodeLogic.dictToReturn
                let s = HomeStruct(dictionary: dict)
                
                let cd = CoreDataService()
                cd.updateEntity(id: wallet.id, keyToUpdate: "lastBalance", newValue: Double(s.coldBalance)!, entityName: .wallets) {
                    
                    self.sortedWallets[index]["lastBalance"] = Double(s.coldBalance)!
                    self.sortedWallets[index]["lastUsed"]  = Date()
                    
                    DispatchQueue.main.async {
                        
                        sender.loadingIndicator(show: false)
                        sender.tintColor = .systemBlue
                        self.walletTable.reloadSections(IndexSet(arrayLiteral: index), with: .fade)
                        
                    }
                    
                    cd.updateEntity(id: wallet.id, keyToUpdate: "lastUsed", newValue: Date(), entityName: .wallets) {}
                    
                }
                
            }
            
        }
        
    }
    
    @objc func verifyAddresses(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "verifyAddresses", sender: self)
            
        }
        
    }
    
    @objc func exportKeys(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "exportKeys", sender: self)
            
        }
        
    }
    
    @objc func export(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "exportSeed", sender: self)
            
        }
        
    }
    
    @objc func getWalletInfo(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
            
            DispatchQueue.main.async {
                
                self.performSegue(withIdentifier: "getWalletInfo", sender: self)
                
            }
            
        }
        
    }
    
    @objc func rescan(_ sender: UIButton) {
        
        let index = Int(sender.restorationIdentifier!)!
        let walletName = WalletStruct(dictionary: self.sortedWallets[index]).name
        impact()
        
        DispatchQueue.main.async {
                        
            let alert = UIAlertController(title: "Rescan the blockchain?", message: "This button will start a blockchain rescan for your current wallet. This is useful if you imported the wallet and do not see balances yet. If you want to check the status of your rescan this button will also let you know the % completion.", preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Rescan", style: .default, handler: { action in
                
                self.creatingView.addConnectingView(vc: self, description: "initiating rescan")
                            
                let reducer = Reducer()
                reducer.makeCommand(walletName: walletName, command: .rescanblockchain, param: "") {
                    
                    DispatchQueue.main.async {
                        
                        self.creatingView.label.text = "confirming rescan status"
                        
                    }
                    
                    reducer.errorBool = false
                    reducer.errorDescription = ""
                    
                    reducer.makeCommand(walletName: walletName, command: .getwalletinfo, param: "") {
                        
                        if !reducer.errorBool || reducer.errorDescription.description.contains("abort") {
                            
                            let result = reducer.dictToReturn
                            if let scanning = result["scanning"] as? NSDictionary {
                                
                                if let _ = scanning["duration"] as? Int {
                                    
                                    self.creatingView.removeConnectingView()
                                    let progress = (scanning["progress"] as! Double)
                                    showAlert(vc: self, title: "Rescanning", message: "Wallet is rescanning with current progress: \((progress * 100).rounded())%")
                                    
                                }
                                
                            } else if (result["scanning"] as? Int) == 0 {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: "wallet not rescanning")
                                
                            } else {
                                
                                self.creatingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: "unable to determine if wallet is rescanning")
                                
                            }
                            
                        } else {
                            
                            self.creatingView.removeConnectingView()
                            displayAlert(viewController: self, isError: true, message: reducer.errorDescription)
                            
                        }
                        
                    }
                    
                }

            }))
            
            alert.addAction(UIAlertAction(title: "Check Scan Status", style: .default, handler: { action in
                
                self.creatingView.addConnectingView(vc: self, description: "checking scan status")
                
                let reducer = Reducer()
                reducer.makeCommand(walletName: walletName, command: .getwalletinfo, param: "") {
                    
                    if !reducer.errorBool || reducer.errorDescription.description.contains("abort") {
                        
                        let result = reducer.dictToReturn
                        if let scanning = result["scanning"] as? NSDictionary {
                            
                            if let _ = scanning["duration"] as? Int {
                                
                                self.creatingView.removeConnectingView()
                                let progress = (scanning["progress"] as! Double)
                                showAlert(vc: self, title: "Rescanning", message: "Wallet is rescanning with current progress: \((progress * 100).rounded())%")
                                
                            }
                            
                        } else if (result["scanning"] as? Int) == 0 {
                            
                            self.creatingView.removeConnectingView()
                            displayAlert(viewController: self, isError: true, message: "wallet not rescanning")
                            
                        } else {
                            
                            self.creatingView.removeConnectingView()
                            displayAlert(viewController: self, isError: true, message: "unable to determine if wallet is rescanning")
                            
                        }
                        
                    } else {
                        
                        self.creatingView.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: reducer.errorDescription)
                        
                    }
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    @objc func makeActive(_ sender: UIButton) {
        
        let index = Int(sender.restorationIdentifier!)!
        let wallet = WalletStruct(dictionary: self.sortedWallets[index])
        
        if !wallet.isActive {
            
            activateNow(wallet: wallet, index: index)
            
        } else {
            
            deactivateNow(wallet: wallet, index: index)
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if sortedWallets.count > 0 {
            
            let type = WalletStruct(dictionary: sortedWallets[indexPath.section]).type
            
            switch  type {
                
            case "DEFAULT":
                
                return 377
                
            case "MULTI":
                
                return 435
                
            case "CUSTOM":
                
                return 294
                
            default:
                
                return 0
                
            }
            
        } else {
            
            return 80
            
        }
                
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return ""
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let dict = sortedWallets[indexPath.section]
        let wallet = WalletStruct.init(dictionary: dict)
        
        if !wallet.isActive {
            
            activateNow(wallet: wallet, index: indexPath.section)
            
        }
        
    }
    
    func activateNow(wallet: WalletStruct, index: Int) {
        
        if !wallet.isActive {
                        
            impact()
            
            let cd = CoreDataService()
            let enc = Encryption()
            
            enc.getNode { (n, error) in
                
                if n != nil {
                    
                    if wallet.nodeId != n!.id {
                        
                        cd.updateEntity(id: wallet.nodeId, keyToUpdate: "isActive", newValue: true, entityName: .nodes) {}
                        cd.updateEntity(id: n!.id, keyToUpdate: "isActive", newValue: false, entityName: .nodes) {}
                        
                    }
                    
                }
                
            }
            
            // update the views
            for (i, _) in sortedWallets.enumerated() {
                
                if index == i {
                    
                    // wallet to activate
                    self.sortedWallets[i]["lastUsed"]  = Date()
                    self.sortedWallets[i]["isActive"] = true
                    
                } else {
                    
                    self.sortedWallets[i]["isActive"] = false
                    
                }
                
                if i + 1 == sortedWallets.count {
                    
                    DispatchQueue.main.async {
                        
                        self.walletTable.reloadSections(IndexSet(arrayLiteral: index), with: .fade)
                                            
                    }
                    
                    // update the actual data
                    cd.updateEntity(id: wallet.id, keyToUpdate: "lastUsed", newValue: Date(), entityName: .wallets) {
                        
                        self.activate(walletToActivate: wallet.id, index: index)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func deactivateNow(wallet: WalletStruct, index: Int) {
        
        if wallet.isActive {
            
            impact()
            
            // update the views
            for (i, _) in sortedWallets.enumerated() {
                
                if index == i {
                    
                    // wallet to deactivate
                    self.sortedWallets[i]["isActive"] = false
                    
                    DispatchQueue.main.async {
                        
                        self.walletTable.reloadSections(IndexSet(arrayLiteral: i), with: .fade)
                                            
                    }
                    
                    let cd = CoreDataService()
                    cd.updateEntity(id: wallet.id, keyToUpdate: "isActive", newValue: false, entityName: .wallets) {}
                    
                }
                
            }
            
        }
        
    }
    
    func getDate(unixTime: Int32) -> String {
        
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm" //Specify your format that you want
        let strDate = dateFormatter.string(from: date)
        return strDate
        
    }
    
    func formatDate(date: Date) -> String {
        
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm" //Specify your format that you want
        let strDate = dateFormatter.string(from: date)
        return strDate
        
    }
    
    func activate(walletToActivate: UUID, index: Int) {
        
        cd.updateEntity(id: walletToActivate, keyToUpdate: "isActive", newValue: true, entityName: .wallets) {
            
            if !self.cd.errorBool {
                                        
                self.deactivate(walletToActivate: walletToActivate, index: index)
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "error deactivating wallet")
                
            }
            
        }
        
    }
    
    func deactivate(walletToActivate: UUID, index: Int) {
        
        for (i, wallet) in sortedWallets.enumerated() {
            
            let str = WalletStruct.init(dictionary: wallet)
            
            if str.id != walletToActivate {
                
                cd.updateEntity(id: str.id, keyToUpdate: "isActive", newValue: false, entityName: .wallets) {
                    
                    if !self.cd.errorBool {
                        
                        self.sortedWallets[i]["isActive"] = false
                        
                        if i != index {
                            
                            DispatchQueue.main.async {
                                
                                self.walletTable.reloadSections(IndexSet(arrayLiteral: i), with: .none)
                                
                            }
                            
                        }
                        
                    } else {
                        
                        displayAlert(viewController: self, isError: true, message: "error deactivating wallet")
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    @objc func createWallet() {
        
        impact()
        
        let enc = Encryption()
        enc.getNode { (node, error) in
            
            if !error && node != nil {
                
                if node!.network != "mainnet" {
                    
                    DispatchQueue.main.async {
                        
                        self.performSegue(withIdentifier: "addWallet", sender: self)
                        
                    }
                    
                } else {
                    
                    displayAlert(viewController: self, isError: true, message: "Mainnet wallets not yet allowed! Sorry.")
                    
                }
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "No active nodes")
                
            }
            
        }
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        switch id {
            
        case "walletInfo":
            
            if let vc = segue.destination as? WalletInfoViewController {
                
                vc.walletname = name
                
            }
            
        case "verifyAddresses":
            
            if let vc = segue.destination as? VerifyKeysViewController {
                
                vc.comingFromSettings = true
                
            }
            
        case "invoice":
            
            if let vc = segue.destination as? InvoiceViewController {
                
                vc.presentingModally = true
            }
            
        case "addWallet":
            
            if let vc = segue.destination as? ChooseWalletFormatViewController {
                
                vc.singleSigDoneBlock = { result in
                    
                    DispatchQueue.main.async {
                        
                        showAlert(vc: self, title: "Success!", message: "Single signature wallet created successfully!")
                        self.refresh()
                        
                    }
                    
                }
                
                vc.multiSigDoneBlock = { (arg0) in
                    
                    let (_, recoverphrase, desc) = arg0
                    
                    DispatchQueue.main.async {
                        
                        DispatchQueue.main.async {
                            
                            self.recoveryPhrase = recoverphrase
                            self.descriptor = desc
                            self.performSegue(withIdentifier: "showRecoveryKit", sender: self)
                            
                        }
                        
                    }
                    
                }
                
                vc.importDoneBlock = { result in
                    
                    DispatchQueue.main.async {
                        
                        self.performSegue(withIdentifier: "importCustom", sender: self)
                        
                    }
                    
                }
                
            }
            
        case "showRecoveryKit":
            
            if let vc = segue.destination as? RecoveryViewController {
                
                vc.recoveryPhrase = self.recoveryPhrase
                vc.descriptor = self.descriptor
                
                vc.onDoneBlock2 = { result in
                    
                    self.refresh()
                    
                }
                
            }
            
        case "importCustom":
            
            if let vc = segue.destination as? ImportViewController {
                
                vc.importComplete = { result in
                    
                    showAlert(vc: self, title: "Success!", message: "Wallet imported! Tap it to active it.")
                    self.refresh()
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }
    
}
