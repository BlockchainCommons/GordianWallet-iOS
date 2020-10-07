//
//  MainMenuViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, UINavigationControllerDelegate, OnionManagerDelegate, UIDocumentPickerDelegate {
    
    weak var nodeLogic = NodeLogic.sharedInstance
    weak var mgr = TorClient.sharedInstance
    weak var ud = UserDefaults.standard
    var wallet:WalletStruct!
    var node:NodeStruct!
    var walletInfo:HomeStruct!
    var nodeInfo:HomeStruct!
    var torInfo:HomeStruct!
    var scanningNode = Bool()
    var showFiat = Bool()
    var walletExists = Bool()
    var bootStrapping = Bool()
    var showNodeInfo = Bool()
    var isRefreshingWalletData = Bool()
    var isRefreshingTorData = Bool()
    var isRefreshingNodeData = Bool()
    var torConnected = Bool()
    var nodeSectionLoaded = Bool()
    var transactionsSectionLoaded = Bool()
    var infoHidden = Bool()
    var torInfoHidden = Bool()
    var walletSectionLoaded = Bool()
    var torSectionLoaded = Bool()
    var initialLoad = Bool()
    var torCellIndex = Int()
    var walletCellIndex = Int()
    var nodeCellIndex = Int()
    var transactionCellIndex = Int()
    var existingNodeId = UUID()
    var existingWalletName = ""
    var statusLabel = UILabel()
    var refresher: UIRefreshControl!
    var connectingView = ConnectingView()
    var nodes = [[String:Any]]()
    var transactionArray = [[String:Any]]()
    var coldcard = [String:Any]()
    let localeConfig = LocaleConfig()
    let priceServer = PriceServer()
    var deviceWords = ""
    var offlineWords = ""
    var tx = ""
    var unsignedPsbt = ""
    var signedRawTx = ""
    var walletNameHash = ""
    var accountMap = ""
    var alertStyle = UIAlertController.Style.actionSheet
    @IBOutlet var mainMenu: UITableView!
    @IBOutlet var sponsorView: UIView!
    @IBOutlet weak var notificationIcon: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showFiat = false
        torConnected = false
        mainMenu.delegate = self
        mainMenu.alpha = 0
        tabBarController?.delegate = self
        navigationController?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(torBootStrapping(_:)), name: .didStartBootstrappingTor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCompleteOnboarding(_:)), name: .didCompleteOnboarding, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showIndexWarning), name: .refillKeypool, object: nil)
        sponsorView.alpha = 0
        initialLoad = true
        walletSectionLoaded = false
        torSectionLoaded = false
        nodeSectionLoaded = false
        transactionsSectionLoaded = false
        isRefreshingTorData = true
        setTitleView()
        configureRefresher()
        infoHidden = true
        torInfoHidden = true
        showNodeInfo = false
                
        Encryption.getNode { [unowned vc = self] (node, error) in
            if !error && node != nil {
                vc.node = node!
                vc.existingNodeId = node!.id
                getActiveWalletNow() { (wallet, error) in
                    if !error && wallet != nil {
                        vc.wallet = wallet
                        vc.existingWalletName = wallet!.name!
                    }
                }
            }
        }
        
        localeConfig.onStartup()
        priceServer.onStartup()
        print(priceServer.createSpotBitURL())
        
        bootStrapping = true
        addStatusLabel(description: "     Bootstrapping Tor...")
        reloadSections([torCellIndex])
        
        if mgr?.state != .started && mgr?.state != .connected && mgr?.state != .refreshing  {
            mgr?.start(delegate: self)
        }
        
        firstTimeHere()
        checkIfoutdated()
        
        if (UIDevice.current.userInterfaceIdiom == .pad) {
          alertStyle = UIAlertController.Style.alert
        }
    }
    
    private func checkIfoutdated() {
        CoreDataService.retrieveEntity(entityName: .wallets) { [unowned vc = self] (wallets, errorDescription) in
            if wallets != nil {
                var isOutdated = true
                for (i, wallet) in wallets!.enumerated() {
                    let walletStruct = WalletStruct(dictionary: wallet)
                    if walletStruct.xprvs != nil {
                        isOutdated = false
                    }
                    if i + 1 == wallets!.count {
                        if isOutdated {
                            showAlert(vc: vc, title: "Important!", message: "We recently made some fundamental changes to how the app stores seeds and derives signing keys, this means the app will no longer be able to sign for outdated accounts. Make sure you back up all your account info, then utilize both kill switches, force quit and reopen the app then recover your existing accounts. If you have only just downloaded the app and have not yet created any accounts then this message can be ignored.")
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func goToNotificationCenter(_ sender: Any) {
        goToNotifications()
    }
    
    private func goToNotifications() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "showNotificationCenter", sender: vc)
        }
    }
    
    @IBAction func uploadFile(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Upload a file?", message: TextBlurbs.uploadAFileMessage(), preferredStyle: vc.alertStyle)
            
            alert.addAction(UIAlertAction(title: "Upload", style: .default, handler: { [unowned vc = self] action in
                let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
                documentPicker.delegate = vc
                documentPicker.modalPresentationStyle = .formSheet
                vc.present(documentPicker, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == .import {
            do {
                let data = try Data(contentsOf: url.absoluteURL)
                let psbt = data.base64EncodedString()
                do {
                    let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                    if let _ = dict["chain"] as? String {
                        /// We know its a coldcard skeleton import
                        importColdCardSingleSig(dict: dict)
                    } else if let _ = dict["p2wsh_deriv"] as? String, let _ = dict["xfp"] as? String {
                        /// It is most likely a multi-sig wallet export
                        coldcardTwoOfThree(importedDict: dict)
                    }
                } catch {
                    signPsbtAlert(psbt: psbt)
                }
            } catch {
                connectingView.removeConnectingView()
                showAlert(vc: self, title: "Error", message: "That is not a valid psbt or Coldcard export")
            }
        }
    }
    
    private func importColdCardSingleSig(dict: [String:Any]) {
        
        func importColdcardSkeleton(walletToImport: [String:Any]) {
            DispatchQueue.main.async { [unowned vc = self] in
                vc.connectingView.removeConnectingView()
                vc.walletNameHash = walletToImport["name"] as! String
                vc.coldcard = walletToImport
                vc.performSegue(withIdentifier: "segueToConfirmImport", sender: vc)
            }
        }
        
        func importSingleSigColdCard(derivation: String) {
            connectingView.addConnectingView(vc: self, description: "importing...")
            let singleSigDict = dict[derivation] as! NSDictionary
            let fingerprint = dict["xfp"] as! String
            Import.importColdCard(coldcardDict: singleSigDict, fingerprint: fingerprint) { (walletToImport) in
                if walletToImport != nil {
                    importColdcardSkeleton(walletToImport: walletToImport!)
                }
            }
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Import Coldcard Single-sig account?", message: TextBlurbs.chooseColdcardDerivationToImport(), preferredStyle: vc.alertStyle)
            
            alert.addAction(UIAlertAction(title: "Native Segwit (BIP84, bc1)", style: .default, handler: { action in
                importSingleSigColdCard(derivation: "bip84")
            }))
            
            alert.addAction(UIAlertAction(title: "Nested Segwit (BIP49, 3)", style: .default, handler: { action in
                importSingleSigColdCard(derivation: "bip49")
            }))
            
            alert.addAction(UIAlertAction(title: "Legacy (BIP44, 1)", style: .default, handler: { action in
                importSingleSigColdCard(derivation: "bip44")
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func coldcardTwoOfThree(importedDict: [String:Any]) {
        
        func saveColdCardMultiSigWallet(coldCardWallet: [String:Any], w: WalletStruct) {
            CoreDataService.saveEntity(dict: coldCardWallet, entityName: .wallets) { (success, errorDescription) in
                if success {
                    /// Segue to confirmation
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.connectingView.removeConnectingView()
                        let recoveryQr = ["descriptor":w.descriptor, "blockheight":w.blockheight,"label":"COLDCARD 2 of 3"] as [String : Any]
                        if let json = recoveryQr.json() {
                            vc.accountMap = json
                        }
                        vc.coldcard = coldCardWallet
                        vc.performSegue(withIdentifier: "segueToColdcardMusigCreated", sender: vc)
                    }
                }
            }
        }
        
        func saveColdCardMultiSigSeed(dict: [String:Any], coldCardWallet: [String:Any], w: WalletStruct) {
            CoreDataService.saveEntity(dict: dict, entityName: .seeds) { [unowned vc = self] (success, errorDescription) in
                if success {
                    saveColdCardMultiSigWallet(coldCardWallet: coldCardWallet, w: w)
                } else {
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "There was an error saving your Coldcard multisig seed.")
                }
            }
        }
        
        func encryptDeviceSeed(coldcardWallet: [String:Any], offline_words: String, device_words: String, w: WalletStruct) {
            let deviceSeedData = device_words.dataUsingUTF8StringEncoding
            Encryption.encryptData(dataToEncrypt: deviceSeedData) { [unowned vc = self] (encryptedData, error) in
                if encryptedData != nil {
                    let d = ["seed":encryptedData!, "birthdate": Date(), "id":UUID()] as [String : Any]
                    vc.deviceWords = device_words
                    vc.offlineWords = offline_words
                    saveColdCardMultiSigSeed(dict: d, coldCardWallet: coldcardWallet, w: w)
                } else {
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "There was an error encrypting your Coldcard multisig wallet.")
                }
            }
        }
        
        func createMultiSigColdcard(coldcardWallet: [String:Any], offline_words: String, device_words: String) {
            let creator = CreateMultiSigWallet.sharedInstance
            let w = WalletStruct(dictionary: coldcardWallet)
            creator.createNodeWatchOnly(primDesc: w.descriptor, changeDesc: w.changeDescriptor) { [unowned vc = self] (success, error) in
                if success {
                    encryptDeviceSeed(coldcardWallet: coldcardWallet, offline_words: offline_words, device_words: device_words, w: w)
                } else {
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "There was an error creating your Coldcard multisig wallet.")
                }
            }
        }
        
        func importMultiSigColdcard() {
            Import.importColdCardMultiSig(coldcardDict: importedDict) { [unowned vc = self] (coldcardWallet, offline_words, device_words) in
                if coldcardWallet != nil && offline_words != nil && device_words != nil {
                    createMultiSigColdcard(coldcardWallet: coldcardWallet!, offline_words: offline_words!, device_words: device_words!)
                } else {
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "There was an error importing your Coldcard multisig wallet.")
                }
            }
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Create a 2 of 3 multi-sig wallet with your Coldcard?", message: "", preferredStyle: vc.alertStyle)
            
            alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { action in
                vc.connectingView.addConnectingView(vc: vc, description: "creating...")
                importMultiSigColdcard()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func signPsbtAlert(psbt: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Sign PSBT?", message: TextBlurbs.signPsbtMessage(), preferredStyle: vc.alertStyle)
            
            alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { action in
                vc.connectingView.addConnectingView(vc: vc, description: "signing psbt")
                vc.signPSBT(psbt: psbt)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func signPSBT(psbt: String) {
        PSBTSigner.sign(psbt: psbt) { [unowned vc = self] (success, psbt, rawTx) in
            if success {
                if psbt != nil {
                    vc.connectingView.removeConnectingView()
                    vc.unsignedPsbt = psbt!
                } else if rawTx != nil {
                    vc.connectingView.removeConnectingView()
                    vc.signedRawTx = rawTx!
                }
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.performSegue(withIdentifier: "goConfirmPsbtSegue", sender: vc)
                }
            } else {
                vc.connectingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "PSBT signing failed")
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Cancelled")
    }
    
    
    @IBAction func goToSettings(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "settings", sender: self)
        }
    }
    
    @objc func didCompleteOnboarding(_ notification: Notification) {
        didAppear()
    }
    
    @objc func torBootStrapping(_ notification: Notification) {
        bootStrapping = true
        addStatusLabel(description: "     Bootstrapping Tor...")
        reloadSections([torCellIndex])
    }
    
    @IBAction func goToWallets(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "scanNow", sender: vc)
        }
    }
    
    @objc func walletsSegue() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "goToWallets", sender: vc)
        }
    }
    
    private func setTitleView() {
        let imageView = UIImageView(image: UIImage(named: "1024.jpg"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        imageView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(logoTapped))
        imageView.addGestureRecognizer(tapRecognizer)
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if ud?.object(forKey: "feeTarget") ==  nil {
            ud?.set(432, forKey: "feeTarget")
        }
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                vc.wallet = wallet!
            }
        }
        #if DEBUG
        didAppear()
        #else
        if KeyChain.getData("userIdentifier") == nil || KeyChain.getData("acceptedDisclaimer") == nil {
            showIntro()
        } else {
            didAppear()
        }
        #endif
    }
    
    private func showIntro() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "showIntro", sender: vc)
        }
    }
    
    @objc func logoTapped() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "goDonate", sender: vc)
        }
    }
    
    private func didAppear() {
        
        DispatchQueue.main.async {
            Encryption.getNode { [unowned vc = self] (node, error) in
                if !error && node != nil {
                    vc.node = node!
                    if vc.torConnected {
                        if vc.initialLoad {
                            vc.initialLoad = false
                            vc.reloadTableData()
                        } else {
                            getActiveWalletNow() { (w, error) in
                                if !error && w != nil {
                                    vc.wallet = w!
                                    if vc.existingWalletName != w!.name && vc.existingNodeId != node!.id {
                                        /// user switched to a different wallet on a different node
                                        vc.existingNodeId = node!.id
                                        vc.refreshNow()
                                    } else if vc.existingWalletName != w!.name {
                                        /// user switched wallets
                                        vc.loadWalletData()
                                    }
                                } else {
                                    vc.existingWalletName = ""
                                    vc.wallet = nil
                                    vc.refreshNow()
//                                    if vc.existingNodeId != node!.id {
//                                        /// this means the node was changed in node manager or a wallet on a different node was activated
//                                        vc.refreshNow()
//                                    } else if vc.existingWalletName != "" {
//                                        /// this means the wallet was deleted without getting deactivated first, so we just force refresh
//                                        /// and manually set the wallet to nil
//                                        vc.wallet = nil
//                                        vc.refreshNow()
//                                    }
//                                    vc.existingWalletName = ""
                                }
                            }
                        }
                    }
                } else {
                    vc.scanningNode = true
                    vc.addNode()
                }
            }
        }
    }
    
    @objc func showIndexWarning() {
        if wallet != nil {
            var message = ""
            let actionTitle = "Refill keypool"
            var alertAction: (() -> Void)!
            if self.wallet.type == "MULTI" {
                message = TextBlurbs.refillMultiSigWarningMessage(keysRemainging: self.wallet.maxRange - self.wallet.index)
                alertAction = {
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.performSegue(withIdentifier: "refillMsigFromHome", sender: vc)
                    }
                }
            } else {
                message = TextBlurbs.refillSingleSigWarningMessage(keysRemainging: self.wallet.maxRange - self.wallet.index)
                alertAction = { [unowned vc = self] in
                    vc.connectingView.addConnectingView(vc: vc.tabBarController!, description: "Refilling the keypool")
                    let singleSig = RefillSingleSig()
                    singleSig.refill(wallet: vc.wallet) { (success, error) in
                        if success {
                            vc.connectingView.removeConnectingView()
                            showAlert(vc: vc, title: "Keypool refilled ✓", message: "We are now refreshing your account data.")
                            vc.loadWalletData()
                        } else {
                            vc.connectingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error!", message: "There was an error refilling the keypool: \(String(describing: error))")
                        }
                    }
                }
            }
            DispatchQueue.main.async { [unowned vc = self] in
                let alert = UIAlertController(title: "Warning!", message: message, preferredStyle: vc.alertStyle)
                
                alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { action in
                    alertAction()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                alert.popoverPresentationController?.sourceView = vc.view
                vc.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: Tableview Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            if transactionArray.count == 0 {
                return 1
            } else {
                return transactionArray.count
            }
        } else {
            return 1
        }
        
    }
    
    private func spinningCell() -> UITableViewCell {
        let blank = blankCell()
        let spinner = UIActivityIndicatorView()
        spinner.frame = CGRect(x: mainMenu.frame.maxX - 80, y: (blank.frame.height / 2) - 10, width: 20, height: 20)
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
    
    private func noActiveWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = descriptionCell(description: "⚠︎ No active account")
        let addWalletButton = UIButton()
        addWalletButton.frame = CGRect(x: mainMenu.frame.maxX - 80, y: (cell.frame.height / 2) - 10, width: 20, height: 20)
        addWalletButton.addTarget(self, action: #selector(addWallet), for: .touchUpInside)
        let image = UIImage(systemName: "plus")
        addWalletButton.setImage(image, for: .normal)
        addWalletButton.tintColor = .systemTeal
        cell.addSubview(addWalletButton)
        return cell
    }
    
    private func defaultWalletCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "singleSigCell", for: indexPath)
        cell.selectionStyle = .none
        
        let coldBalanceLabel = cell.viewWithTag(2) as! UILabel
        let walletTypeLabel = cell.viewWithTag(4) as! UILabel
        let walletlabel = cell.viewWithTag(5) as! UILabel
        let confirmedIcon = cell.viewWithTag(26) as! UIImageView
        let fiatBalance = cell.viewWithTag(28) as! UILabel
        let accountTypeIcon = cell.viewWithTag(3) as! UIImageView
        let fxRate = cell.viewWithTag(29) as! UILabel
        let view1 = cell.viewWithTag(30)!
        let view2 = cell.viewWithTag(31)!
        let view3 = cell.viewWithTag(32)!
        let imageView = cell.viewWithTag(33) as! UIImageView
        
        view1.clipsToBounds = true
        view2.clipsToBounds = true
        view3.clipsToBounds = true
        imageView.clipsToBounds = true
        view1.layer.cornerRadius = 8
        view2.layer.cornerRadius = 8
        view3.layer.cornerRadius = 8
        imageView.layer.cornerRadius = 5
        imageView.layer.magnificationFilter = .nearest
        
        imageView.image = LifeHash.image(wallet.descriptor)
        
        fxRate.text = walletInfo.fxRate
        var coldBalance = walletInfo.coldBalance
        if coldBalance == "" {
            coldBalance = "0"
        }
        
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet.descriptor)
        if str.chain == "Mainnet" {
            coldBalanceLabel.textColor = .systemGreen
        } else if str.chain == "Testnet" {
            coldBalanceLabel.textColor = .systemOrange
        }
        
        walletlabel.text = wallet.label
        if !showFiat {
            fiatBalance.text = walletInfo.fiatBalance
            coldBalanceLabel.text = coldBalance
        } else {
            fiatBalance.text = coldBalance
            coldBalanceLabel.text = walletInfo.fiatBalance
        }
        
        if walletInfo.unconfirmed {
            confirmedIcon.image = UIImage(systemName: "exclamationmark.triangle")
            confirmedIcon.tintColor = .systemRed
        } else {
            confirmedIcon.image = UIImage(systemName: "checkmark")
            confirmedIcon.tintColor = .systemGreen
        }
        
        if walletInfo.noUtxos {
            confirmedIcon.alpha = 0
        } else {
            confirmedIcon.alpha = 1
        }
        
        coldBalanceLabel.adjustsFontSizeToFitWidth = true
        
        var format = ""
        if wallet.derivation.contains("84") || wallet.derivation.contains("48") {
            format = "Segwit"
        } else if wallet.derivation.contains("49") {
            format = "Nested Segwit"
        } else if wallet.derivation.contains("44") {
            format = "Legacy"
        }
        
        if str.isMulti {
            walletTypeLabel.text = "\(str.mOfNType) Multi Signature - \(format)"
            
            if wallet.nodeIsSigner != nil {
                if wallet.nodeIsSigner! {
                    if walletInfo.knownSigners.count >= str.sigsRequired {
                        accountTypeIcon.image = UIImage(systemName: "flame")
                        accountTypeIcon.tintColor = .systemRed
                    } else if walletInfo.knownSigners.count == 0 {
                        accountTypeIcon.image = UIImage(systemName: "cloud.sun")
                        accountTypeIcon.tintColor = .systemTeal
                    } else if walletInfo.knownSigners.count > 0 && walletInfo.knownSigners.count < str.sigsRequired {
                        accountTypeIcon.image = UIImage(systemName: "sun.min")
                        accountTypeIcon.tintColor = .systemYellow
                    }
                } else {
                    if walletInfo.knownSigners.count >= str.sigsRequired {
                        accountTypeIcon.image = UIImage(systemName: "flame")
                        accountTypeIcon.tintColor = .systemRed
                    } else if walletInfo.knownSigners.count == 0 {
                        accountTypeIcon.image = UIImage(systemName: "snow")
                        accountTypeIcon.tintColor = .systemTeal
                    } else if walletInfo.knownSigners.count > 0 && walletInfo.knownSigners.count < str.sigsRequired {
                        accountTypeIcon.image = UIImage(systemName: "sun.min")
                        accountTypeIcon.tintColor = .systemYellow
                    }
                }
            } else {
                if walletInfo.knownSigners.count >= str.sigsRequired {
                    accountTypeIcon.image = UIImage(systemName: "flame")
                    accountTypeIcon.tintColor = .systemRed
                } else if walletInfo.knownSigners.count == 0 {
                    accountTypeIcon.image = UIImage(systemName: "snow")
                    accountTypeIcon.tintColor = .systemTeal
                } else if walletInfo.knownSigners.count > 0 && walletInfo.knownSigners.count < str.sigsRequired {
                    accountTypeIcon.image = UIImage(systemName: "sun.min")
                    accountTypeIcon.tintColor = .systemYellow
                }
            }
        } else {
            walletTypeLabel.text = "Single Signature - \(format)"
            if walletInfo.knownSigners.count > 0 {
                accountTypeIcon.image = UIImage(systemName: "flame")
                accountTypeIcon.tintColor = .systemRed
            } else {
                accountTypeIcon.image = UIImage(systemName: "snow")
                accountTypeIcon.tintColor = .white
            }
        }
        
        return cell
    }
    
    private func torCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "torCell", for: indexPath)
        cell.selectionStyle = .none
        
        let spinner = UIActivityIndicatorView(style: .medium)
        let torStatusLabel = cell.viewWithTag(1) as! UILabel
        let p2pOnionLabel = cell.viewWithTag(3) as! UILabel
        let onionVersionLabel = cell.viewWithTag(4) as! UILabel
        let v3address = cell.viewWithTag(6) as! UILabel
        let torActiveCircle = cell.viewWithTag(7) as! UIImageView
        let infoButton = cell.viewWithTag(9) as! UIButton
        let connectedView = cell.viewWithTag(10)!
        let clientOnionView = cell.viewWithTag(11)!
        let p2pView = cell.viewWithTag(13)!
        let v3OnionView = cell.viewWithTag(14)!
        let v3View = cell.viewWithTag(15)!
        
        v3View.layer.cornerRadius = 8
        connectedView.layer.cornerRadius = 8
        clientOnionView.layer.cornerRadius = 8
        p2pView.layer.cornerRadius = 8
        v3OnionView.layer.cornerRadius = 8
        spinner.startAnimating()
        spinner.alpha = 1
        infoButton.alpha = 0
        infoButton.addTarget(self, action: #selector(getTorInfo(_:)), for: .touchUpInside)
        
        if torInfoHidden {
            let image = UIImage(systemName: "rectangle.expand.vertical")
            infoButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "rectangle.compress.vertical")
            infoButton.setImage(image, for: .normal)
        }
        
        let onionAddress = (node.onionAddress.split(separator: "."))[0]
        if onionAddress.count == 16 {
            onionVersionLabel.text = "bitcoin core rpc hidden service version 2"
        } else if onionAddress.count == 56 {
            onionVersionLabel.text = "bitcoin core rpc hidden service version 3"
        }
        
        if isRefreshingTorData {
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
        if torSectionLoaded {
            p2pOnionLabel.text = "P2P URL: \(torInfo.p2pOnionAddress)"
        } else {
            p2pOnionLabel.text = "fetching network info from your node..."
        }
        
        if self.torConnected {
            if torSectionLoaded && !isRefreshingTorData {
                spinner.stopAnimating()
                spinner.alpha = 0
                infoButton.alpha = 1
                torStatusLabel.text = "\(node.label)"
                torActiveCircle.tintColor = .systemGreen
            } else if isRefreshingTorData && !torSectionLoaded {
                spinner.startAnimating()
                spinner.alpha = 1
                infoButton.alpha = 0
                torStatusLabel.text = "\(node.label)..."
                torActiveCircle.tintColor = .systemOrange
            }
        } else {
            if bootStrapping {
                spinner.startAnimating()
                spinner.alpha = 1
                infoButton.alpha = 0
                torStatusLabel.text = "bootstrapping..."
                torActiveCircle.tintColor = .systemOrange
            } else {
                torStatusLabel.text = "\(node.label)..."
                torActiveCircle.tintColor = .systemRed
                spinner.stopAnimating()
                spinner.alpha = 0
                infoButton.alpha = 1
            }
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
        let infoButton = cell.viewWithTag(17) as! UIButton
        infoButton.addTarget(self, action: #selector(getNodeInfo(_:)), for: .touchUpInside)
        
        if !showNodeInfo {
            let image = UIImage(systemName: "rectangle.expand.vertical")
            infoButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "rectangle.compress.vertical")
            infoButton.setImage(image, for: .normal)
        }
        
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
        sizeLabel.text = "\(nodeInfo.size) size"
        difficultyLabel.text = "\(nodeInfo.difficulty) difficulty"
        
        if nodeInfo.progress == "99%" {
            sync.text = "fully synced"
        } else {
            sync.text = "\(nodeInfo.progress) synced"
        }
        
        feeRate.text = "\(nodeInfo.feeRate) fee rate"
        isHot.textColor = .white
        
        if wallet != nil {
            isHot.alpha = 1
            
            if wallet.type == "DEFAULT" {
                isHot.text = "watch-only"
                isHot.textColor = .systemBlue
            } else if wallet.type == "MULTI" {
                isHot.text = "signer"
                isHot.textColor = .systemTeal
            } else if wallet.type == "CUSTOM" {
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
        
        if torInfo.torReachable {
            tor.text = "Tor on"
        } else {
            tor.text = "Tor off"
        }
        
        mempool.text = "\(nodeInfo.mempoolCount.withCommas()) mempool"
        if nodeInfo.pruned {
            pruned.text = "pruned"
        } else if !nodeInfo.pruned {
            pruned.text = "not pruned"
        }
        
        if nodeInfo.network != "" {
            if nodeInfo.network == "main" {
                network.text = "mainnet"
                network.textColor = .systemGreen
            } else if nodeInfo.network == "test" {
                network.text = "⚠ testnet"
                network.textColor = .systemOrange
            } else {
                network.text = nodeInfo.network
            }
        }
        
        blockHeight.text = "\(nodeInfo.blockheight.withCommas()) blocks"
        connections.text = "\(nodeInfo.incomingCount) ↓ \(nodeInfo.outgoingCount) ↑ connections"
        version.text = "Bitcoin Core v\(torInfo.version)"
        hashRate.text = nodeInfo.hashrate + " " + "EH/s hashrate"
        uptime.text = "\(nodeInfo.uptime / 86400) days uptime"
        return cell
    }
    
    private func transactionCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = mainMenu.dequeueReusableCell(withIdentifier: "MainMenuCell", for: indexPath)
        cell.selectionStyle = .none
        mainMenu.separatorColor = .clear
        
        let amountLabel = cell.viewWithTag(2) as! UILabel
        let confirmationsLabel = cell.viewWithTag(3) as! UILabel
        let labelLabel = cell.viewWithTag(4) as! UILabel
        let dateLabel = cell.viewWithTag(5) as! UILabel
        let infoButton = cell.viewWithTag(6) as! UIButton
        let changeImage = cell.viewWithTag(7) as! UIImageView
        let backView = cell.viewWithTag(10)!
        
        backView.layer.cornerRadius = 8
        changeImage.tintColor = .darkGray
        infoButton.addTarget(self, action: #selector(getTransaction(_:)), for: .touchUpInside)
        infoButton.restorationIdentifier = "\(indexPath.row)"
        amountLabel.alpha = 1
        confirmationsLabel.alpha = 1
        labelLabel.alpha = 1
        dateLabel.alpha = 1
        
        let dict = self.transactionArray[indexPath.row]
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
            changeImage.image = UIImage(systemName: "arrow.up.right")
            changeImage.tintColor = .systemRed
        } else {
            amountLabel.text = "+" + amount
            amountLabel.textColor = .lightGray
            labelLabel.textColor = .systemGray
            dateLabel.textColor = .systemGray
            changeImage.image = UIImage(systemName: "arrow.down.left")
            changeImage.tintColor = .systemGreen
        }
        
        if selfTransfer {
            amountLabel.text = (amountLabel.text!).replacingOccurrences(of: "+", with: "")
            amountLabel.text = (amountLabel.text!).replacingOccurrences(of: "-", with: "")
            changeImage.alpha = 1
            amountLabel.textColor = .darkGray
            changeImage.image = UIImage.init(systemName: "arrow.2.circlepath")
            changeImage.tintColor = .darkGray
        }
        
        if confs == 0 {
            amountLabel.text = "⚠︎ \(amountLabel.text!)"
        }
        
        return cell
    }
    
    private func walletCell(_ indexPath: IndexPath) -> UITableViewCell {
        self.walletCellIndex = indexPath.section
        
        if walletSectionLoaded {
            
            if walletExists {
                return defaultWalletCell(indexPath)
            } else {
                return blankCell()
            }
            
        } else {
            
            if torSectionLoaded && self.node != nil && self.wallet != nil && self.torConnected {
                return spinningCell()
            } else if torSectionLoaded && wallet == nil && self.torConnected {
                return noActiveWalletCell(indexPath)
            } else {
                return blankCell()
            }
            
        }
    }
    
    private func torsCell(_ indexPath: IndexPath) -> UITableViewCell {
        self.torCellIndex = indexPath.section
        if !torConnected {
            return descriptionCell(description: "⚠︎ Connection to node failed")
        } else {
            
            if node != nil {
                
                if !torSectionLoaded {
                    return spinningCell()
                } else {
                    return torCell(indexPath)
                }
                
            } else {
                return blankCell()
            }
        }
    }
    
    private func nodesCell(_ indexPath: IndexPath) -> UITableViewCell {
        self.nodeCellIndex = indexPath.section
        if nodeSectionLoaded {
            return nodeCell(indexPath)
        } else if torSectionLoaded {
            return spinningCell()
        } else {
            return blankCell()
        }
    }
    
    private func transactionsCell(_ indexPath: IndexPath) -> UITableViewCell {
        self.transactionCellIndex = indexPath.section
        if !transactionsSectionLoaded {
            
            if walletSectionLoaded {
                return spinningCell()
            } else if self.wallet == nil && nodeSectionLoaded {
                return descriptionCell(description: "⚠︎ No active account")
            } else if self.wallet != nil && nodeSectionLoaded {
                return descriptionCell(description: "⚠︎ No transactions")
            } else {
                return blankCell()
            }
            
        } else {
            
            if transactionArray.count > 0 {
                return transactionCell(indexPath)
            } else if self.wallet == nil {
                return descriptionCell(description: "⚠︎ No active account")
            } else {
                return descriptionCell(description: "No transactions")
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return torsCell(indexPath)
        case 1:
            return nodesCell(indexPath)
        case 2:
            return walletCell(indexPath)
        default:
            return transactionsCell(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 30)
        
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        textLabel.textColor = .systemGray
        
        let refreshButton = UIButton()
        let refreshImage = UIImage(systemName: "arrow.clockwise")
        refreshButton.setImage(refreshImage, for: .normal)
        refreshButton.tintColor = .white
        refreshButton.tag = section
        refreshButton.addTarget(self, action: #selector(reloadSection(_:)), for: .touchUpInside)
        let refreshButtonX = header.frame.maxX - 29
        
        switch section {
        case self.torCellIndex:
            textLabel.text = "Tor Status"
            if torSectionLoaded {
                refreshButton.alpha = 1
                refreshButton.frame = CGRect(x: refreshButtonX, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
            } else {
                refreshButton.alpha = 0
                refreshButton.frame = CGRect(x: 0, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
            }
            
        case self.walletCellIndex:
            textLabel.text = "Current Account Status"
            if walletSectionLoaded {
                refreshButton.alpha = 1
                refreshButton.frame = CGRect(x: refreshButtonX, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
            } else {
                refreshButton.alpha = 0
                refreshButton.frame = CGRect(x: 0, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
            }
            
        case self.nodeCellIndex:
            textLabel.text = "Full Node Status"
            if nodeSectionLoaded {
                refreshButton.alpha = 1
                refreshButton.frame = CGRect(x: refreshButtonX, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
            } else {
                refreshButton.alpha = 0
                refreshButton.frame = CGRect(x: 0, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
            }
            
        case 3:
            textLabel.text = "Transaction History"
            if transactionsSectionLoaded {
                refreshButton.alpha = 1
                refreshButton.frame = CGRect(x: refreshButtonX, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
            } else {
                refreshButton.alpha = 0
                refreshButton.frame = CGRect(x: 0, y: 0, width: 15, height: 18)
                textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
            }
            
        default:
            break
        }
        refreshButton.center.y = textLabel.center.y
        header.addSubview(textLabel)
        header.addSubview(refreshButton)
        return header
    }
    
    @objc func reloadSection(_ sender: UIButton) {
        let section = sender.tag
        sender.tintColor = .clear
        sender.loadingIndicator(show: true)
        
        switch section {
        case self.torCellIndex:
            self.refreshTorData(sender)
            
        case self.walletCellIndex:
            self.refreshWalletData(sender)
            
        case self.nodeCellIndex:
            self.refreshNodeData(sender)
            
        default:
            self.refreshTransactions(sender)
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section <= 3 {
            return 30
        } else {
            return 10
        }
    }
    
    private func walletCellHeight() -> CGFloat {
        if walletSectionLoaded {
            return 159
        } else {
            return 47
        }
    }
    
    private func torCellHeight() -> CGFloat {
        if !torConnected {
            return 47
        } else {
            
            if node != nil {
                
                if torInfoHidden {
                    
                    if torSectionLoaded {
                        return 38
                    } else {
                        return 47
                    }
                    
                } else {
                    return 154
                }
                
            } else {
                return 47
            }
        }
    }
    
    private func nodeCellHeight() -> CGFloat {
        if nodeSectionLoaded {
            
            if showNodeInfo {
                return 205
            } else {
                return 62
            }
            
        } else {
            return 47
        }
    }
    
    private func transactionCellHeight() -> CGFloat {
        if transactionsSectionLoaded {
            
            if transactionArray.count > 0 {
                return 80
            } else {
                return 47
            }
            
        } else {
            return 47
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return torCellHeight()
            
        case 1:
            return nodeCellHeight()
            
        case 2:
            return walletCellHeight()
            
        default:
            return transactionCellHeight()
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == walletCellIndex {
            
            if showFiat {
                showFiat = false
            } else {
                showFiat = true
            }
            
            reloadSections([walletCellIndex])
        }
    }
    
    @objc func getWalletInfo(_ sender: UIButton) {
        if infoHidden {
            infoHidden = false
        } else {
            infoHidden = true
        }
        reloadSections([walletCellIndex])
    }
    
    @objc func getTorInfo(_ sender: UIButton) {
        if torInfoHidden {
            torInfoHidden = false
        } else {
            torInfoHidden = true
        }
        reloadSections([torCellIndex])
    }
    
    @objc func getNodeInfo(_ sender: UIButton) {
        if showNodeInfo {
            showNodeInfo = false
        } else {
            showNodeInfo = true
        }
        reloadSections([nodeCellIndex])
    }
    
    private func updateLabel(text: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.statusLabel.text = text
        }
    }
    
    private func loadWalletData() {
        isRefreshingWalletData = true
        reloadSections([walletCellIndex])
        updateLabel(text: "     Getting wallet info...")
        existingWalletName = wallet.name!
        nodeLogic?.loadWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
            if success && dictToReturn != nil {
                vc.torConnected = true
                /// we update the wallets database in NodeLogic, so we need to refresh the wallet struct here
                getActiveWalletNow { (w, error) in
                    if w != nil {
                        vc.wallet = w!
                        vc.walletExists = true
                        vc.walletInfo = HomeStruct(dictionary: dictToReturn!)
                        vc.walletSectionLoaded = true
                        vc.isRefreshingWalletData = false
                        vc.reloadSections([vc.walletCellIndex, 3])
                        vc.loadTransactionData()
                    }
                }
            } else {
                vc.walletSectionLoaded = true
                vc.removeStatusLabel()
                vc.isRefreshingWalletData = false
                vc.walletExists = false
                vc.reloadSections([vc.walletCellIndex])
                vc.loadNodeData()
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "error loading wallet data")
            }
        }
    }
    
    private func refreshWalletData(_ sender: UIButton) {
        isRefreshingWalletData = true
        nodeLogic?.loadWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
            if success && dictToReturn != nil {
                vc.torConnected = true
                /// we update the wallets database in NodeLogic, so we need to refresh the wallet struct here
                getActiveWalletNow { (w, error) in
                    if w != nil {
                        vc.wallet = w!
                        vc.walletInfo = HomeStruct(dictionary: dictToReturn!)
                        vc.walletSectionLoaded = true
                        vc.isRefreshingWalletData = false
                        vc.reloadSections([vc.walletCellIndex])
                    }
                }
            } else {
                vc.walletSectionLoaded = false
                vc.removeStatusLabel()
                vc.isRefreshingWalletData = false
                vc.reloadSections([vc.walletCellIndex])
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "error fetching wallet data")
            }
        }
    }
    
    private func loadTorData() {
        if node != nil {
            reloadSections([torCellIndex])
            updateLabel(text: "     Getting network info from your node...")
            nodeLogic?.loadTorData { [unowned vc = self] (success, dictToReturn, errorDesc) in
                if success && dictToReturn != nil {
                    vc.torConnected = true
                    vc.torInfo = HomeStruct(dictionary: dictToReturn!)
                    vc.torSectionLoaded = true
                    vc.isRefreshingTorData = false
                    if vc.wallet != nil {
                        vc.reloadSections([vc.torCellIndex, vc.walletCellIndex])
                        vc.loadWalletData()
                    } else {
                        vc.reloadSections([vc.torCellIndex, vc.nodeCellIndex])
                        vc.loadNodeData()
                    }
                } else {
                    vc.torConnected = false
                    vc.torSectionLoaded = false
                    vc.removeStatusLabel()
                    vc.isRefreshingTorData = false
                    vc.reloadSections([vc.torCellIndex])
                    DispatchQueue.main.async {
                        vc.refresher.endRefreshing()
                    }
                    displayAlert(viewController: vc,
                                 isError: true,
                                 message: errorDesc ?? "error fetching network data")
                }
            }
        }
    }
    
    private func refreshTorData(_ sender: UIButton) {
        if node != nil {
            nodeLogic?.loadTorData { [unowned vc = self] (success, dictToReturn, errorDesc) in
                if success && dictToReturn != nil {
                    vc.torConnected = true
                    vc.torInfo = HomeStruct(dictionary: dictToReturn!)
                    vc.torSectionLoaded = true
                    vc.isRefreshingTorData = false
                    vc.reloadSections([vc.torCellIndex])
                } else {
                    vc.torSectionLoaded = false
                    vc.removeStatusLabel()
                    vc.isRefreshingTorData = false
                    vc.reloadSections([vc.torCellIndex])
                    displayAlert(viewController: self,
                                 isError: true,
                                 message: errorDesc ?? "error fetching network data")
                }
            }
        }
    }
    
    private func loadNodeData() {
        isRefreshingNodeData = true
        reloadSections([nodeCellIndex])
        updateLabel(text: "     Getting Full Node data...")
        nodeLogic?.loadNodeData(node: node) { [unowned vc = self] (success, dictToReturn, errorDesc) in
            if success && dictToReturn != nil {
                vc.torConnected = true
                vc.nodeInfo = HomeStruct(dictionary: dictToReturn!)
                vc.nodeSectionLoaded = true
                vc.isRefreshingNodeData = false
                DispatchQueue.main.async {
                    if vc.wallet == nil {
                        vc.reloadSections([vc.walletCellIndex, vc.nodeCellIndex, 3])
                    } else {
                        vc.reloadSections([vc.nodeCellIndex])
                    }
                    vc.removeStatusLabel()
                    vc.sponsorThisApp()
                    vc.checkWalletStatus()
                }
            } else {
                vc.nodeSectionLoaded = false
                vc.removeStatusLabel()
                vc.isRefreshingNodeData = false
                vc.reloadSections([vc.nodeCellIndex])
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "error fetching node stats")
            }
        }
    }
    
    private func refreshNodeData(_ sender: UIButton) {
        isRefreshingNodeData = true
        nodeLogic?.loadNodeData(node: node) { [unowned vc = self] (success, dictToReturn, errorDesc) in
            if success && dictToReturn != nil {
                vc.torConnected = true
                vc.nodeInfo = HomeStruct(dictionary: dictToReturn!)
                vc.nodeSectionLoaded = true
                vc.isRefreshingNodeData = false
                vc.reloadSections([vc.nodeCellIndex])
            } else {
                vc.nodeSectionLoaded = false
                vc.isRefreshingNodeData = false
                vc.reloadSections([vc.nodeCellIndex])
                displayAlert(viewController: vc, isError: true, message: errorDesc ?? "error fetching node stats")
            }
        }
    }
    
    private func loadTransactionData() {
        updateLabel(text: "     Getting transactions...")
        nodeLogic?.loadTransactionData(wallet: wallet) { [unowned vc = self] (success, transactions, errorDesc) in
            if success && transactions != nil {
                DispatchQueue.main.async {
                    vc.torConnected = true
                    vc.transactionArray = transactions!.reversed()
                    vc.transactionsSectionLoaded = true
                    vc.mainMenu.reloadData()
                    vc.loadNodeData()
                }
            } else {
                vc.transactionsSectionLoaded = false
                vc.removeStatusLabel()
                displayAlert(viewController: vc,
                             isError: true,
                             message: errorDesc ?? "error fetching transactions")
            }
        }
    }
    
    private func refreshTransactions(_ sender: UIButton) {
        nodeLogic?.loadTransactionData(wallet: wallet) { [unowned vc = self] (success, transactions, errorDesc) in
            if success && transactions != nil {
                vc.torConnected = true
                vc.transactionArray.removeAll()
                vc.transactionArray = transactions!.reversed()
                vc.transactionsSectionLoaded = true
                DispatchQueue.main.async {
                    vc.mainMenu.reloadData()
                }
            } else {
                vc.transactionsSectionLoaded = false
                self.removeStatusLabel()
                displayAlert(viewController: self,
                             isError: true,
                             message: errorDesc ?? "error fetching transactions")
            }
        }
    }
    
    @objc func getTransaction(_ sender: UIButton) {
        let index = Int(sender.restorationIdentifier!)!
        let selectedTx = self.transactionArray[index]
        let txID = selectedTx["txID"] as! String
        tx = txID
        UIPasteboard.general.string = txID
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "getTransaction", sender: vc)
        }
    }
    
    //MARK: User Interface
    
    private func addStatusLabel(description: String) {
        //Matshona Dhliwayo — 'Great things take time; that is why seeds persevere through rocks and dirt to bloom.'
        DispatchQueue.main.async { [unowned vc = self] in
            vc.statusLabel.removeFromSuperview()
            vc.statusLabel.frame = CGRect(x: 0, y: -50, width: vc.view.frame.width, height: 50)
            vc.statusLabel.backgroundColor = .black
            vc.statusLabel.textAlignment = .left
            vc.statusLabel.textColor = .lightGray
            vc.statusLabel.font = .systemFont(ofSize: 12)
            vc.statusLabel.text = description
            vc.view.addSubview(vc.statusLabel)
            UIView.animate(withDuration: 0.5, animations: { [unowned vc = self] in
                vc.statusLabel.frame = CGRect(x: 16, y: vc.navigationController!.navigationBar.frame.maxY + 5, width: vc.view.frame.width - 32, height: 13)
            })
        }
    }
    
    private func removeStatusLabel() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                vc.statusLabel.alpha = 0
            }) { [unowned vc = self] (_) in
                vc.statusLabel.removeFromSuperview()
            }
        }
    }
    
    @objc func addWallet() {
        if self.torConnected {
            self.tabBarController?.selectedIndex = 1
        } else {
            showAlert(vc: self, title: "Tor not connected", message: "You need to be connected to a node over tor in order to create a wallet")
        }
    }
    
    private func configureRefresher() {
        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.white
        refresher.attributedTitle = NSAttributedString(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        refresher.addTarget(self, action: #selector(refreshNow), for: UIControl.Event.valueChanged)
        mainMenu.addSubview(refresher)
    }
    
    //MARK: User Actions
    
    @objc func closeConnectingView() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.connectingView.removeConnectingView()
        }
    }
    
    @objc func refreshNow() {
        isRefreshingTorData = true
        reloadTableData()
    }
    
    private func addNode() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "scanNow", sender: vc)
        }
    }
    
    private func reloadTableData() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.torSectionLoaded = false
            vc.walletSectionLoaded = false
            vc.transactionsSectionLoaded = false
            vc.nodeSectionLoaded = false
            vc.transactionArray.removeAll()
            vc.refresher.endRefreshing()
            vc.mainMenu.reloadData()
            vc.existingWalletName = ""
        }
        getActiveWalletNow() { [unowned vc = self] (w, error) in
            if !error && w != nil {
                vc.wallet = w!
                vc.loadTorData()
            } else {
                
                if vc.node != nil {
                    vc.loadTorData()
                } else {
                    vc.isRefreshingTorData = false
                    vc.removeStatusLabel()
                    displayAlert(viewController: vc, isError: true, message: "no active node, please go to node manager and activate one")
                }
                
            }
        }
    }
    
    private func reloadSections(_ sections: [Int]) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.mainMenu.reloadSections(IndexSet(sections), with: .automatic)
        }
    }
    
    private func nodeJustAdded() {
        Encryption.getNode { [unowned vc = self] (node, error) in
            if !error && node != nil {
                vc.node = node!
                vc.reloadSections([vc.nodeCellIndex])
                vc.didAppear()
            }
        }
    }
    
    //MARK: Helpers
    
    private func firstTimeHere() {
        let firstTime = FirstTime()
        firstTime.firstTimeHere { [unowned vc = self] (success) in
            if !success {
                displayAlert(viewController: vc, isError: true, message: "Something very wrong has happened... Please delete the app and try again.")
            }
        }
    }
    
    @IBAction func sponsorNow(_ sender: Any) {
        sponsorNow()
    }
    
    private func sponsorThisApp() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                vc.sponsorView.alpha = 1
            }) { [unowned vc = self] (_) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                    vc.closeSponsorButton()
                }
            }
        }
    }
    
    @IBAction func closeSponsorBanner(_ sender: Any) {
        closeSponsorButton()
    }
    
    @objc func closeSponsorButton() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                vc.sponsorView.alpha = 0
            })
        }
    }
    
    @objc func sponsorNow() {
        UIApplication.shared.open(URL(string: "https://github.com/sponsors/BlockchainCommons")!) { (Bool) in }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        mainMenu.reloadData()
    }
    
    func torConnProgress(_ progress: Int) {
        updateLabel(text: "     Bootstrapping Tor \(progress)%...")
    }
    
    func torConnFinished() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.mainMenu.alpha = 1
        }
        bootStrapping = false
        torConnected = true
        reloadSections([torCellIndex])
        didAppear()
    }
    
    func torConnDifficulties() {
        showAlert(vc: self, title: "Error", message: "We are having difficulties starting tor...")
    }
    
    private func checkWalletStatus() {
        if wallet != nil {
            WalletStatus.getStatus(wallet: wallet!) { dict in
                let status = StatusStruct(dictionary: dict)
                if status.shouldRefill {
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.notificationIcon.image = UIImage(systemName: "exclamationmark.bubble")
                        let appDelegate = UIApplication.shared.delegate as? AppDelegate
                        appDelegate?.promptForNotificationPermission()
                        appDelegate?.scheduleNotification(type: "Refill")
                    }
                } else {
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.notificationIcon.image = UIImage(systemName: "bubble.left")
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "segueToColdcardMusigCreated":
            if let vc = segue.destination as? WalletCreatedSuccessViewController {
                vc.isColdcard = true
                vc.recoveryQr = accountMap
                vc.nodesWords = offlineWords
                vc.recoveryPhrase = deviceWords
                vc.wallet = coldcard
            }
            
        case "segueToConfirmImport":
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                vc.walletDict = coldcard
                vc.isImporting = true
                vc.walletNameHash = walletNameHash
            }
            
        case "settings":
            if let vc = segue.destination as? SettingsViewController {
                vc.doneBlock = { [unowned thisVc = self] result in
                    // checks if a different node was activated when user went to settings and refreshes the table if they did
                    Encryption.getNode { (node, error) in
                        if !error && node != nil {
                            if node!.id != thisVc.existingNodeId {
                                thisVc.didAppear()
                            }
                        }
                    }
                }
            }
            
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
                vc.scanningNode = scanningNode
                vc.onDoneBlock = { [unowned thisVc = self] result in
                    thisVc.nodeJustAdded()
                }
            }
            
        case "refillMsigFromHome":
            if let vc = segue.destination as? RefillMultisigViewController {
                vc.wallet = self.wallet
                vc.multiSigRefillDoneBlock = { [unowned thisVc = self] result in
                    showAlert(vc: thisVc, title: "Success", message: "Keypool refilled ✓")
                    thisVc.loadWalletData()
                }
            }
            
        case "goConfirmPsbtSegue":
            if let vc = segue.destination as? ConfirmViewController {
                vc.unsignedPsbt = unsignedPsbt
                vc.signedRawTx = signedRawTx
            }
            
        default:
            break
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
