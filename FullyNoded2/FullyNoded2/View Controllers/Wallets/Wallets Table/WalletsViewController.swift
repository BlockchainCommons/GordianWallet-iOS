//
//  WalletsViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 10/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    @IBOutlet var loadingRefresher: UIActivityIndicatorView!
    var isLoading = Bool()
    var refresher: UIRefreshControl!
    var index = Int()
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
        editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editWallets))
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createWallet))
        navigationItem.setRightBarButton(addButton, animated: true)
        navigationItem.setLeftBarButton(editButton, animated: true)
        configureRefresher()
        loadingRefresher.alpha = 0
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        isLoading = true
        refresh()
        
        DispatchQueue.main.async {
            
            self.walletTable.setContentOffset(.zero, animated: true)
            
        }
        
    }
    
    private func configureRefresher() {
        
        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.white
        refresher.attributedTitle = NSAttributedString(string: "refresh data", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        refresher.addTarget(self, action: #selector(self.pullToRefresh), for: UIControl.Event.valueChanged)
        walletTable.addSubview(refresher)
        
    }
    
    @objc func editWallets() {
        
        if !isLoading {
            
            walletTable.setEditing(!walletTable.isEditing, animated: true)
            
            if walletTable.isEditing {
                
                editButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(editWallets))
                
            } else {
                
                editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editWallets))
                
            }
            
            self.navigationItem.setLeftBarButton(editButton, animated: true)
            
        } else {
            
            showAlert(vc: self, title: "Fetching wallet data from your node...", message: "Please wait until the spinner disappears as the app is currently fetching wallet data from your node.")
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        if tableView.isEditing {
            
            return .delete
            
        }

        return .none
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            if !isLoading {
                
                if sortedWallets.count > 0 {
                 
                    let id = sortedWallets[indexPath.section]["id"] as! UUID
                    cd.updateEntity(id: id, keyToUpdate: "isArchived", newValue: true, entityName: .wallets) {
                        
                        if !self.cd.errorBool {
                            
                            if self.sortedWallets.count == 1 {
                                
                                DispatchQueue.main.async {
                                    
                                    self.sortedWallets.removeAll()
                                    self.editWallets()
                                    self.walletTable.reloadData()
                                    
                                }
                                
                            } else {
                                
                                DispatchQueue.main.async {
                                    
                                    self.sortedWallets.remove(at: indexPath.section)
                                    tableView.deleteSections(IndexSet(arrayLiteral: indexPath.section), with: .fade)
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            displayAlert(viewController: self, isError: true, message: "error deleting node")
                            
                        }
                        
                    }
                    
                } else {
                    
                    self.editWallets()
                    displayAlert(viewController: self, isError: true, message: "not allowed")
                    
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
    
    @objc func pullToRefresh() {
        
        if !isLoading {
            
            self.isLoading = true
            self.refresher.beginRefreshing()
            refresh()
            
        } else {
            
            showAlert(vc: self, title: "Please be patient", message: "We are already refreshing your wallets data, wait for the spinner to dissapear then try again.")
            
        }
        
    }
    
    func refresh() {
        print("refresh")
        
        sortedWallets.removeAll()
        
        func loadWallets() {
                        
            self.cd.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                
                if errorDescription == nil {
                    
                    if wallets!.count == 0 {
                        
                        self.isLoading = false
                        self.createWallet()
                        
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            self.loadingRefresher.startAnimating()
                            self.loadingRefresher.alpha = 1
                            
                        }
                        
                        for (i, w) in wallets!.enumerated() {
                            
                            let s = WalletStruct(dictionary: w)
                            
                            if !s.isArchived {
                                
                                self.sortedWallets.append(w)
                                
                            }
                            
                            if i + 1 == wallets!.count {
                                
                                self.sortedWallets = self.sortedWallets.sorted{ ($0["lastUsed"] as? Date ?? Date()) > ($1["lastUsed"] as? Date ?? Date()) }
                                
                                if self.sortedWallets.count == 0 {
                                    
                                    self.isLoading = false
                                    self.createWallet()
                                    
                                } else {
                                    
                                    if self.nodes.count == 0 {
                                        
                                        self.isLoading = false
                                        self.walletTable.isUserInteractionEnabled = false
                                        
                                        for (i, wallet) in self.sortedWallets.enumerated() {
                                            
                                            let w = WalletStruct(dictionary: wallet)
                                            self.cd.updateEntity(id: w.id, keyToUpdate: "isActive", newValue: false, entityName: .wallets) {}
                                            
                                            if i + 1 == self.sortedWallets.count {
                                                
                                                DispatchQueue.main.async {
                                                    
                                                    self.walletTable.reloadData()
                                                    self.refresher.endRefreshing()
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        DispatchQueue.main.async {
                                            
                                            self.walletTable.reloadData()
                                            self.index = 0
                                            self.getBalances()
                                            
                                        }
                                        
                                    }
                                                                        
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    displayAlert(viewController: self, isError: true, message: errorDescription!)
                    
                }
                
            }
            
        }
        
        let enc = Encryption()
        cd.retrieveEntity(entityName: .nodes) { (nodes, errorDescription) in
            
            if errorDescription == nil && nodes != nil {
                
                if nodes!.count > 0 {
                    
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
                                
                                loadWallets()
                                
                            }
                            
                        }
                                            
                    }
                    
                } else {
                    
                    loadWallets()
                    
                    displayAlert(viewController: self, isError: true, message: "no nodes! Something is very wrong, you will not be able to use these wallets without a node")
                    
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
        //let refreshData = cell.viewWithTag(5) as! UIButton
        //let showInvoice = cell.viewWithTag(6) as! UIButton
        //let makeItCold = cell.viewWithTag(7) as! UIButton
        let networkLabel = cell.viewWithTag(8) as! UILabel
        let utxosButton = cell.viewWithTag(9) as! UIButton
        let derivationLabel = cell.viewWithTag(11) as! UILabel
        //let getWalletInfoButton = cell.viewWithTag(12) as! UIButton
        let updatedLabel = cell.viewWithTag(13) as! UILabel
        let createdLabel = cell.viewWithTag(14) as! UILabel
        let shareSeedButton = cell.viewWithTag(16) as! UIButton
        let rpcOnionLabel = cell.viewWithTag(19) as! UILabel
        let walletFileLabel = cell.viewWithTag(20) as! UILabel
        let seedOnDeviceView = cell.viewWithTag(21)!
        let isActiveLabel = cell.viewWithTag(24) as! UILabel
        let stackView = cell.viewWithTag(25)!
        let nodeView = cell.viewWithTag(26)!
        let nodeLabel = cell.viewWithTag(27) as! UILabel
        let deviceXprv = cell.viewWithTag(28) as! UILabel
        let bannerView = cell.viewWithTag(32)!
        let nodeKeysLabel = cell.viewWithTag(33) as! UILabel
        let rescanLabel = cell.viewWithTag(34) as! UILabel
        
        rescanLabel.alpha = 0
        rescanLabel.adjustsFontSizeToFitWidth = true
        
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
        
        if let isRescanning = sortedWallets[indexPath.section]["isRescanning"] as? Bool {
            
            if isRescanning {
                
                print("wallet is rescanning")
                
                if let progress = sortedWallets[indexPath.section]["progress"] as? String {
                    
                    rescanLabel.text = "Rescanning" + " " + progress + "%"
                    
                } else {
                    
                    rescanLabel.text = "Rescanning"
                    
                }
                
                rescanLabel.alpha = 1
                
            } else {
                
                print("wallet not rescanning")
                rescanLabel.alpha = 0
                
            }
            
        }
        
        isActive.addTarget(self, action: #selector(makeActive(_:)), for: .valueChanged)
        isActive.restorationIdentifier = "\(indexPath.section)"
        
        if isActive.isOn {
            
            utxosButton.addTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            //makeItCold.addTarget(self, action: #selector(makeCold(_:)), for: .touchUpInside)
            //showInvoice.addTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            shareSeedButton.addTarget(self, action: #selector(exportSeed(_:)), for: .touchUpInside)
            exportKeysButton.addTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            //getWalletInfoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.addTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            //refreshData.addTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        } else {
            
            utxosButton.removeTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            //makeItCold.removeTarget(self, action: #selector(makeCold(_:)), for: .touchUpInside)
            //showInvoice.removeTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            shareSeedButton.removeTarget(self, action: #selector(exportSeed(_:)), for: .touchUpInside)
            exportKeysButton.removeTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            //getWalletInfoButton.removeTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.removeTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            //refreshData.removeTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        }
        
        //makeItCold.restorationIdentifier = "\(indexPath.section)"
        shareSeedButton.restorationIdentifier = "\(indexPath.section)"
        exportKeysButton.restorationIdentifier = "\(indexPath.section)"
        //getWalletInfoButton.restorationIdentifier = "\(indexPath.section)"
        verifyAddresses.restorationIdentifier = "\(indexPath.section)"
        //refreshData.restorationIdentifier = "\(indexPath.section)"
        
        rescanLabel.layer.cornerRadius = 8
        nodeView.layer.cornerRadius = 8
        stackView.layer.cornerRadius = 8
        seedOnDeviceView.layer.cornerRadius = 8
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
        
        nodeKeysLabel.text = "holds public keys \(wallet.derivation)/0 to /999"
        deviceXprv.text = "xprv \(wallet.derivation)"
        updatedLabel.text = "\(formatDate(date: wallet.lastUpdated))"
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
        //let refreshData = cell.viewWithTag(5) as! UIButton
        //let showInvoice = cell.viewWithTag(6) as! UIButton
        //let makeItCold = cell.viewWithTag(7) as! UIButton
        let networkLabel = cell.viewWithTag(8) as! UILabel
        let utxosButton = cell.viewWithTag(9) as! UIButton
        let derivationLabel = cell.viewWithTag(11) as! UILabel
        //let getWalletInfoButton = cell.viewWithTag(12) as! UIButton
        let updatedLabel = cell.viewWithTag(13) as! UILabel
        let createdLabel = cell.viewWithTag(14) as! UILabel
        let nodeSeedLabel = cell.viewWithTag(15) as! UILabel
        let shareSeedButton = cell.viewWithTag(16) as! UIButton
        //let getNodeSeedInfoButton = cell.viewWithTag(17) as! UIButton
        //let getOfflineSeedInfoButton = cell.viewWithTag(18) as! UIButton
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
        let rescanLabel = cell.viewWithTag(34) as! UILabel
        
        rescanLabel.alpha = 0
        rescanLabel.adjustsFontSizeToFitWidth = true
        
        isActive.addTarget(self, action: #selector(makeActive(_:)), for: .valueChanged)
        isActive.restorationIdentifier = "\(indexPath.section)"
        
        if let isRescanning = sortedWallets[indexPath.section]["isRescanning"] as? Bool {
            
            if isRescanning {
                
                print("wallet is rescanning")
                
                if let progress = sortedWallets[indexPath.section]["progress"] as? String {
                    
                    rescanLabel.text = "Rescanning" + " " + progress + "%"
                    
                } else {
                    
                    rescanLabel.text = "Rescanning"
                    
                }
                
                rescanLabel.alpha = 1
                
            } else {
                
                print("wallet not rescanning")
                rescanLabel.alpha = 0
                
            }
            
        }
        
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
            //makeItCold.addTarget(self, action: #selector(makeCold(_:)), for: .touchUpInside)
            //showInvoice.addTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            shareSeedButton.addTarget(self, action: #selector(exportSeed(_:)), for: .touchUpInside)
            exportKeysButton.addTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            //getWalletInfoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.addTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            //refreshData.addTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            //getNodeSeedInfoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            //getOfflineSeedInfoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            
        } else {
            
            utxosButton.removeTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            //makeItCold.removeTarget(self, action: #selector(makeCold(_:)), for: .touchUpInside)
            //showInvoice.removeTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            shareSeedButton.removeTarget(self, action: #selector(exportSeed(_:)), for: .touchUpInside)
            exportKeysButton.removeTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            //getWalletInfoButton.removeTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.removeTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            //refreshData.removeTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            //getNodeSeedInfoButton.removeTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            //getOfflineSeedInfoButton.removeTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            
        }
        
        //makeItCold.restorationIdentifier = "\(indexPath.section)"
        shareSeedButton.restorationIdentifier = "\(indexPath.section)"
        exportKeysButton.restorationIdentifier = "\(indexPath.section)"
        //getWalletInfoButton.restorationIdentifier = "\(indexPath.section)"
        verifyAddresses.restorationIdentifier = "\(indexPath.section)"
        //refreshData.restorationIdentifier = "\(indexPath.section)"
        
        rescanLabel.layer.cornerRadius = 8
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
        nodeKeys.text = "keys \(wallet.derivation)/0 and 1/0 to /999"
        offlineXprv.text = "xprv \(wallet.derivation)"
        updatedLabel.text = "\(formatDate(date: wallet.lastUpdated))"
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
        //let refreshData = cell.viewWithTag(5) as! UIButton
        //let showInvoice = cell.viewWithTag(6) as! UIButton
        //let rescanButton = cell.viewWithTag(7) as! UIButton
        let networkLabel = cell.viewWithTag(8) as! UILabel
        let utxosButton = cell.viewWithTag(9) as! UIButton
        let derivationLabel = cell.viewWithTag(11) as! UILabel
        //let getWalletInfoButton = cell.viewWithTag(12) as! UIButton
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
        let rescanLabel = cell.viewWithTag(34) as! UILabel
        
        rescanLabel.alpha = 0
        rescanLabel.adjustsFontSizeToFitWidth = true
        
        if let isRescanning = sortedWallets[indexPath.section]["isRescanning"] as? Bool {
            
            if isRescanning {
                
                print("wallet is rescanning")
                
                if let progress = sortedWallets[indexPath.section]["progress"] as? String {
                    
                    rescanLabel.text = "Rescanning" + " " + progress + "%"
                    
                } else {
                    
                    rescanLabel.text = "Rescanning"
                    
                }
                
                rescanLabel.alpha = 1
                
            } else {
                
                print("wallet not rescanning")
                rescanLabel.alpha = 0
                
            }
            
        }
        
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
            exportSeedButton.addTarget(self, action: #selector(exportSeed(_:)), for: .touchUpInside)
            //rescanButton.addTarget(self, action: #selector(rescan(_:)), for: .touchUpInside)
            //showInvoice.addTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            exportKeysButton.addTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            //getWalletInfoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.addTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            //refreshData.addTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        } else {
            
            utxosButton.removeTarget(self, action: #selector(goUtxos(_:)), for: .touchUpInside)
            exportSeedButton.removeTarget(self, action: #selector(exportSeed(_:)), for: .touchUpInside)
            //rescanButton.removeTarget(self, action: #selector(rescan(_:)), for: .touchUpInside)
            //showInvoice.removeTarget(self, action: #selector(invoice(_:)), for: .touchUpInside)
            exportKeysButton.removeTarget(self, action: #selector(exportKeys(_:)), for: .touchUpInside)
            //getWalletInfoButton.removeTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
            verifyAddresses.removeTarget(self, action: #selector(verifyAddresses(_:)), for: .touchUpInside)
            //refreshData.removeTarget(self, action: #selector(refreshData(_:)), for: .touchUpInside)
            
        }
        
        //rescanButton.restorationIdentifier = "\(indexPath.section)"
        exportSeedButton.restorationIdentifier = "\(indexPath.section)"
        exportKeysButton.restorationIdentifier = "\(indexPath.section)"
        //getWalletInfoButton.restorationIdentifier = "\(indexPath.section)"
        verifyAddresses.restorationIdentifier = "\(indexPath.section)"
        //refreshData.restorationIdentifier = "\(indexPath.section)"
        
        nodeView.layer.cornerRadius = 8
        stackView.layer.cornerRadius = 8
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
        
        updatedLabel.text = "\(formatDate(date: wallet.lastUpdated))"
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
                    
                    keysOnNodeLabel.text = "1,000 private keys on \(s.label)"
                    
                } else {
                    
                    keysOnNodeLabel.text = "1,000 public keys on \(s.label)"
                    
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
    
    @objc func getInfo(_ sender: UIButton) {
        
        displayAlert(viewController: self, isError: false, message: "Under Construction")
        
    }
    
    @objc func goUtxos(_ sender: UIButton) {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "seeUtxos", sender: self)
            
        }
        
    }
    
    private func impact() {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
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
    
    @objc func exportSeed(_ sender: UIButton) {
        
        impact()
        
        let isCaptured = UIScreen.main.isCaptured
        
        if !isCaptured {
            
            DispatchQueue.main.async {
                
                self.performSegue(withIdentifier: "exportSeed", sender: self)
                
            }
            
        } else {
            
            showAlert(vc: self, title: "Security Alert!", message: "Your device is taking a screen recording, please stop the recording and try again.")
            
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 30
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if sortedWallets.count > 0 {
            
            let wallet = WalletStruct(dictionary: sortedWallets[section])
            
            let header = UIView()
            header.backgroundColor = UIColor.clear
            header.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30)
            
            let textLabel = UILabel()
            textLabel.textAlignment = .left
            textLabel.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
            textLabel.text = wallet.label
            textLabel.frame = CGRect(x: 0, y: 0, width: self.walletTable.frame.width / 2.2, height: 30)
            textLabel.adjustsFontSizeToFitWidth = true
            
            let refreshButton = UIButton()
            let image = UIImage(systemName: "arrow.clockwise")
            refreshButton.setImage(image, for: .normal)
            refreshButton.tag = section
            refreshButton.addTarget(self, action: #selector(reloadSection(_:)), for: .touchUpInside)
            refreshButton.frame = CGRect(x: header.frame.maxX - 70, y: 0, width: 20, height: 20)
            refreshButton.center.y = textLabel.center.y
            
            let toolsButton = UIButton()
            let toolImage = UIImage(systemName: "hammer")
            toolsButton.setImage(toolImage, for: .normal)
            toolsButton.tag = section
            toolsButton.addTarget(self, action: #selector(walletTools(_:)), for: .touchUpInside)
            toolsButton.frame = CGRect(x: refreshButton.frame.minX - 40, y: 0, width: 20, height: 20)
            toolsButton.center.y = textLabel.center.y
            
            let editButton = UIButton()
            let editImage = UIImage(systemName: "pencil")
            editButton.setImage(editImage, for: .normal)
            editButton.tag = section
            editButton.addTarget(self, action: #selector(editLabel(_:)), for: .touchUpInside)
            editButton.frame = CGRect(x: toolsButton.frame.minX - 40, y: 0, width: 20, height: 20)
            editButton.center.y = textLabel.center.y
            
            if wallet.isActive {
                
                textLabel.textColor = .white
                editButton.tintColor = .white
                toolsButton.tintColor = .white
                refreshButton.tintColor = .white
                
                editButton.isEnabled = true
                toolsButton.isEnabled = true
                refreshButton.isEnabled = true
                
            } else {
                
                editButton.tintColor = .systemGray
                toolsButton.tintColor = .systemGray
                refreshButton.tintColor = .systemGray
                textLabel.textColor = .systemGray
                
                editButton.isEnabled = false
                toolsButton.isEnabled = false
                refreshButton.isEnabled = false
                
            }
            
            header.addSubview(textLabel)
            header.addSubview(refreshButton)
            header.addSubview(toolsButton)
            header.addSubview(editButton)
            
            return header
            
        } else {
            
            return nil
            
        }
        
    }
    
    @objc func editLabel(_ sender: UIButton) {
        
        impact()
        
        let wallet = WalletStruct(dictionary: sortedWallets[sender.tag])
        
        DispatchQueue.main.async {
            
            let title = "Give your wallet a label"
            let message = "Add a label so you can easily identify your wallets"
            let style = UIAlertController.Style.alert
            
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: style)
            
            let save = UIAlertAction(title: "Save", style: .default) { (alertAction) in
                
                let textField = (alert.textFields![0] as UITextField).text
                
                if textField != "" {
                    
                    let cd = CoreDataService()
                    cd.updateEntity(id: wallet.id, keyToUpdate: "label", newValue: textField!, entityName: .wallets) {
                        
                        if !cd.errorBool {
                            
                            DispatchQueue.main.async {
                                
                                showAlert(vc: self, title: "Success", message: "Wallet label updated")
                                self.refresh()
                                
                            }
                            
                        } else {
                            
                            showAlert(vc: self, title: "Error!", message: "There was a problem saving your wallets label")
                            
                        }
                        
                    }
                    
                }
                
            }
            
            alert.addTextField { (textField) in
                textField.placeholder = "Add a label"
                textField.keyboardAppearance = .dark
            }
            
            alert.addAction(save)
            let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
            alert.addAction(cancel)
            self.present(alert, animated:true, completion: nil)
            
        }
        
    }
    
    @objc func walletTools(_ sender: UIButton) {
        
        if !isLoading {
            
            impact()
            
            DispatchQueue.main.async {
                
                let w = WalletStruct(dictionary: self.sortedWallets[sender.tag])
                self.wallet = w
                self.performSegue(withIdentifier: "goToTools", sender: self)
                
            }
            
        } else {
            
            showAlert(vc: self, title: "Please be patient", message: "We are fetching data from your node, wait until the spinner disappears then try again.")
            
        }
        
    }
    
    @objc func reloadSection(_ sender: UIButton) {
        
        if !isLoading {
            
            isLoading = true
            impact()
            let index = sender.tag
            
            DispatchQueue.main.async {
                
                sender.tintColor = .clear
                sender.loadingIndicator(show: true)
                
            }
            
            let wallet = WalletStruct(dictionary: self.sortedWallets[index])
            let nodeLogic = NodeLogic()
            nodeLogic.wallet = wallet
            nodeLogic.loadWalletData {
                
                if !nodeLogic.errorBool {
                    
                    let s = HomeStruct(dictionary: nodeLogic.dictToReturn)
                    let doub = (s.coldBalance).doubleValue
                    
                    self.cd.updateEntity(id: wallet.id, keyToUpdate: "lastBalance", newValue: doub, entityName: .wallets) {
                        
                        self.sortedWallets[index]["lastBalance"] = doub
                        self.sortedWallets[index]["lastUsed"]  = Date()
                        self.sortedWallets[index]["lastUpdated"] = Date()
                        
                        self.getRescanStatus(i: index, walletName: wallet.name) {
                            
                            DispatchQueue.main.async {
                                
                                sender.loadingIndicator(show: false)
                                sender.tintColor = .systemTeal
                                self.walletTable.reloadSections(IndexSet(arrayLiteral: index), with: .fade)
                                self.isLoading = false
                                
                            }
                            
                            self.cd.updateEntity(id: wallet.id, keyToUpdate: "lastUsed", newValue: Date(), entityName: .wallets) {}
                            self.cd.updateEntity(id: wallet.id, keyToUpdate: "lastUpdated", newValue: Date(), entityName: .wallets) {}
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            
            showAlert(vc: self, title: "Please be patient", message: "We are fetching data from your node, wait until the spinner disappears then try again.")
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if sortedWallets.count > 0 {
         
            let dict = sortedWallets[indexPath.section]
            let wallet = WalletStruct.init(dictionary: dict)
            
            if !wallet.isActive {
                
                activateNow(wallet: wallet, index: indexPath.section)
                
            }
            
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
        
        if !isLoading {
            
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
            
        } else {
            
            showAlert(vc: self, title: "Fetching wallet data from your node...", message: "Please wait until the spinner disappears as the app is currently fetching wallet data from your node.")
            
        }
        
    }
    
    func getWalletBalance(wallet: WalletStruct, i: Int, completion: @escaping () -> Void) {
        
        let nodeLogic = NodeLogic()
        nodeLogic.wallet = wallet
        nodeLogic.loadWalletData {
            
            if !nodeLogic.errorBool {
                
                let s = HomeStruct(dictionary: nodeLogic.dictToReturn)
                let doub = (s.coldBalance).doubleValue
                
                self.cd.updateEntity(id: wallet.id, keyToUpdate: "lastBalance", newValue: doub, entityName: .wallets) {
                    
                    self.sortedWallets[i]["lastBalance"] = doub
                    self.cd.updateEntity(id: wallet.id, keyToUpdate: "lastUpdated", newValue: Date(), entityName: .wallets) {}
                    
                    self.getRescanStatus(i: self.index, walletName: wallet.name) {
                        
                        DispatchQueue.main.async {
                            
                            self.walletTable.reloadSections(IndexSet(arrayLiteral: i), with: .fade)
                            completion()
                            
                        }
                                                
                    }
                    
                }
                
            } else {
                
                completion()
                
            }
            
        }
        
    }
    
    func getBalances() {
        
        // only fetch balances that are on the current active node
        if self.index < sortedWallets.count {
            
            let wallet = WalletStruct(dictionary: sortedWallets[self.index])
            let enc = Encryption()
            enc.getNode { (node, error) in
                
                if !error && node != nil {
                    
                    if node!.id == wallet.nodeId {
                        
                        self.getWalletBalance(wallet: wallet, i: self.index) {
                            
                            self.index += 1
                            self.getBalances()
                            
                        }
                        
                    } else {
                        
                        self.index += 1
                        self.getBalances()
                        
                    }
                    
                }
                
            }
            
        } else {
            
            DispatchQueue.main.async {
                
                self.isLoading = false
                self.loadingRefresher.alpha = 0
                self.loadingRefresher.stopAnimating()
                self.refresher.endRefreshing()
                
            }
            
        }
        
    }
    
    func getRescanStatus(i: Int, walletName: String, completion: @escaping () -> Void) {
        
        print("get rescan status")
        let reducer = Reducer()
        reducer.makeCommand(walletName: walletName, command: .getwalletinfo, param: "") {

            if !reducer.errorBool || reducer.errorDescription.description.contains("abort") {

                if let result = reducer.dictToReturn {

                    if let scanning = result["scanning"] as? NSDictionary {

                        if let _ = scanning["duration"] as? Int {

                            let progress = (scanning["progress"] as! Double) * 100
                            self.sortedWallets[i]["progress"] = "\(Int(progress))"
                            self.sortedWallets[i]["isRescanning"] = true
                            completion()

                        }

                    } else {

                        self.sortedWallets[i]["isRescanning"] = false
                        completion()

                    }

                }

            } else {

                self.sortedWallets[i]["isRescanning"] = false
                completion()

            }

        }
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        switch id {
            
        case "goToTools":
            
            if let vc = segue.destination as? WalletToolsViewController {
                
                vc.wallet = self.wallet
                vc.sweepDoneBlock = { result in
                    
                    self.refresh()
                    showAlert(vc: self, title: "Wallet Sweeped! 🤩", message: "We are refreshing your balances now.")
                    
                }
                
            }
            
        case "walletInfo":
            
            if let vc = segue.destination as? WalletInfoViewController {
                
                vc.walletname = name
                
            }
            
        case "verifyAddresses":
            
            if let vc = segue.destination as? VerifyKeysViewController {
                
                vc.comingFromSettings = true
                
            }
            
        case "addWallet":
            
            if let vc = segue.destination as? ChooseWalletFormatViewController {
                
                vc.walletDoneBlock = { result in
                    
                    showAlert(vc: self, title: "Success!", message: "Wallet created successfully!")
                    self.isLoading = true
                    self.refresh()
                    
                }
                
//                vc.importDoneBlock = { result in
//
//                    DispatchQueue.main.async {
//
//                        self.performSegue(withIdentifier: "importCustom", sender: self)
//
//                    }
//
//                }
                
                vc.recoverDoneBlock = { result in
                    
                    DispatchQueue.main.async {
                        
                        self.isLoading = true
                        self.refresh()
                        
                        showAlert(vc: self, title: "Success!", message: "Wallet recovered 🤩!")
                        
                    }
                    
                }
                
            }
            
//        case "showRecoveryKit":
//
//            if let vc = segue.destination as? RecoveryViewController {
//
//                vc.recoveryPhrase = self.recoveryPhrase
//                vc.descriptor = self.descriptor
//
//                vc.onDoneBlock2 = { result in
//
//                    self.isLoading = true
//                    self.refresh()
//
//                }
//
//            }
            
//        case "importCustom":
//
//            if let vc = segue.destination as? ImportViewController {
//
//                vc.importComplete = { result in
//
//                    showAlert(vc: self, title: "Success!", message: "Wallet imported! Tap it to active it.")
//                    self.isLoading = true
//                    self.refresh()
//
//                }
//
//            }
            
        default:
            
            break
            
        }
        
    }
    
}
