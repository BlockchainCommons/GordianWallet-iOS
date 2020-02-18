//
//  MainMenuViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit
import KeychainSwift

class MainMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, UINavigationControllerDelegate {
    
    var isRefreshingZero = Bool()
    var isRefreshingOne = Bool()
    var isRefreshingTwo = Bool()
    var existingNodeId = UUID()
    var torConnected = Bool()
    var sectionTwoLoaded = Bool()
    let imageView = UIImageView()
    let progressView = UIProgressView(progressViewStyle: .bar)
    var statusLabel = UILabel()
    var timer:Timer!
    var wallet:WalletStruct!
    var node:NodeStruct!
    var walletInfo:HomeStruct!
    let backView = UIView()
    let ud = UserDefaults.standard
    var hashrateString = String()
    var version = String()
    var incomingCount = Int()
    var outgoingCount = Int()
    var isPruned = Bool()
    var tx = String()
    var currentBlock = Int()
    var transactionArray = [[String:Any]]()
    @IBOutlet var mainMenu: UITableView!
    var refresher: UIRefreshControl!
    var connector:Connector!
    var connectingView = ConnectingView()
    let cd = CoreDataService()
    let enc = Encryption()
    let nodeLogic = NodeLogic()
    var nodes = [[String:Any]]()
    var uptime = Int()
    var initialLoad = Bool()
    var mempoolCount = Int()
    var walletDisabled = Bool()
    var torReachable = Bool()
    var progress = ""
    var difficulty = ""
    var feeRate = ""
    var size = ""
    var coldBalance = ""
    var unconfirmedBalance = ""
    var network = ""
    var p2pOnionAddress = ""
    var sectionZeroLoaded = Bool()
    var sectionOneLoaded = Bool()
    let spinner = UIActivityIndicatorView(style: .medium)
    var refreshButton = UIBarButtonItem()
    var dataRefresher = UIBarButtonItem()
    var wallets = NSArray()
    let label = UILabel()
    var existingWalletName = ""
    var fiatBalance = ""
    var sectionThreeLoaded = Bool()
    var infoHidden = Bool()
    var nodeInfoHidden = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        torConnected = false
        mainMenu.delegate = self
        tabBarController?.delegate = self
        navigationController?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationReceived(_:)), name: .torConnecting, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.foregroundNotificationReceived(_:)), name: .didEnterForeground, object: nil)
        mainMenu.tableFooterView = UIView(frame: .zero)
        initialLoad = true
        sectionZeroLoaded = false
        sectionOneLoaded = false
        sectionTwoLoaded = false
        sectionThreeLoaded = false
        isRefreshingOne = true
        setTitleView()
        configureRefresher()
        infoHidden = true
        nodeInfoHidden = true
        
        if ud.object(forKey: "firstTime") == nil {
            
            firstTimeHere()
            
        } else {
            
            showUnlockScreen()
            
        }
        
        enc.getNode { (node, error) in
            
            if !error && node != nil {
                
                self.node = node!
                self.existingNodeId = node!.id
                
                getActiveWalletNow() { (wallet, error) in
                    
                    if !error && wallet != nil {
                        
                        self.wallet = wallet
                        self.existingWalletName = wallet!.name
                        
                    }
                    
                }
                
            }
            
        }
                
    }
    
    @IBAction func goToSettings(_ sender: Any) {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            self.performSegue(withIdentifier: "settings", sender: self)
            
        }
        
    }
    
    
    @objc func notificationReceived(_ notification: Notification) {
        print("notificationReceived TorConnected")
        
        self.torConnected = true
        self.reloadSections([1])
        didAppear()

    }
    
    @objc func foregroundNotificationReceived(_ notification: Notification) {
        print("foreground NotificationReceived")
        
        if UIDevice.modelName != "iPhone 11 pro max" && UIDevice.modelName != "Simulator iPhone 11 pro max" {
            
            self.torConnected = false
            self.reloadSections([1])
            self.addStatusLabel(description: "     Initiating Tor tunnel...")
            
        } else {
            
            if !initialLoad {
                
                showAlert(vc: self, title: "Alert", message: "There is a known issue when refreshing the Tor connection on iPhone 11 Pro Max, we are working on a fix, in the meantime you may need to force close the app and reopen to reconnect Tor manually if you experience any issues.")
                
            }
            
        }

    }
    
    @IBAction func goToWallets(_ sender: Any) {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            self.performSegue(withIdentifier: "scanNow", sender: self)
            
        }
        
    }
    
    @objc func walletsSegue() {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            self.performSegue(withIdentifier: "goToWallets", sender: self)
            
        }
        
    }
    
    private func setTitleView() {
        
        let imageView = UIImageView(image: UIImage(named: "1024.png"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.mainMenu.translatesAutoresizingMaskIntoConstraints = true
        
        didAppear()
        
    }
    
    private func didAppear() {
        print("didappear")
                
        DispatchQueue.main.async {
            
            self.reloadSections([1])
            
            self.enc.getNode { (node, error) in
                
                if !error {
                                        
                    self.node = node!
                    
                    if self.torConnected {
                        
                        if self.initialLoad {
                            
                            self.initialLoad = false
                            self.reloadTableData()
                            
                        } else {
                            
                            getActiveWalletNow() { (w, error) in
                                                                
                                if !error && w != nil {
                                    
                                    self.wallet = w!
                                    
                                    if self.existingWalletName != w!.name && self.existingNodeId != node!.id {
                                        
                                        self.existingNodeId = node!.id
                                        self.refreshNow()
                                        
                                    } else if self.existingWalletName != w!.name {
                                        
                                        self.loadSectionZero()
                                        
                                    }
                                    
                                } else {
                                    
                                    if self.existingNodeId != node!.id {
                                        
                                        self.refreshNow()
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    self.addNode()
                    
                }
                
            }
                        
        }

    }
    
    @IBAction func lockButton(_ sender: Any) {
        
        showUnlockScreen()
        
    }
    
    private func setFeeTarget() {
        
        if ud.object(forKey: "feeTarget") == nil {
            
            ud.set(432, forKey: "feeTarget")
            
        }
        
    }
    
    private func showUnlockScreen() {
        
        let keychain = KeychainSwift()
        
        if keychain.get("UnlockPassword") != nil {
            
            DispatchQueue.main.async {
                
                self.performSegue(withIdentifier: "lockScreen", sender: self)
                
            }
            
        }
        
    }
    
    //MARK: Tableview Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if transactionArray.count > 0 {
            
            return 3 + transactionArray.count
            
        } else {
            
            return 4
            
        }
                
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    private func spinningCell() -> UITableViewCell {
        
        let blank = blankCell()
        let spinner = UIActivityIndicatorView()
        spinner.frame = CGRect(x: blank.contentView.frame.maxX, y: (blank.frame.height / 2) - 10, width: 20, height: 20)
        blank.addSubview(spinner)
        spinner.startAnimating()
        return blank
        
    }
    
    private func blankCell() -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = #colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
        return cell
        
    }
    
    private func descriptionCell(description: String) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = #colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
        cell.textLabel?.text = description
        cell.textLabel?.textColor = .lightGray
        return cell
        
    }
    
    private func defaultWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "singleSigCell", for: indexPath)
        cell.selectionStyle = .none
        
        let walletNameLabel = cell.viewWithTag(1) as! UILabel
        let coldBalanceLabel = cell.viewWithTag(2) as! UILabel
        let walletTypeLabel = cell.viewWithTag(4) as! UILabel
        let derivationPathLabel = cell.viewWithTag(5) as! UILabel
        let seedOnDeviceLabel = cell.viewWithTag(8) as! UILabel
        let dirtyFiatLabel = cell.viewWithTag(11) as! UILabel
        let infoButton = cell.viewWithTag(12) as! UIButton
        let deviceXprv = cell.viewWithTag(15) as! UILabel
        let deviceView = cell.viewWithTag(16)!
        let refreshingSpinner = cell.viewWithTag(23) as! UIActivityIndicatorView
        let nodeView = cell.viewWithTag(24)!
        let keysOnNodeDescription = cell.viewWithTag(25) as! UILabel
        
        nodeView.layer.cornerRadius = 8
        
        if isRefreshingZero {
            
            refreshingSpinner.alpha = 1
            refreshingSpinner.startAnimating()
            
        } else {
            
            refreshingSpinner.alpha = 0
            refreshingSpinner.stopAnimating()
        }
        
        deviceView.layer.cornerRadius = 8
        infoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
        self.coldBalance = walletInfo.coldBalance
                        
        if coldBalance == "" {
            
            self.coldBalance = "0"
            
        }
        
        dirtyFiatLabel.text = "\(self.fiatBalance)"
        
        if network == "test" {
            
            coldBalanceLabel.textColor = .systemOrange
            
        } else if network == "main" {
            
            coldBalanceLabel.textColor = .systemGreen
            
        }
        
        if wallet.type == "CUSTOM" {
            
            coldBalanceLabel.textColor = .systemGray
        }
                            
        if walletInfo.unconfirmed {
            
            coldBalanceLabel.text = self.coldBalance + " " + "BTC ⚠︎"
            coldBalanceLabel.textColor = .systemRed
            
        } else {
            
            coldBalanceLabel.text = self.coldBalance + " " + "BTC"
            
        }
        
        coldBalanceLabel.adjustsFontSizeToFitWidth = true
        
        walletTypeLabel.text = "Single Signature"
        seedOnDeviceLabel.text = "1 Signer on \(UIDevice.current.name)"
        
        if wallet.derivation.contains("84") {
            
            derivationPathLabel.text = "Native Segwit Account 0 (BIP84 \(wallet.derivation))"
            
        } else if wallet.derivation.contains("44") {
            
            derivationPathLabel.text = "Legacy Account 0 (BIP44 \(wallet.derivation))"
            
        } else if wallet.derivation.contains("49") {
            
            derivationPathLabel.text = "P2SH Nested Segwit Account 0 (BIP49 \(wallet.derivation))"
            
        }
        
        keysOnNodeDescription.text = "public keys \(wallet.derivation)/0 to /1999"
        deviceXprv.text = "xprv \(wallet.derivation)"
        walletNameLabel.text = "\(wallet.name).dat"
        
        return cell
        
    }
    
    private func multiWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "walletCell", for: indexPath)
        cell.selectionStyle = .none
        
        let walletNameLabel = cell.viewWithTag(1) as! UILabel
        let coldBalanceLabel = cell.viewWithTag(2) as! UILabel
        let walletTypeLabel = cell.viewWithTag(4) as! UILabel
        let derivationPathLabel = cell.viewWithTag(5) as! UILabel
        let backUpSeedLabel = cell.viewWithTag(6) as! UILabel
        let seedOnNodeLabel = cell.viewWithTag(7) as! UILabel
        let seedOnDeviceLabel = cell.viewWithTag(8) as! UILabel
        let dirtyFiatLabel = cell.viewWithTag(11) as! UILabel
        let infoButton = cell.viewWithTag(12) as! UIButton
        let deviceXprv = cell.viewWithTag(15) as! UILabel
        let deviceView = cell.viewWithTag(16)!
        let nodeXprv = cell.viewWithTag(17) as! UILabel
        let nodeView = cell.viewWithTag(18)!
        let offlineView = cell.viewWithTag(19)!
        let offlineXprvLabel = cell.viewWithTag(22) as! UILabel
        let refreshingSpinner = cell.viewWithTag(23) as! UIActivityIndicatorView
        
        if isRefreshingZero {
            
            refreshingSpinner.alpha = 1
            refreshingSpinner.startAnimating()
            
        } else {
            
            refreshingSpinner.alpha = 0
            refreshingSpinner.stopAnimating()
        }
        
        nodeView.layer.cornerRadius = 8
        offlineView.layer.cornerRadius = 8
        deviceView.layer.cornerRadius = 8
        
        infoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
        
        self.coldBalance = walletInfo.coldBalance
                        
        if coldBalance == "" {
            
            self.coldBalance = "0"
            
        }
        
        dirtyFiatLabel.text = "\(self.fiatBalance)"
        
        if network == "test" {
            
            coldBalanceLabel.textColor = .systemOrange
            
        } else if network == "main" {
            
            coldBalanceLabel.textColor = .systemGreen
            
        }
        
        if walletInfo.unconfirmed {
            
            coldBalanceLabel.text = self.coldBalance + " " + "BTC ⚠︎"
            coldBalanceLabel.textColor = .systemRed
            
        } else {
            
            coldBalanceLabel.text = self.coldBalance + " " + "BTC"
            
        }
        
        coldBalanceLabel.adjustsFontSizeToFitWidth = true
        
        walletTypeLabel.text = "2 of 3 multisig"
        backUpSeedLabel.text = "1 Seed Offline"
        seedOnNodeLabel.text = "1 Seedless \(node.label)"
        seedOnDeviceLabel.text = "1 Seed on \(UIDevice.current.name)"
        nodeView.alpha = 1
        offlineView.alpha = 1
        
        if wallet.derivation.contains("84") {
            
            derivationPathLabel.text = "Native Segwit Account 0 (BIP84 \(wallet.derivation))"
            
        } else if wallet.derivation.contains("44") {
            
            derivationPathLabel.text = "Legacy Account 0 (BIP44 \(wallet.derivation))"
            
        } else if wallet.derivation.contains("49") {
            
            derivationPathLabel.text = "P2SH Nested Segwit Account 0 (BIP49 \(wallet.derivation))"
            
        }
        
        nodeXprv.text = "private keys \(wallet.derivation)/0 to /1999"
        deviceXprv.text = "xprv \(wallet.derivation)"
        offlineXprvLabel.text = "xprv \(wallet.derivation)"
        
        walletNameLabel.text = "\(wallet.name).dat"
        
        return cell
        
    }
    
    private func customWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
     
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "coldStorageCell", for: indexPath)
        cell.selectionStyle = .none
        
        let descriptorParser = DescriptorParser()
        let descStruct = descriptorParser.descriptor(wallet.descriptor)
        
        let walletNameLabel = cell.viewWithTag(1) as! UILabel
        let coldBalanceLabel = cell.viewWithTag(2) as! UILabel
        let walletTypeLabel = cell.viewWithTag(4) as! UILabel
        let derivationPathLabel = cell.viewWithTag(5) as! UILabel
        let seedOnDeviceLabel = cell.viewWithTag(8) as! UILabel
        let dirtyFiatLabel = cell.viewWithTag(11) as! UILabel
        let infoButton = cell.viewWithTag(12) as! UIButton
        let refreshingSpinner = cell.viewWithTag(23) as! UIActivityIndicatorView
        let nodeView = cell.viewWithTag(24)!
        let watchIcon = cell.viewWithTag(25) as! UIImageView
        let keysOnNodeLabel = cell.viewWithTag(26) as! UILabel
        
        nodeView.layer.cornerRadius = 8
        
        if isRefreshingZero {
            
            refreshingSpinner.alpha = 1
            refreshingSpinner.startAnimating()
            
        } else {
            
            refreshingSpinner.alpha = 0
            refreshingSpinner.stopAnimating()
        }
        
        
        infoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
        
        self.coldBalance = walletInfo.coldBalance
        
        if coldBalance == "" {
            
            self.coldBalance = "0"
            
        }
        
        dirtyFiatLabel.text = "\(self.fiatBalance)"
        
        if network == "test" {
            
            coldBalanceLabel.textColor = .systemOrange
            
        } else if network == "main" {
            
            coldBalanceLabel.textColor = .systemGreen
            
        }
        
        if walletInfo.unconfirmed {
            
            coldBalanceLabel.text = self.coldBalance + " " + "BTC ⚠︎"
            coldBalanceLabel.textColor = .systemRed
            
        } else {
            
            coldBalanceLabel.text = self.coldBalance + " " + "BTC"
            
        }
        
        coldBalanceLabel.adjustsFontSizeToFitWidth = true
        
        if descStruct.isMulti {
            
            walletTypeLabel.text = descStruct.mOfNType
            
        } else {
            
            walletTypeLabel.text = "Single Signature"
            
        }
        
        if descStruct.isHot {
            
            seedOnDeviceLabel.text = "\(node.label) is Hot"
            keysOnNodeLabel.text = "2,000 private keys on \(node.label)"
            watchIcon.image = UIImage(systemName: "pencil.and.ellipsis.rectangle")
            cell.backgroundColor = #colorLiteral(red: 0.3451878428, green: 0.0757862553, blue: 0.05608722568, alpha: 1)
            nodeView.backgroundColor = #colorLiteral(red: 0.3920713854, green: 0.08131650479, blue: 0.04822516962, alpha: 1)
            
        } else {
            
            seedOnDeviceLabel.text = "\(node.label) is Cold"
            keysOnNodeLabel.text = "2,000 public keys on \(node.label)"
            watchIcon.image = UIImage(systemName: "eye")
            cell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
            nodeView.backgroundColor = #colorLiteral(red: 0, green: 0.1491778237, blue: 0.3231337072, alpha: 1)
            
        }
        
        
        derivationPathLabel.text = descStruct.format
        
        walletNameLabel.text = "\(wallet.name).dat"
        
        return cell
        
    }
    
    private func noActiveWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = descriptionCell(description: "⚠︎ No active wallet")
        let addWalletButton = UIButton()
        addWalletButton.frame = CGRect(x: cell.frame.maxX, y: (cell.frame.height / 2) - 10, width: 20, height: 20)
        addWalletButton.addTarget(self, action: #selector(addWallet), for: .touchUpInside)
        let image = UIImage(systemName: "plus")
        addWalletButton.setImage(image, for: .normal)
        addWalletButton.tintColor = .systemBlue
        cell.addSubview(addWalletButton)
        return cell
        
    }
    
    private func torCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "torCell", for: indexPath)
        cell.selectionStyle = .none
        let torStatusLabel = cell.viewWithTag(1) as! UILabel
        let p2pOnionLabel = cell.viewWithTag(3) as! UILabel
        let onionVersionLabel = cell.viewWithTag(4) as! UILabel
        let connectionStatusLabel = cell.viewWithTag(5) as! UILabel
        let v3address = cell.viewWithTag(6) as! UILabel
        let torActiveCircle = cell.viewWithTag(7) as! UIImageView
        let spinner = cell.viewWithTag(8) as! UIActivityIndicatorView
        let infoButton = cell.viewWithTag(9) as! UIButton
        
        spinner.startAnimating()
        spinner.alpha = 1
        infoButton.alpha = 0
        infoButton.addTarget(self, action: #selector(getNodeInfo(_:)), for: .touchUpInside)
        
        let onionAddress = (node.onionAddress.split(separator: "."))[0]
        
        if onionAddress.count == 16 {
            
            onionVersionLabel.text = "bitcoin core rpc hidden service version 2"
            
        } else if onionAddress.count == 56 {
            
            onionVersionLabel.text = "bitcoin core rpc hidden service version 3"
            
        }
        
        if isRefreshingOne {
            
            spinner.startAnimating()
            spinner.alpha = 1
            infoButton.alpha = 0
            
        } else {
            
            spinner.stopAnimating()
            spinner.alpha = 0
            infoButton.alpha = 1
            
        }
        
        let first10 = String(node.onionAddress.prefix(5))
        let last15 = String(node.onionAddress.suffix(15))
        v3address.text = "💻 ← \(first10)*****\(last15) → 📱"
        
        if sectionOneLoaded {
            
            connectionStatusLabel.text = "connected to \(node.label)"
            p2pOnionLabel.text = "P2P URL: \(p2pOnionAddress)"
            
        } else {
            
            connectionStatusLabel.text = "establishing connection to \(node.label)"
            p2pOnionLabel.text = "fetching network info from your node..."
            
        }
        
        torActiveCircle.image = UIImage(systemName: "circle.fill")
        
        if self.torConnected {
            
            if sectionOneLoaded && !isRefreshingOne {
                
                spinner.stopAnimating()
                spinner.alpha = 0
                infoButton.alpha = 1
                torStatusLabel.text = "connected"
                torActiveCircle.tintColor = .systemGreen
                
            } else if isRefreshingOne && !sectionOneLoaded {
                
                spinner.startAnimating()
                spinner.alpha = 1
                infoButton.alpha = 0
                torStatusLabel.text = "connecting..."
                torActiveCircle.tintColor = .systemOrange
                
            }
            
        } else {
            
            torStatusLabel.text = "connecting..."
            torActiveCircle.tintColor = .systemOrange
            connectionStatusLabel.text = "disconnected..."
            
            spinner.startAnimating()
            spinner.alpha = 1
            infoButton.alpha = 0
            
        }
        
        return cell
        
    }
    
    private func nodeCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "NodeInfo", for: indexPath)
        cell.selectionStyle = .none
        cell.isSelected = false
        
        let network = cell.viewWithTag(1) as! UILabel
        let pruned = cell.viewWithTag(2) as! UILabel
        let connections = cell.viewWithTag(3) as! UILabel
        let version = cell.viewWithTag(4) as! UILabel
        let hashRate = cell.viewWithTag(5) as! UILabel
        let sync = cell.viewWithTag(6) as! UILabel
        let blockHeight = cell.viewWithTag(7) as! UILabel
        let uptime = cell.viewWithTag(8) as! UILabel
        let mempool = cell.viewWithTag(10) as! UILabel
        let tor = cell.viewWithTag(11) as! UILabel
        let difficultyLabel = cell.viewWithTag(12) as! UILabel
        let sizeLabel = cell.viewWithTag(13) as! UILabel
        let feeRate = cell.viewWithTag(14) as! UILabel
        let isHot = cell.viewWithTag(15) as! UILabel
        let refreshingSpinner = cell.viewWithTag(16) as! UIActivityIndicatorView
        let infoButton = cell.viewWithTag(17) as! UIButton
        
        infoButton.addTarget(self, action: #selector(getWalletInfo(_:)), for: .touchUpInside)
        
        network.layer.cornerRadius = 6
        pruned.layer.cornerRadius = 6
        connections.layer.cornerRadius = 6
        version.layer.cornerRadius = 6
        hashRate.layer.cornerRadius = 6
        sync.layer.cornerRadius = 6
        blockHeight.layer.cornerRadius = 6
        uptime.layer.cornerRadius = 6
        mempool.layer.cornerRadius = 6
        tor.layer.cornerRadius = 6
        difficultyLabel.layer.cornerRadius = 6
        sizeLabel.layer.cornerRadius = 6
        feeRate.layer.cornerRadius = 6
        isHot.layer.cornerRadius = 6
        
        if isRefreshingTwo {
            
            refreshingSpinner.alpha = 1
            refreshingSpinner.startAnimating()
            
        } else {
            
            refreshingSpinner.alpha = 0
            refreshingSpinner.stopAnimating()
        }
        
        sizeLabel.text = "\(self.size) size"
        difficultyLabel.text = "\(self.difficulty) difficulty"
        
        if self.progress == "99%" {
            
            sync.text = "fully synced"
            
        } else {
            
            sync.text = "\(self.progress) synced"
            
        }
        
        feeRate.text = "\(self.feeRate) fee rate"
        
        isHot.textColor = .white
        
        if wallet != nil {
            
            isHot.alpha = 1
            
            if wallet.type == "DEFAULT" {
                
                //isHot.backgroundColor = .systemBlue
                isHot.text = "watch-only"
                isHot.textColor = .systemBlue
                
            } else if wallet.type == "MULTI" {
                
                //isHot.backgroundColor = .systemTeal
                isHot.text = "signer"
                isHot.textColor = .systemTeal
                
            } else if wallet.type == "CUSTOM" {
                
                //isHot.backgroundColor = .systemBlue
                isHot.text = "watch-only"
                
                let parser = DescriptorParser()
                let str = parser.descriptor(wallet.descriptor)
                
                if str.isHot {
                    
                    isHot.textColor = .systemTeal
                    
                } else {
                    
                    isHot.textColor = .systemBlue
                    
                }
                
            }
            
        } else {
            
            isHot.alpha = 0
            
        }
        
        if torReachable {
            
            tor.text = "Tor on"
            
        } else {
            
            tor.text = "Tor off"
            
        }
        
        mempool.text = "\(self.mempoolCount.withCommas()) mempool"
        
        if self.isPruned {
            
            pruned.text = "pruned"
            
        } else if !self.isPruned {
            
            pruned.text = "not pruned"
        }
        
        if self.network != "" {
            
            if self.network == "main" {
                
                network.text = "mainnet"
                network.textColor = .systemGreen
                
            } else if self.network == "test" {
                
                network.text = "⚠ testnet"
                network.textColor = .systemOrange
                
            } else {
                
                network.text = self.network
                
            }
            
        }
        
        blockHeight.text = "\(self.currentBlock.withCommas()) blocks"
        connections.text = "\(incomingCount) ↓ \(outgoingCount) ↑ connections"
        version.text = "Bitcoin Core v\(self.version)"
        hashRate.text = self.hashrateString + " " + "EH/s hashrate"
        uptime.text = "\(self.uptime / 86400) days uptime"
        
        return cell
        
    }
    
    private func transactionCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "MainMenuCell", for: indexPath)
        cell.selectionStyle = .none
        mainMenu.separatorColor = .darkGray
        
        let amountLabel = cell.viewWithTag(2) as! UILabel
        let confirmationsLabel = cell.viewWithTag(3) as! UILabel
        let labelLabel = cell.viewWithTag(4) as! UILabel
        let dateLabel = cell.viewWithTag(5) as! UILabel
        let infoButton = cell.viewWithTag(6) as! UIButton
        
        infoButton.addTarget(self, action: #selector(getTransaction(_:)), for: .touchUpInside)
        infoButton.restorationIdentifier = "\( indexPath.section)"
        amountLabel.alpha = 1
        confirmationsLabel.alpha = 1
        labelLabel.alpha = 1
        dateLabel.alpha = 1
        
        let dict = self.transactionArray[indexPath.section - 3]
                        
        confirmationsLabel.text = (dict["confirmations"] as! String) + " " + "confs"
        let label = dict["label"] as? String
        
        if label != "," {
            
            labelLabel.text = label
            
        } else if label == "," {
            
            labelLabel.text = ""
            
        }
        
        dateLabel.text = dict["date"] as? String
        
        if dict["abandoned"] as? Bool == true {
            
            cell.backgroundColor = UIColor.red
            
        }
        
        let amount = dict["amount"] as! String
        let confs = Int(dict["confirmations"] as! String)!
        
        if confs == 0 {
            
            confirmationsLabel.textColor = .systemRed
            
        } else if confs < 6 {
         
            confirmationsLabel.textColor = .systemYellow
            
        } else {
            
            confirmationsLabel.textColor = .systemGray
            
        }
        
        let selfTransfer = dict["selfTransfer"] as! Bool
        
        if amount.hasPrefix("-") {
        
            amountLabel.text = amount
            amountLabel.textColor = .darkGray
            labelLabel.textColor = .systemGray
            dateLabel.textColor = .systemGray
            
        } else {
            
            amountLabel.text = "+" + amount
            amountLabel.textColor = .lightGray
            labelLabel.textColor = .systemGray
            dateLabel.textColor = .systemGray
                                
        }
        
        if selfTransfer {
            
            amountLabel.text = (amountLabel.text!).replacingOccurrences(of: "+", with: "🔄")
            amountLabel.text = (amountLabel.text!).replacingOccurrences(of: "-", with: "🔄")
            
        }
        
        if confs == 0 {
            
            amountLabel.text = "⚠︎ \(amountLabel.text!)"
            
        }
        
        return cell
        
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        switch indexPath.section {
            
        case 0:
            
            if sectionZeroLoaded {
                
                let type = wallet.type
                
                switch type {
                    
                // Single sig wallet
                case "DEFAULT":
                    return defaultWalletCell(indexPath)
                    
                // Multi sig cell
                case "MULTI":
                    return multiWalletCell(indexPath)
                    
                // Custom cell (can be antyhing the user imports), to parse it we use the DescriptorParser.swift
                case "CUSTOM":
                    return customWalletCell(indexPath)
                    
                default:
                    return blankCell()
                }
                
            } else {
                
                if sectionOneLoaded && self.node != nil && self.wallet != nil && self.torConnected {
                    
                    return spinningCell()
                    
                } else if sectionOneLoaded && wallet == nil && self.torConnected {
                    
                    return noActiveWalletCell(indexPath)
                    
                } else {
                    
                    return blankCell()
                    
                }
                
            }
            
        case 1:
                        
            if node != nil {
                
                return torCell(indexPath)
                
            } else {
                
                return blankCell()
                
            }
            
        case 2:
            
            if sectionTwoLoaded {
                
                return nodeCell(indexPath)
                
            } else if sectionOneLoaded {
                    
                return spinningCell()
                    
            } else {
                
                return blankCell()
                
            }
                
        default:
            
            if !sectionThreeLoaded {
                
                if sectionZeroLoaded {
                    
                    return spinningCell()
                    
                } else if self.wallet == nil && sectionTwoLoaded {
                    
                    return descriptionCell(description: "⚠︎ No active wallet")
                    
                } else if self.wallet != nil && sectionTwoLoaded {
                    
                    return descriptionCell(description: "No transactions")
                    
                } else {
                    
                    return blankCell()
                    
                }
                                    
            } else {
                
                if transactionArray.count > 0 {
                    
                    return transactionCell(indexPath)
                    
                } else if self.wallet == nil {
                    
                    return descriptionCell(description: "⚠︎ No active wallet")
                    
                } else {
                    
                    return descriptionCell(description: "No transactions")
                    
                }
                                   
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
                    
        var sectionString = ""
        switch section {
        case 0: sectionString = "Wallet Info"
        case 1: sectionString = "Tor Status"
        case 2: sectionString = "Full Node Status"
        case 3: sectionString = "Transaction History"
        default: break}
        return sectionString
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = .systemGray
        (view as! UITableViewHeaderFooterView).textLabel?.alpha = 1
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
        case 0: return 30
        case 1, 2, 3: return 20
        default: return 5
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
        case 0:
                        
            if sectionZeroLoaded {
                
                if wallet.type == "MULTI" {
                    
                    if infoHidden {
                        
                        return 138
                        
                    } else {
                       
                        return 290
                        
                    }
                    
                } else if wallet.type == "CUSTOM" {
                    
                    if infoHidden {
                    
                        return 138
                        
                    } else {
                        
                        return 188
                        
                    }
                    
                } else {
                    
                    if infoHidden {
                    
                        return 138
                        
                    } else {
                        
                        return 255
                        
                    }
                    
                }

            } else {

                return 47

            }
            
        case 1:
            
            if self.node != nil {
                
                if nodeInfoHidden {
                    
                    return 57
                    
                } else {
                    
                    return 129
                    
                }
                
            } else {
                
                return 47
                
            }
                        
        case 2:
            
            if sectionTwoLoaded {
                
                return 192
                
            } else {
                
                return 47
                
            }
            
        default:
            
            if sectionThreeLoaded {
                
                return 80
                
            } else {
                
                return 47
                
            }
            
        }
        
    }
    
    @objc func getWalletInfo(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
            if self.infoHidden {
                
                self.infoHidden = false
                
            } else {
                
                self.infoHidden = true
                
            }
            
            self.reloadSections([0])
                        
        }
        
    }
    
    @objc func getNodeInfo(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
            if self.nodeInfoHidden {
                
                self.nodeInfoHidden = false
                
            } else {
                
                self.nodeInfoHidden = true
                
            }
            
            self.reloadSections([0])
                        
        }
        
    }
    
    private func updateWalletMetaData(wallet: WalletStruct) {
        
        cd.updateEntity(id: wallet.id, keyToUpdate: "lastBalance", newValue: Double(self.walletInfo.coldBalance)!, entityName: .wallets) {
            
            if !self.cd.errorBool {
                
                print("succesfully updated lastBalance")
                
            } else {
                
                print("error saving lastBalance")
                
            }
            
        }
        
        cd.updateEntity(id: wallet.id, keyToUpdate: "lastUsed", newValue: Date(), entityName: .wallets) {
            
            if !self.cd.errorBool {
                
                print("succesfully updated lastUsed")
                
            } else {
                
                print("error saving lastUsed")
                
            }
            
        }
        
    }
    
    private func updateLabel(text: String) {
        
        DispatchQueue.main.async {
            
            self.statusLabel.text = text
            
        }
        
    }
    
    private func loadSectionZero() {
        
        self.isRefreshingZero = true
        self.reloadSections([0])
        self.updateLabel(text: "     Getting wallet info...")
                        
        nodeLogic.wallet = self.wallet
        self.existingWalletName = self.wallet.name
        nodeLogic.walletDisabled = false
        nodeLogic.loadSectionZero() {
            
            if self.nodeLogic.errorBool {
                
                self.sectionZeroLoaded = false
                self.removeStatusLabel()
                self.isRefreshingZero = false
                self.reloadSections([0])
                displayAlert(viewController: self, isError: true, message: self.nodeLogic.errorDescription)
                
            } else {
                
                let dict = self.nodeLogic.dictToReturn
                self.walletInfo = HomeStruct(dictionary: dict)
                self.updateWalletMetaData(wallet: self.wallet)
                self.sectionZeroLoaded = true
                self.isRefreshingZero = false
                self.reloadSections([0, 3])
                
                DispatchQueue.main.async {
                    
                    let impact = UIImpactFeedbackGenerator()
                    impact.impactOccurred()
                    
                }
                
                self.getDirtyFiatBalance()
                self.loadSectionThree()
                
            }
            
        }
        
    }
    
    private func loadSectionOne() {
        
        if self.node != nil {
            
            updateLabel(text: "     Getting Tor network data...")
            nodeLogic.loadSectionOne {
                
                if !self.nodeLogic.errorBool {
                    
                    let s = HomeStruct(dictionary: self.nodeLogic.dictToReturn)
                    self.p2pOnionAddress = s.p2pOnionAddress
                    self.version = s.version
                    self.torReachable = s.torReachable
                    
                    self.sectionOneLoaded = true
                    self.isRefreshingOne = false
                    
                    if self.wallet != nil {
                        
                        self.reloadSections([1, 0])
                        self.loadSectionZero()
                        
                    } else {
                        
                        self.reloadSections([1, 2])
                        self.loadSectionTwo()
                                                                        
                    }
                    
                } else {
                    
                    self.sectionOneLoaded = false
                    self.removeStatusLabel()
                    self.isRefreshingOne = false
                    self.reloadSections([1])
                    
                    displayAlert(viewController: self,
                                 isError: true,
                                 message: self.nodeLogic.errorDescription)
                                        
                }
                
            }
            
        }
        
    }
    
    private func loadSectionTwo() {
        print("loadSectionTwo")
        
        self.isRefreshingTwo = true
        self.reloadSections([2])
        self.updateLabel(text: "     Getting Full Node data...")
        
        nodeLogic.wallet = wallet
        nodeLogic.walletDisabled = walletDisabled
        nodeLogic.loadSectionTwo() {
            
            if self.nodeLogic.errorBool {
                
                self.sectionTwoLoaded = false
                self.removeStatusLabel()
                self.isRefreshingTwo = false
                self.reloadSections([2])
                displayAlert(viewController: self, isError: true, message: self.nodeLogic.errorDescription)
                
            } else {
                
                let dict = self.nodeLogic.dictToReturn
                let str = HomeStruct(dictionary: dict)
                self.feeRate = str.feeRate
                self.mempoolCount = str.mempoolCount
                self.network = str.network
                
                if self.network == "main" {
                    
                    self.cd.updateEntity(id: self.node.id, keyToUpdate: "network", newValue: "mainnet", entityName: .nodes) {}
                    
                } else if self.network == "test" {
                    
                    self.cd.updateEntity(id: self.node.id, keyToUpdate: "network", newValue: "testnet", entityName: .nodes) {}
                    
                }
                
                self.size = str.size
                self.difficulty = str.difficulty
                self.progress = str.progress
                self.isPruned = str.pruned
                self.incomingCount = str.incomingCount
                self.outgoingCount = str.outgoingCount
                self.hashrateString = str.hashrate
                self.uptime = str.uptime
                self.currentBlock = str.blockheight
                self.sectionTwoLoaded = true
                
                self.isRefreshingTwo = false
                
                DispatchQueue.main.async {
                    
                    if self.wallet == nil {
                        
                        self.reloadSections([0, 2, 3])
                        
                    } else {
                        
                        self.reloadSections([2, 0])
                        
                    }
                    
                    let impact = UIImpactFeedbackGenerator()
                    impact.impactOccurred()
                    self.removeStatusLabel()
                    
                }
                
            }
            
        }
        
    }
    
    private func loadSectionThree() {
        
        updateLabel(text: "     Getting transactions...")
        
        nodeLogic.wallet = wallet
        nodeLogic.walletDisabled = walletDisabled
        nodeLogic.loadSectionThree() {
            
            if self.nodeLogic.errorBool {
                
                self.sectionThreeLoaded = false
                self.removeStatusLabel()
                
                displayAlert(viewController: self,
                             isError: true,
                             message: self.nodeLogic.errorDescription)
                
            } else {
                
                self.transactionArray.removeAll()
                self.transactionArray = self.nodeLogic.arrayToReturn.reversed()
                self.sectionThreeLoaded = true
                                
                DispatchQueue.main.async {
                    
                    self.mainMenu.reloadData()
                    let impact = UIImpactFeedbackGenerator()
                    impact.impactOccurred()
                    self.loadSectionTwo()
                    
                }
                
            }
            
        }
        
    }
    
    @objc func getTransaction(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        let index = Int(sender.restorationIdentifier!)!
        let selectedTx = self.transactionArray[index - 3]
        let txID = selectedTx["txID"] as! String
        self.tx = txID
        UIPasteboard.general.string = txID
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            self.performSegue(withIdentifier: "getTransaction", sender: self)
            
        }
        
    }
    
    private func getDirtyFiatBalance() {
        
        let converter = FiatConverter()
        
        func getResult() {
            
            if !converter.errorBool {
                
                let rate = converter.fxRate
                
                guard let coldDouble = Double(self.coldBalance.replacingOccurrences(of: ",", with: "")) else {
                    
                    return
                    
                }
                
                let formattedColdDouble = ((coldDouble * rate).rounded()).withCommas()
                self.fiatBalance = "﹩\(formattedColdDouble) USD"
                self.reloadSections([0])
                
            }
            
        }
        
        converter.getFxRate(completion: getResult)
    }
    
    //MARK: User Interface
    
    private func addStatusLabel(description: String) {
        //Matshona Dhliwayo — 'Great things take time; that is why seeds persevere through rocks and dirt to bloom.'
        
        DispatchQueue.main.async {
            
            self.statusLabel.removeFromSuperview()
            self.statusLabel.frame = CGRect(x: 0, y: -50, width: self.view.frame.width, height: 50)
            self.statusLabel.backgroundColor = .black
            self.statusLabel.textAlignment = .left
            self.statusLabel.textColor = .lightGray
            self.statusLabel.font = .systemFont(ofSize: 12)
            self.statusLabel.text = description
            self.view.addSubview(self.statusLabel)
            
            UIView.animate(withDuration: 0.5, animations: {
                
                self.statusLabel.frame = CGRect(x: 16, y: self.navigationController!.navigationBar.frame.maxY + 5, width: self.view.frame.width - 32, height: 13)
                self.mainMenu.frame = CGRect(x: 0, y: self.statusLabel.frame.maxY, width: self.mainMenu.frame.width, height: self.mainMenu.frame.height)
                
            })
            
        }
        
    }
    
    private func removeStatusLabel() {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.5, animations: {
                
                self.statusLabel.frame.origin.y = -50
                self.mainMenu.frame = CGRect(x: 0, y: 0, width: self.mainMenu.frame.width, height: self.view.frame.height)
                
            }) { (_) in
                
                self.statusLabel.removeFromSuperview()
                
            }
            
        }
        
    }
    
    @objc func addWallet() {

        let impact = UIImpactFeedbackGenerator()

        DispatchQueue.main.async {

            impact.impactOccurred()

        }

        if self.torConnected {
            
            self.tabBarController?.selectedIndex = 1

        } else {

            showAlert(vc: self, title: "Tor not connected", message: "You need to be connected to a node over tor in order to create a wallet")

        }

    }
    
    private func configureRefresher() {
        
        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.white
        refresher.attributedTitle = NSAttributedString(string: "refresh data", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        refresher.addTarget(self, action: #selector(self.refreshNow), for: UIControl.Event.valueChanged)
        mainMenu.addSubview(refresher)
        
    }
    
    //MARK: User Actions
    
    @objc func closeConnectingView() {
        
        DispatchQueue.main.async {
            self.connectingView.removeConnectingView()
        }
        
    }
    
    @objc func refreshNow() {
        print("refresh")
        
        self.isRefreshingOne = true
        self.mainMenu.reloadSections(IndexSet(arrayLiteral: 1), with: .fade)
        self.reloadTableData()
        
    }
    
    private func addNode() {
        
        if ud.object(forKey: "showIntro") == nil {
            
            DispatchQueue.main.async {
                
                self.performSegue(withIdentifier: "showIntro", sender: self)
                
            }
            
        } else {
            
            DispatchQueue.main.async {
                
                self.performSegue(withIdentifier: "scanNow", sender: self)
                
            }
            
        }
        
    }
    
    private func reloadTableData() {
        
        self.refresher.endRefreshing()
        self.addStatusLabel(description: "     Connecting Tor...")
        
        getActiveWalletNow() { (w, error) in
                
            if !error {
                
                self.loadSectionOne()
                                
            } else {
                                
                if self.node != nil {
                    
                     self.loadSectionOne()
                    
                } else {
                    
                    self.isRefreshingOne = false
                    self.removeStatusLabel()
                    displayAlert(viewController: self, isError: true, message: "no active node, please go to node manager and activate one")
                    
                }
                
            }
            
        }
        
    }
    
    private func reloadSections(_ sections: [Int]) {
        
        DispatchQueue.main.async {
            
            self.mainMenu.reloadSections(IndexSet(sections), with: .fade)
            
        }
        
    }
    
    private func nodeJustAdded() {
        print("nodeJustAdded")
        
        self.enc.getNode { (node, error) in
            
            if !error && node != nil {
                
                self.node = node!
                self.reloadSections([1])
                
                if !self.torConnected {
                    
                    TorClient.sharedInstance.start {
                        
                        self.didAppear()
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "goToWallets":
            
            if let vc = segue.destination as? WalletsViewController {
                
                vc.node = self.node
                
            }
            
        case "getTransaction":
            
            if let vc = segue.destination as? TransactionViewController {
                
                vc.txid = tx
                
            }
            
        case "scanNow":
            
            if let vc = segue.destination as? ScannerViewController {
                
                vc.onDoneBlock = { result in
                    
                    self.nodeJustAdded()
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }
    
    //MARK: Helpers
    
    private func firstTimeHere() {
        
        setFeeTarget()
        
        let firstTime = FirstTime()
        firstTime.firstTimeHere { (success) in
            
            if success {
                
                self.showUnlockScreen()
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "Something very wrong has happened... Please delete the app and try again.")
                
            }
            
        }
        
    }
    
}

extension Double {
    
    func withCommas() -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return numberFormatter.string(from: NSNumber(value:self))!
        
    }
    
}
