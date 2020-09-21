//
//  WalletsViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 10/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    weak var nodeLogic = NodeLogic.sharedInstance
    var walletName = ""
    var walletToImport = [String:Any]()
    var isLoading = Bool()
    var refresher: UIRefreshControl!
    var index = 0
    var name = ""
    var node:NodeStruct!
    var wallets = [[String:Any]]()
    var activeWallet:WalletStruct!
    var sortedWallets = [[String:Any]]()
    let dateFormatter = DateFormatter()
    let spinner = ConnectingView()
    var nodes = [[String:Any]]()
    var recoveryPhrase = ""
    var descriptor = ""
    var urToRecover = ""
    var xprv = ""
    @IBOutlet var walletTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        walletTable.delegate = self
        walletTable.dataSource = self
        configureRefresher()
        walletTable.setContentOffset(.zero, animated: true)
        NotificationCenter.default.addObserver(self, selector: #selector(didSweep(_:)), name: .didSweep, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCreateAccount(_:)), name: .didCreateAccount, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRescanAccount(_:)), name: .didRescanAccount, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didAbortRescan(_:)), name: .didAbortRescan, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(seedAdded(_:)), name: .seedAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(seedDeleted(_:)), name: .seedDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transactionSent(_:)), name: .transactionSent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSwitched(_:)), name: .nodeSwitched, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLabel(_:)), name: .didUpdateLabel, object: nil)
        refreshLocalDataAndBalanceForActiveAccount()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: TODO - Add a notification when a signer or seed gets added to refresh
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        nodes.removeAll()
    }
    
    @IBAction func scanQr(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "goImport", sender: vc)
        }
    }
    
    @IBAction func accountTools(_ sender: Any) {
        if activeWallet != nil {
            walletTools()
        } else {
            showAlert(vc: self, title: "No active account", message: "Tap an account to activate it, then you can use tools. If you don't have any accounts create one by tapping the + button or import one by tapping the QR scanner.")
        }
    }
    
    @IBAction func addAccount(_ sender: Any) {
        createWallet()
    }
    
    @objc func didUpdateLabel(_ notification: Notification) {
        refreshLocalDataOnly()
    }
    
    @objc func didCreateAccount(_ notification: Notification) {
        refreshLocalDataAndBalanceForActiveAccount()
    }
    
    @objc func didRescanAccount(_ notification: Notification) {
        refreshActiveWalletData()
    }
    
    @objc func didAbortRescan(_ notification: Notification) {
        refreshActiveWalletData()
    }
    
    @objc func seedAdded(_ notification: Notification) {
        refreshLocalDataOnly()
    }
    
    @objc func seedDeleted(_ notification: Notification) {
        refreshLocalDataOnly()
    }
    
    @objc func transactionSent(_ notification: Notification) {
        spinner.addConnectingView(vc: self, description: "refreshing balance...")
        /// Need to hardcode a delay as doing it immideately after the transaction broadcasts means the transaction may not have propgated across the network that quickly. Keep in mind we use Blockstreams node to broadcast transactions, if we strictly used our own node then of course it would be instant.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned vc = self] in
            vc.refreshActiveWalletData()
        }
    }
    
    @objc func nodeSwitched(_ notification: Notification) {
        refreshLocalDataOnly()
    }
    
    @objc func didSweep(_ notification: Notification) {
        refreshLocalDataAndBalanceForActiveAccount()
    }
    
    private func configureRefresher() {
        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.white
        refresher.attributedTitle = NSAttributedString(string: "refresh data", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        refresher.addTarget(self, action: #selector(self.refreshLocalDataAndBalanceForActiveAccount), for: UIControl.Event.valueChanged)
        walletTable.addSubview(refresher)
    }
    
//    func onionAddress(wallet: WalletStruct) -> String {
//        var rpcOnion = ""
//        for n in nodes {
//            let s = NodeStruct(dictionary: n)
//            if s.id == wallet.nodeId {
//                rpcOnion = s.onionAddress
//            }
//        }
//        return rpcOnion
//    }
    
    func refreshLocalDataOnly() {
        spinner.addConnectingView(vc: self, description: "refreshing local data...")
        setOnionLabels() { [unowned vc = self] success in
            if success {
                vc.setSortedWalletsArray() { [unowned vc = self] success in
                    if success {
                        vc.setKnownUnknownSignersAndFingerprints() { [unowned vc = self] success in
                            DispatchQueue.main.async {
                                vc.walletTable.reloadData()
                                vc.spinner.removeConnectingView()
                            }
                        }
                    }
                }
            } else {
                vc.spinner.removeConnectingView()
            }
        }
    }
    
    private func refreshActiveWalletData() {
        func reloadNow() {
            DispatchQueue.main.async { [unowned vc = self] in
                vc.walletTable.reloadData()
                vc.refresher.endRefreshing()
                vc.spinner.removeConnectingView()
                vc.walletTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                vc.isLoading = false
            }
        }
        let account = WalletStruct(dictionary: sortedWallets[0])
        getWalletBalance(walletStruct: account) {
            reloadNow()
        }
    }
    
    private func deactivateAllAccounts() {
        isLoading = false
        for (i, wallet) in sortedWallets.enumerated() {
            let w = WalletStruct(dictionary: wallet)
            CoreDataService.updateEntity(id: w.id!, keyToUpdate: "isActive", newValue: false, entityName: .wallets) {_ in }
            if i + 1 == sortedWallets.count {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.refresher.endRefreshing()
                    vc.spinner.removeConnectingView()
                    vc.walletTable.reloadData()
                }
            }
        }
    }
    
    private func setOnionLabels(completion: @escaping ((Bool)) -> Void) {
        CoreDataService.retrieveEntity(entityName: .nodes) { [unowned vc = self] (nodes, errorDescription) in
            if errorDescription == nil && nodes != nil {
                if nodes!.count > 0 {
                    vc.nodes = nodes!
                    for (i, n) in nodes!.enumerated() {
                        Encryption.decryptData(dataToDecrypt: (n["onionAddress"] as! Data)) { (decryptedOnionAddress) in
                            if decryptedOnionAddress != nil {
                                vc.nodes[i]["onionAddress"] = String(bytes: decryptedOnionAddress!, encoding: .utf8)
                            }
                            Encryption.decryptData(dataToDecrypt: (n["label"] as! Data)) { (decryptedLabel) in
                                if decryptedLabel != nil {
                                    vc.nodes[i]["label"] = String(bytes: decryptedLabel!, encoding: .utf8)
                                }
                            }
                        }
                        if i + 1 == nodes!.count {
                            completion(true)
                        }
                    }
                } else {
                    completion(false)
                }
            }
        }
    }
    
    private func setSortedWalletsArray(completion: @escaping ((Bool)) -> Void) {
        sortedWallets.removeAll()
        CoreDataService.retrieveEntity(entityName: .wallets) { [unowned vc = self] (wallets, errorDescription) in
            if errorDescription == nil {
                if wallets!.count == 0 {
                    vc.spinner.removeConnectingView()
                    vc.isLoading = false
                    completion(false)
                } else {
                    for (i, w) in wallets!.enumerated() {
                        let s = WalletStruct(dictionary: w)
                        if !s.isArchived && w["id"] != nil && w["name"] != nil {
                            vc.sortedWallets.append(w)
                            if s.isActive {
                                vc.activeWallet = s
                            }
                        }
                        if i + 1 == wallets!.count {
                            if vc.sortedWallets.count == 0 {
                                vc.spinner.removeConnectingView()
                                vc.isLoading = false
                                completion(false)
                            } else {
                                completion(true)
                            }
                        }
                    }
                }
            } else {
                completion(false)
                vc.spinner.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: errorDescription!)
            }
        }
    }
    
    private func getAccountBalance() {
        if nodes.count == 0 {
            deactivateAllAccounts()
        } else {
            refreshActiveWalletData()
        }
    }
    
    private func setKnownUnknownSignersAndFingerprints(completion: @escaping ((Bool)) -> Void) {
        for (i, wallet) in sortedWallets.enumerated() {
            let wstruct = WalletStruct(dictionary: wallet)
            SeedParser.getSigners(wallet: wstruct) { [unowned vc = self] (knownSigners, uknownSigners) in
                vc.sortedWallets[i]["knownSigners"] = knownSigners
                vc.sortedWallets[i]["unknownSigners"] = uknownSigners
                if i + 1 == vc.sortedWallets.count {
                    vc.sortedWallets = vc.sortedWallets.sorted{ ($0["lastUsed"] as? Date ?? Date()) > ($1["lastUsed"] as? Date ?? Date()) }
                    vc.setLifeHashes(completion: completion)
                }
            }
        }
    }
    
    private func setLifeHashes(completion: @escaping ((Bool)) -> Void) {
        if index < sortedWallets.count {
            let wstruct = WalletStruct(dictionary: sortedWallets[index])
            sortedWallets[index]["lifehash"] = lifehash(wstruct.descriptor)
            index += 1
            setLifeHashes(completion: completion)
        } else {
            index = 0
            completion(true)
        }
    }
    
    @objc func refreshLocalDataAndBalanceForActiveAccount() {
        spinner.addConnectingView(vc: self, description: "loading accounts...")
        sortedWallets.removeAll()
        wallets.removeAll()
        activeWallet = nil
        walletTable.reloadData()
        setOnionLabels() { success in
            if success {
                CoreDataService.retrieveEntity(entityName: .wallets) { [unowned vc = self] (wallets, errorDescription) in
                    if errorDescription == nil {
                        if wallets!.count == 0 {
                            vc.refresher.endRefreshing()
                            vc.spinner.removeConnectingView()
                            vc.isLoading = false
                        } else {
                            for (i, w) in wallets!.enumerated() {
                                let s = WalletStruct(dictionary: w)
                                if !s.isArchived && w["id"] != nil && w["name"] != nil {
                                    vc.sortedWallets.append(w)
                                    if s.isActive {
                                        vc.activeWallet = s
                                    }
                                }
                                if i + 1 == wallets!.count {
                                    if vc.sortedWallets.count == 0 {
                                        vc.spinner.removeConnectingView()
                                        vc.refresher.endRefreshing()
                                        vc.isLoading = false
                                    }
                                    vc.setKnownUnknownSignersAndFingerprints() { [unowned vc = self] success in
                                        vc.getAccountBalance()
                                    }
                                }
                            }
                        }
                    } else {
                        vc.refresher.endRefreshing()
                        vc.spinner.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDescription!)
                    }
                }
            } else {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.refresher.endRefreshing()
                    vc.spinner.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "No nodes, please add one in order to use the app.")
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
    
    private func lifehash(_ input: String) -> UIImage {
        return LifeHash.image(input)
    }
    
    private func singleSigCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let d = sortedWallets[indexPath.section]
        let walletStruct = WalletStruct.init(dictionary: d)
        
        let cell = walletTable.dequeueReusableCell(withIdentifier: "singleSigWalletCell", for: indexPath)
        cell.selectionStyle = .none
        
        let balanceLabel = cell.viewWithTag(1) as! UILabel
        let deviceLabel = cell.viewWithTag(2) as! UILabel
        let nodeKeyLabel = cell.viewWithTag(3) as! UILabel
        let updatedLabel = cell.viewWithTag(13) as! UILabel
        let createdLabel = cell.viewWithTag(14) as! UILabel
        let rpcOnionLabel = cell.viewWithTag(19) as! UILabel
        let walletFileLabel = cell.viewWithTag(20) as! UILabel
        let seedOnDeviceView = cell.viewWithTag(21)!
        let nodeView = cell.viewWithTag(26)!
        let nodeLabel = cell.viewWithTag(27) as! UILabel
        let deviceXprv = cell.viewWithTag(28) as! UILabel
        let bannerView = cell.viewWithTag(32)!
        let nodeKeysLabel = cell.viewWithTag(33) as! UILabel
        let seedOnDeviceLabel = cell.viewWithTag(37) as! UILabel
        let deviceSeedImage = cell.viewWithTag(38) as! UIImageView
        let walletTypeLabel = cell.viewWithTag(39) as! UILabel
        let walletTypeImage = cell.viewWithTag(40) as! UIImageView
        let accountLabel = cell.viewWithTag(42) as! UILabel
        let typeLabel = cell.viewWithTag(43) as! UILabel
        let lifehashImage = cell.viewWithTag(44) as! UIImageView
        
        deviceLabel.text = UIDevice.current.name
        accountLabel.text = walletStruct.label
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.text = "\(walletStruct.lastBalance.avoidNotation) BTC"
        
        lifehashImage.image = (sortedWallets[indexPath.section]["lifehash"] as! UIImage)
        lifehashImage.clipsToBounds = true
        lifehashImage.layer.cornerRadius = 5
        lifehashImage.layer.magnificationFilter = .nearest
        
        if walletStruct.isActive {
            
            cell.contentView.alpha = 1
            bannerView.backgroundColor = #colorLiteral(red: 0, green: 0.1631944358, blue: 0.3383367703, alpha: 1)
            
        } else if !walletStruct.isActive {
            
            cell.contentView.alpha = 0.4
            bannerView.backgroundColor = #colorLiteral(red: 0.1051254794, green: 0.1292803288, blue: 0.1418488324, alpha: 1)
            
        }
        
        if let isRescanning = sortedWallets[indexPath.section]["isRescanning"] as? Bool {
            
            if isRescanning {
                
                if let progress = sortedWallets[indexPath.section]["progress"] as? String {
                    
                    balanceLabel.text = "Rescanning... \(progress)%"
                    
                }
                                
            }
            
        }
        
        nodeView.layer.cornerRadius = 8
        seedOnDeviceView.layer.cornerRadius = 8
        
        let derivation = walletStruct.derivation
        
        if walletStruct.descriptor.contains("tpub") {
            balanceLabel.textColor = .systemOrange
            
        } else {
            balanceLabel.textColor = .systemGreen
            
        }
        
        if walletStruct.knownSigners.count == 1 {
            seedOnDeviceLabel.text = "1 account xprv"
            deviceXprv.text = process(walletStruct.knownSigners)
            deviceSeedImage.image = UIImage(imageLiteralResourceName: "Signature")
            walletTypeLabel.text = "Hot Account"
            walletTypeImage.image = UIImage(systemName: "flame")
            walletTypeImage.tintColor = .systemRed
        } else {
            seedOnDeviceLabel.text = "Cold"
            deviceXprv.text = "1 account xpub \(walletStruct.derivation)"
            deviceSeedImage.image = UIImage(systemName: "eye.fill")
            walletTypeLabel.text = "Cold Account"
            walletTypeImage.image = UIImage(systemName: "snow")
            walletTypeImage.tintColor = .white
        }
        
        nodeKeyLabel.text = "1 account xpub \(walletStruct.derivation)"
        nodeKeysLabel.text = "1 keypool, keys \(walletStruct.index) to \(walletStruct.maxRange) unused"
        updatedLabel.text = "\(formatDate(date: walletStruct.lastUpdated))"
        createdLabel.text = "\(getDate(unixTime: walletStruct.birthdate))"
        walletFileLabel.text = reducedWalletName(name: walletStruct.name!)
        
        if derivation.contains("84") {

            typeLabel.text = "Single Sig - Segwit"

        } else if derivation.contains("44") {

            typeLabel.text = "Single Sig - Legacy"

        } else if derivation.contains("49") {

            typeLabel.text = "Single Sig - Nested Segwit"

        } else {
            
            typeLabel.text = "Single Sig - Custom"
        }
        
        for n in nodes {
            let s = NodeStruct(dictionary: n)
            
            if s.id == walletStruct.nodeId {
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
        let walletStruct = WalletStruct.init(dictionary: d)
        
        let cell = walletTable.dequeueReusableCell(withIdentifier: "multiSigWalletCell", for: indexPath)
        cell.selectionStyle = .none
        
        let balanceLabel = cell.viewWithTag(1) as! UILabel
        let deviceLabel = cell.viewWithTag(2) as! UILabel
        let nodesXprv = cell.viewWithTag(3) as! UILabel
        let updatedLabel = cell.viewWithTag(13) as! UILabel
        let createdLabel = cell.viewWithTag(14) as! UILabel
        let rpcOnionLabel = cell.viewWithTag(19) as! UILabel
        let walletFileLabel = cell.viewWithTag(20) as! UILabel
        let seedOnDeviceView = cell.viewWithTag(21)!
        let seedOnNodeView = cell.viewWithTag(22)!
        let seedOfflineView = cell.viewWithTag(23)!
        let nodeView = cell.viewWithTag(26)!
        let nodeLabel = cell.viewWithTag(27) as! UILabel
        let deviceXprv = cell.viewWithTag(29) as! UILabel
        let nodeKeys = cell.viewWithTag(30) as! UILabel
        let offlineXprv = cell.viewWithTag(31) as! UILabel
        let bannerView = cell.viewWithTag(33)!
        let seedOnDeviceLabel = cell.viewWithTag(36) as! UILabel
        let offlineSeedLabel = cell.viewWithTag(37) as! UILabel
        let mOfnTypeLabel = cell.viewWithTag(38) as! UILabel
        let walletType = cell.viewWithTag(39) as! UILabel
        let walletTypeImage = cell.viewWithTag(40) as! UIImageView
        let deviceSeedImage = cell.viewWithTag(41) as! UIImageView
        let accountLabel = cell.viewWithTag(42) as! UILabel
        let primaryKeysNodeSignerImage = cell.viewWithTag(43) as! UIImageView
        
        let lifehashImage = cell.viewWithTag(44) as! UIImageView
        lifehashImage.image = (sortedWallets[indexPath.section]["lifehash"] as! UIImage)
        lifehashImage.clipsToBounds = true
        lifehashImage.layer.cornerRadius = 5
        lifehashImage.layer.magnificationFilter = .nearest
        
        deviceLabel.text = UIDevice.current.name
        accountLabel.text = walletStruct.label
        let p = DescriptorParser()
        let str = p.descriptor(walletStruct.descriptor)
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.text = "\(walletStruct.lastBalance.avoidNotation) BTC"
                
        if let isRescanning = sortedWallets[indexPath.section]["isRescanning"] as? Bool {
            
            if isRescanning {
                
                if let progress = sortedWallets[indexPath.section]["progress"] as? String {
                    
                    balanceLabel.text = "Rescanning... \(progress)%"
                    
                }
                                
            }
            
        }
        
        if walletStruct.isActive {
            
            cell.contentView.alpha = 1
            bannerView.backgroundColor = #colorLiteral(red: 0, green: 0.1631944358, blue: 0.3383367703, alpha: 1)
            
        } else if !walletStruct.isActive {
            
            cell.contentView.alpha = 0.6
            bannerView.backgroundColor = #colorLiteral(red: 0.1051254794, green: 0.1292803288, blue: 0.1418488324, alpha: 1)
            
        }
        
        nodeView.layer.cornerRadius = 8
        seedOnDeviceView.layer.cornerRadius = 8
        seedOnNodeView.layer.cornerRadius = 8
        seedOfflineView.layer.cornerRadius = 8
        
        let derivation = walletStruct.derivation
        
        if derivation.contains("1") {
            
            balanceLabel.textColor = .systemOrange
            
        } else {
            
            balanceLabel.textColor = .systemGreen
            
        }
        
        if derivation.contains("84") {
            
            mOfnTypeLabel.text = "\(str.mOfNType) multisig - Segwit"
            
        } else if derivation.contains("44") {
            
            mOfnTypeLabel.text = "\(str.mOfNType) multisig - Legacy"
            
        } else if derivation.contains("49") {
            
            mOfnTypeLabel.text = "\(str.mOfNType) multisig - Nested Segwit"
            
        } else if derivation.contains("48") {
            
            mOfnTypeLabel.text = "\(str.mOfNType) multisig - Segwit"
            
        } else {
            
            mOfnTypeLabel.text = "\(str.mOfNType) multisig - Custom"
            
        }
        
        let descriptorParser = DescriptorParser()
        let descriptorStruct = descriptorParser.descriptor(walletStruct.descriptor)
        nodesXprv.text = "1 keypool, keys \(walletStruct.index) to \(walletStruct.maxRange) unused"
        
        if descriptorStruct.keysWithPath.count == 3 {
            let nodesKey = descriptorStruct.keysWithPath[2]
            let nodesPath = nodesKey.replacingOccurrences(of: descriptorStruct.multiSigKeys[2], with: "")
            let arr = nodesPath.split(separator: "]")
            let xprvPath = "\(arr[0])]"
            if walletStruct.nodeIsSigner != nil {
                if walletStruct.nodeIsSigner! {
                    nodeKeys.text = "1 xprv \(xprvPath)"
                    primaryKeysNodeSignerImage.image = UIImage(imageLiteralResourceName: "Signature")
                } else {
                    nodeKeys.text = "3 xpub's \(walletStruct.derivation)"
                    primaryKeysNodeSignerImage.image = UIImage(systemName: "eye.fill")
                }
            } else {
                nodeKeys.text = "3 xpub's \(walletStruct.derivation)"
                primaryKeysNodeSignerImage.image = UIImage(systemName: "eye.fill")
            }
        } else {
            nodeKeys.text = "\(descriptorStruct.keysWithPath.count) xpub's \(walletStruct.derivation)"
            primaryKeysNodeSignerImage.image = UIImage(systemName: "eye.fill")
        }
                
        if walletStruct.knownSigners.count >= str.sigsRequired {
            
            var seedText = "xprv"
            if walletStruct.knownSigners.count > 1 {
                seedText = "xprvs"
            }
            seedOnDeviceLabel.text = "\(walletStruct.knownSigners.count) account \(seedText)"
            walletType.text = "Hot Account"
            walletTypeImage.image = UIImage(systemName: "flame")
            walletTypeImage.tintColor = .systemRed
            deviceSeedImage.image = UIImage(imageLiteralResourceName: "Signature")
            deviceXprv.text = process(walletStruct.knownSigners)
                        
        } else if walletStruct.knownSigners.count < str.sigsRequired && walletStruct.knownSigners.count > 0 {
            
            var seeds = "xprvs"
            if walletStruct.knownSigners.count == 1 {
                seeds = "xprv"
            }
            
            seedOnDeviceLabel.text = "\(walletStruct.knownSigners.count) account \(seeds)"
            walletType.text = "Warm Account"
            walletTypeImage.image = UIImage(systemName: "sun.min")
            walletTypeImage.tintColor = .systemYellow
            deviceSeedImage.image = UIImage(imageLiteralResourceName: "Signature")
            deviceXprv.text = process(walletStruct.knownSigners)
            
        } else if walletStruct.knownSigners.count == 0 {
            
            if walletStruct.nodeIsSigner != nil {
                if walletStruct.nodeIsSigner! {
                    seedOnDeviceLabel.text = "Cool"
                    walletType.text = "Cool Account"
                    walletTypeImage.image = UIImage(systemName: "cloud.sun")
                } else {
                    seedOnDeviceLabel.text = "Cold"
                    walletType.text = "Cold Account"
                    walletTypeImage.image = UIImage(systemName: "snow")
                }
            } else {
                seedOnDeviceLabel.text = "Cold"
                walletType.text = "Cold Account"
                walletTypeImage.image = UIImage(systemName: "snow")
            }
            
            walletTypeImage.tintColor = .systemTeal
            deviceSeedImage.image = UIImage(systemName: "eye.fill")
            deviceXprv.text = "\(descriptorStruct.keysWithPath.count) xpub's: \(walletStruct.derivation)"
            
        }
        
        offlineSeedLabel.text = "\(walletStruct.unknownSigners.count) external master seed's"
        offlineXprv.text = process(walletStruct.unknownSigners)
        
        updatedLabel.text = "\(formatDate(date: walletStruct.lastUpdated))"
        createdLabel.text = "\(getDate(unixTime: walletStruct.birthdate))"
        walletFileLabel.text = reducedWalletName(name: walletStruct.name!)
        
        for n in nodes {
            
            let s = NodeStruct(dictionary: n)
        
            if walletStruct.nodeId != nil {
                if s.id == walletStruct.nodeId {
                    
                    let rpcOnion = s.onionAddress
                    let first10 = String(rpcOnion.prefix(5))
                    let last15 = String(rpcOnion.suffix(15))
                    rpcOnionLabel.text = "\(first10)*****\(last15)"
                    nodeLabel.text = s.label
                    
                }
            }
            
        }
        
        return cell
        
    }
    
    private func process(_ fingerprints:[String]) -> String {
        var stringToreturn = (fingerprints.description).replacingOccurrences(of: "[", with: "")
        stringToreturn = stringToreturn.replacingOccurrences(of: "]", with: "")
        stringToreturn = stringToreturn.replacingOccurrences(of: "\"", with: "")
        return stringToreturn
    }
        
    private func noWalletCell() -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.backgroundColor = .black
        cell.textLabel?.text = "⚠︎ No account's created yet, tap the +"
        cell.textLabel?.textColor = .lightGray
        cell.textLabel?.font = .systemFont(ofSize: 17)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if sortedWallets.count > 0 {
            
            let d = sortedWallets[indexPath.section]
            let walletStruct = WalletStruct.init(dictionary: d)
                
            switch walletStruct.type {
                
            case "DEFAULT":
                
                return singleSigCell(indexPath)
                
            case "MULTI":
                
                return multiSigWalletCell(indexPath)
                
            default:
                
                return UITableViewCell()
                
            }
            
        } else {
            
            return noWalletCell()
            
        }
        
    }
    
    @objc func exportSeed(_ sender: UIButton) {
        
        let isCaptured = UIScreen.main.isCaptured
        
        if !isCaptured {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.performSegue(withIdentifier: "exportSeed", sender: vc)
                
            }
            
        } else {
            
            showAlert(vc: self, title: "Security Alert!", message: "Your device is taking a screen recording, please stop the recording and try again.")
            
        }        
                
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if sortedWallets.count > 0 {
            
            let type = WalletStruct(dictionary: sortedWallets[indexPath.section]).type
            
            switch  type {
                
            case "DEFAULT":
                
                return 335
                
            case "MULTI":
                
                return 439
                
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
    
    @objc func walletTools() {
        if !isLoading {
            DispatchQueue.main.async { [unowned vc = self] in
                vc.performSegue(withIdentifier: "goToTools", sender: vc)
            }
        } else {
            showAlert(vc: self, title: "Please be patient", message: "We are fetching data from your node, wait until the spinner disappears then try again.")
        }
    }
    
    @objc func reloadActiveWallet() {

        if !isLoading {
            refresher.beginRefreshing()
            isLoading = true

            DispatchQueue.main.async { [unowned vc = self] in
                vc.spinner.addConnectingView(vc: vc, description: "refreshing wallet data...")
            }

            let walletStruct = WalletStruct(dictionary: self.sortedWallets[index])

            nodeLogic?.loadWalletData(wallet: walletStruct) { [unowned vc = self] (success, dictToReturn, errorDesc) in

                if success && dictToReturn != nil {

                    let s = HomeStruct(dictionary: dictToReturn!)
                    let doub = (s.coldBalance).doubleValue

                    vc.sortedWallets[0]["lastBalance"] = doub
                    vc.sortedWallets[0]["lastUsed"]  = Date()
                    vc.sortedWallets[0]["lastUpdated"] = Date()

                    vc.getRescanStatus(walletName: WalletStruct(dictionary: vc.sortedWallets[0]).name ?? "") {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.walletTable.reloadData()
                            vc.isLoading = false
                            vc.spinner.removeConnectingView()
                            vc.refresher.endRefreshing()
                        }
                    }

                } else {

                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.walletTable.reloadSections(IndexSet(arrayLiteral: 0), with: .fade)
                        vc.isLoading = false
                        vc.refreshLocalDataAndBalanceForActiveAccount()
                        vc.spinner.removeConnectingView()
                        vc.refresher.endRefreshing()
                        showAlert(vc: self, title: "Error", message: errorDesc ?? "error updating balance")
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
            let walletStruct = WalletStruct.init(dictionary: dict)
            
            if !walletStruct.isActive {
                
                UIView.animate(withDuration: 0.3) { [unowned vc = self] in
                    vc.walletTable.alpha = 0
                }
                
                activateNow(wallet: walletStruct, index: indexPath.section)
                
            }
            
        }
        
    }
    
    func activateNow(wallet: WalletStruct, index: Int) {
        
        if !wallet.isActive {
                        
            Encryption.getNode { [unowned vc = self] (n, error) in
                
                if n != nil {
                    
                    if wallet.nodeId != nil {
                        if wallet.nodeId! != n!.id {
                            
                            CoreDataService.updateEntity(id: wallet.nodeId!, keyToUpdate: "isActive", newValue: true, entityName: .nodes) {_ in }
                            CoreDataService.updateEntity(id: n!.id, keyToUpdate: "isActive", newValue: false, entityName: .nodes) {_ in }
                            vc.activeWallet = wallet
                            
                        }
                    }
                    
                }
                
            }
            
            CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "lastUsed", newValue: Date(), entityName: .wallets) { [unowned vc = self] _ in
                
                vc.activate(walletToActivate: wallet.id!, index: index)
                
            }
            
        }
        
    }
    
    func getDate(unixTime: Int32) -> String {
        
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm"
        let strDate = dateFormatter.string(from: date)
        return strDate
        
    }
    
    func formatDate(date: Date) -> String {
        
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm"
        let strDate = dateFormatter.string(from: date)
        return strDate
        
    }
    
    func activate(walletToActivate: UUID, index: Int) {
        
        CoreDataService.updateEntity(id: walletToActivate, keyToUpdate: "isActive", newValue: true, entityName: .wallets) { [unowned vc = self] (success, errorDesc) in
            
            if success {
                                        
                vc.deactivate(walletToActivate: walletToActivate, index: index)
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: "error deactivating account")
                
            }
            
        }
        
    }
    
    func deactivate(walletToActivate: UUID, index: Int) {
        
        for (i, wallet) in sortedWallets.enumerated() {
            
            let str = WalletStruct.init(dictionary: wallet)
            
            if str.id != walletToActivate {
                
                CoreDataService.updateEntity(id: str.id!, keyToUpdate: "isActive", newValue: false, entityName: .wallets) { [unowned vc = self] (success, errorDesc) in
                    
                    if !success {
                        
                        displayAlert(viewController: vc, isError: true, message: "error deactivating account")
                        
                    }
                    
                }
                
            }
            
            if i + 1 == sortedWallets.count {
                
                refreshLocalDataAndBalanceForActiveAccount()
                
                UIView.animate(withDuration: 1.5) { [unowned vc = self] in
                    vc.walletTable.alpha = 1
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .didSwitchAccounts, object: nil, userInfo: nil)
                }
                
            }
            
        }
        
    }
    
    @objc func createWallet() {
        
        if !isLoading {
            
//-------------------------------------------------------------------------------
// MARK: - To enable mainnet accounts just uncomment the following lines of code:
//
            DispatchQueue.main.async { [unowned vc = self] in

                vc.performSegue(withIdentifier: "addWallet", sender: vc)

            }
//-------------------------------------------------------------------------------
// MARK: - And comment out the following lines of code:

//            Encryption.getNode { [unowned vc = self] (node, error) in
//                
//                if !error && node != nil {
//                    
//                    if node!.network == "mainnet" {
//                        
//                        DispatchQueue.main.async {
//                            var alertStyle = UIAlertController.Style.actionSheet
//                            if (UIDevice.current.userInterfaceIdiom == .pad) {
//                                alertStyle = UIAlertController.Style.alert
//                            }
//                            let alert = UIAlertController(title: "We appreciate your patience", message: "We are still adding new features, so mainnet wallets are disabled. Please help us test.", preferredStyle: alertStyle)
//                            alert.addAction(UIAlertAction(title: "Understood", style: .default, handler: { action in }))
//                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
//                            vc.present(alert, animated: true, completion: nil)
//                        }
//                        
//                    } else {
//                        
//                        DispatchQueue.main.async {
//                            
//                            vc.performSegue(withIdentifier: "addWallet", sender: vc)
//                            
//                        }
//                        
//                    }
//                    
//                } else {
//                    
//                    displayAlert(viewController: vc, isError: true, message: "No active nodes")
//                    
//                }
//                
//            }
//-------------------------------------------------------------------------------
            
        } else {
            
            showAlert(vc: self, title: "Fetching wallet data from your node...", message: "Please wait until the spinner disappears as the app is currently fetching wallet data from your node.")
            
        }
        
    }
    
    func getWalletBalance(walletStruct: WalletStruct, completion: @escaping () -> Void) {
        nodeLogic?.loadWalletData(wallet: walletStruct) { [unowned vc = self] (success, dictToReturn, errorDesc) in
            if success && dictToReturn != nil {
                let s = HomeStruct(dictionary: dictToReturn!)
                let doub = (s.coldBalance).doubleValue
                vc.sortedWallets[0]["lastBalance"] = doub
                vc.getRescanStatus(walletName: walletStruct.name ?? "") {
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    func getRescanStatus(walletName: String, completion: @escaping () -> Void) {
        
        if sortedWallets.count > 0 {
            
            Reducer.makeCommand(walletName: walletName, command: .getexternalwalletinfo, param: "") { [unowned vc = self] (object, errorDesc) in

                if let result = object as? NSDictionary {
                    
                    if let _ = result["scanning"] as? Bool {
                        vc.sortedWallets[0]["isRescanning"] = false
                        completion()
                        
                    } else if let dict = result["scanning"] as? NSDictionary {
                        if let progress = dict["progress"] as? Double {
                            let progressProcessed = progress * 100
                            vc.sortedWallets[0]["progress"] = "\(Int(progressProcessed))"
                            vc.sortedWallets[0]["isRescanning"] = true
                            completion()
                            
                        } else {
                            vc.sortedWallets[0]["isRescanning"] = false
                            completion()
                        }
                        
                    } else {
                        completion()

                    }

                } else {
                    vc.sortedWallets[0]["isRescanning"] = false
                    completion()

                }

            }
            
        } else {
            
            completion()
            
        }
        
    }
    
    private func reducedWalletName(name: String) -> String {
        let first = String(name.prefix(5))
        let last = String(name.suffix(5))
        return "\(first)*****\(last).dat"
        
    }
    
    private func reduceLabel(label: String) -> String {
        let first = String(label.prefix(10))
        let last = String(label.suffix(10))
        return "\(first)...\(last)"
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        walletTable.reloadData()
    }
    
    private func processUrHdkey(ur: String) {
        //"ur:crypto-hdkey/otadykaxhdclaevswfdmjpfswpwkahcywspsmndwmusoskprbbehetchsnpfcybbmwrhchspfxjeecaahdcxlnfszolyrtdlgmhfcnzectvwcmkbpsftgonbgauefsehgrqzdmvodizoweemtlaybakiylat"
        Encryption.getNode { (node, error) in
            guard node != nil else { return }
            var prefix = "0488ade4"
            if node!.network == "testnet" {
                prefix = "04358394"
            }
            let (isMaster, keyData, chainCode) = URHelper.urToHdkey(urString: ur)
            guard isMaster != nil, keyData != nil, chainCode != nil else { return }
            //guard keyData != nil else { return }
            //guard chainCode != nil else { return }
            if isMaster! {
                var base58String = "\(prefix)000000000000000000\(chainCode!)\(keyData!)"
                if let data = Data(base58String) {
                    let checksum = Encryption.checksum(Data(data))
                    base58String += checksum
                    if let rawData = Data(base58String) {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.xprv = Base58.encode([UInt8](rawData))
                            vc.performSegue(withIdentifier: "segueToCreateUrSuppliedKey", sender: vc)
                        }
                    }
                }
            }
        }
    }
    
    private func processUrSskr(ur: String) {
        if let shard = URHelper.urToShard(sskrUr: ur) {
            print("shard: \(shard)")
        }
    }
    
    private func processDescriptor(item: String) {
        spinner.addConnectingView(vc: self, description: "processing...")
        //ur:crypto-sskr/taadecgojlcybyadaoknuyjekszmztwppfjejyvacyghhfemgdoxsrneyt
        if item.hasPrefix("ur:crypto-sskr/") {
            processUrSskr(ur: item)
            
        } else if item.hasPrefix("ur:crypto-hdkey/") {
            processUrHdkey(ur: item)
            
        } else if item.hasPrefix("ur:crypto-seed/") {
            spinner.removeConnectingView()
            
            if let _ = URHelper.urToEntropy(urString: item).data {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.urToRecover = item
                    vc.performSegue(withIdentifier: "segueToUrRecovery", sender: vc)
                }
            } else {
                showAlert(vc: self, title: "Oops", message: "That does not look like a valid crypto-seed UR")
            }
            
        } else if let data = item.data(using: .utf8) {
            
            do {
                
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
            
                if let _ = dict["descriptor"] as? String {
                    
                    if let _ = dict["blockheight"] as? Int {
                        /// It is an Account Map.
                        Import.importAccountMap(accountMap: dict) { walletDict in
                            
                            if walletDict != nil {
                                DispatchQueue.main.async { [unowned vc = self] in
                                    vc.spinner.removeConnectingView()
                                    vc.walletToImport = walletDict!
                                    vc.walletName = walletDict!["name"] as! String
                                    vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                    
                                }
                            }
                        }
                    }
                    
                } else if let fingerprint = dict["xfp"] as? String {
                    /// It is a coldcard wallet skeleton file.
                    spinner.removeConnectingView()
                    DispatchQueue.main.async { [unowned vc = self] in
                        var alertStyle = UIAlertController.Style.actionSheet
                        if (UIDevice.current.userInterfaceIdiom == .pad) {
                          alertStyle = UIAlertController.Style.alert
                        }
                        
                        let alert = UIAlertController(title: "Import Coldcard Single-sig account?", message: TextBlurbs.chooseColdcardDerivationToImport(), preferredStyle: alertStyle)
                        
                        alert.addAction(UIAlertAction(title: "Native Segwit (BIP84, bc1)", style: .default, handler: { action in
                            vc.spinner.addConnectingView(vc: vc, description: "importing...")
                            let bip84Dict = dict["bip84"] as! NSDictionary
                            
                            Import.importColdCard(coldcardDict: bip84Dict, fingerprint: fingerprint) { (walletToImport) in
                                
                                if walletToImport != nil {
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        vc.spinner.removeConnectingView()
                                        vc.walletName = walletToImport!["name"] as! String
                                        vc.walletToImport = walletToImport!
                                        vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                        
                                    }
                                }
                            }
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Nested Segwit (BIP49, 3)", style: .default, handler: { action in
                            vc.spinner.addConnectingView(vc: vc, description: "importing...")
                            let bip49Dict = dict["bip49"] as! NSDictionary
                            
                            Import.importColdCard(coldcardDict: bip49Dict, fingerprint: fingerprint) { (walletToImport) in
                                
                                if walletToImport != nil {
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        vc.spinner.removeConnectingView()
                                        vc.walletName = walletToImport!["name"] as! String
                                        vc.walletToImport = walletToImport!
                                        vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                        
                                    }
                                }
                            }
                            
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Legacy (BIP44, 1)", style: .default, handler: { action in
                            vc.spinner.addConnectingView(vc: vc, description: "importing...")
                            let bip44Dict = dict["bip44"] as! NSDictionary
                            
                            Import.importColdCard(coldcardDict: bip44Dict, fingerprint: fingerprint) { (walletToImport) in
                                
                                if walletToImport != nil {
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        vc.spinner.removeConnectingView()
                                        vc.walletName = walletToImport!["name"] as! String
                                        vc.walletToImport = walletToImport!
                                        vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                                        
                                    }
                                }
                            }
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        alert.popoverPresentationController?.sourceView = vc.view
                        vc.present(alert, animated: true, completion: nil)
                        
                    }
                }
                
            } catch {
                /// It is not an Account Map.
                Import.importDescriptor(descriptor: item) { [unowned vc = self] walletDict in
                    
                    if walletDict != nil {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.walletToImport = walletDict!
                            vc.walletName = walletDict!["name"] as! String
                            vc.performSegue(withIdentifier: "goConfirmImport", sender: vc)
                            
                        }
                        
                    } else {
                        vc.spinner.removeConnectingView()
                        showAlert(vc: vc, title: "Error", message: "error importing that account")
                        
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segue.identifier
        switch id {
        case "segueToCreateUrSuppliedKey":
            if let vc = segue.destination as? ChooseWalletFormatViewController {
                vc.rootKeyFromUr = xprv
                vc.walletDoneBlock = { [unowned thisVc = self] result in
                    showAlert(vc: thisVc, title: "Success!", message: "Wallet created successfully!")
                    thisVc.isLoading = true
                    thisVc.refreshLocalDataAndBalanceForActiveAccount()
                }
            }
            
        case "segueToUrRecovery":
            if let vc = segue.destination as? WordRecoveryViewController {
                vc.urToRecover = urToRecover
            }
            
        case "goConfirmImport":
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                vc.walletNameHash = walletName
                vc.walletDict = walletToImport
            }
            
        case "goImport":
        if let vc = segue.destination as? ScannerViewController {
            vc.isImporting = true
            vc.returnStringBlock = { [unowned thisVc = self] item in
                thisVc.processDescriptor(item: item.lowercased())
            }
        }
            
        case "goToTools":
            if let vc = segue.destination as? WalletToolsViewController {
                vc.wallet = self.activeWallet
                vc.sweepDoneBlock = { [unowned thisVc = self] result in
                    thisVc.refreshLocalDataAndBalanceForActiveAccount()
                    showAlert(vc: thisVc, title: "Wallet Sweeped! 🤩", message: "We are refreshing your balances now.")
                }
                
                vc.refillDoneBlock = { [unowned thisVc = self] result in
                    thisVc.refreshLocalDataAndBalanceForActiveAccount()
                    showAlert(vc: thisVc, title: "Success!", message: "Keypool refilled 🤩")
                }
            }
            
        case "addWallet":
            if let vc = segue.destination as? ChooseWalletFormatViewController {
                vc.walletDoneBlock = { [unowned thisVc = self] result in
                    showAlert(vc: thisVc, title: "Success!", message: "Wallet created successfully!")
                    thisVc.isLoading = true
                    thisVc.refreshLocalDataAndBalanceForActiveAccount()
                }
                
                vc.recoverDoneBlock = { [unowned thisVc = self] result in
                    DispatchQueue.main.async {
                        thisVc.isLoading = true
                        thisVc.refreshLocalDataAndBalanceForActiveAccount()
                        showAlert(vc: thisVc, title: "Success!", message: "Wallet recovered 🤩!\n\nYour node is now rescanning the blockchain, balances may not show until the rescan completes.")
                    }
                }
            }
            
        default:
            break
        }
        
    }
    
}
