//
//  WalletToolsViewController.swift
//  FullyNoded2
//
//  Created by Peter on 10/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletToolsViewController: UIViewController {
    
    var addSeed = Bool()
    var wallet:WalletStruct!
    var sweepDoneBlock: ((Bool) -> Void)?
    var refillDoneBlock: ((Bool) -> Void)?
    @IBOutlet var rescanOutlet: UIButton!
    @IBOutlet var sweepToOutlet: UIButton!
    @IBOutlet var refillOutlet: UIButton!
    @IBOutlet weak var addSignerOutlet: UIButton!
    @IBOutlet weak var backupInfoOutlet: UIButton!
    @IBOutlet weak var utxosOutlet: UIButton!
    @IBOutlet weak var exportKeyOutlet: UIButton!
    @IBOutlet weak var addSignerInfoOutlet: UIButton!
    
    let creatingView = ConnectingView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rescanOutlet.layer.cornerRadius = 8
        sweepToOutlet.layer.cornerRadius = 8
        refillOutlet.layer.cornerRadius = 8
        addSignerOutlet.layer.cornerRadius = 8
        backupInfoOutlet.layer.cornerRadius = 8
        utxosOutlet.layer.cornerRadius = 8
        exportKeyOutlet.layer.cornerRadius = 8
        
        if wallet.xprvs != nil {
            
            if wallet.xprvs!.count == 0 && wallet.type == "DEFAULT" {
                addSignerOutlet.alpha = 1
                addSignerInfoOutlet.alpha = 1
                
            } else if wallet.xprvs!.count > 0 && wallet.type == "DEFAULT" {
                addSignerOutlet.alpha = 0
                addSignerInfoOutlet.alpha = 0
                
            } else if wallet.type != "DEFAULT" {
                let parser = DescriptorParser()
                let str = parser.descriptor(wallet.descriptor)
                
                if wallet.xprvs!.count < str.sigsRequired {
                    addSignerOutlet.alpha = 1
                    addSignerInfoOutlet.alpha = 1
                    
                } else {
                    addSignerOutlet.alpha = 0
                    addSignerInfoOutlet.alpha = 0
                    
                }
            }
            
        } else {
            addSignerOutlet.alpha = 1
            addSignerInfoOutlet.alpha = 1
            
        }
    
    }
    
    private func refillMultisig() {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "refillMultisig", sender: self)
            
        }
        
    }
    
    private func refillSingleSig() {
        
        self.creatingView.addConnectingView(vc: self, description: "Refilling the keypool")
        
        let singleSig = RefillSingleSig()
        singleSig.refill(wallet: self.wallet) { [unowned vc = self] (success, error) in
            
            if success {
                
                vc.creatingView.removeConnectingView()
                DispatchQueue.main.async {
                    
                    vc.dismiss(animated: true) {
                        
                        vc.refillDoneBlock!(true)
                        
                    }
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error!", message: "There was an error refilling the keypool: \(String(describing: error))")
                
            }
            
        }
        
    }
    
    @IBAction func seeBackUpInfo(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "exportSeed", sender: vc)
        }
    }
    
    @IBAction func seeUtxos(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "seeUtxos", sender: vc)
        }
    }
    
    @IBAction func exportKeys(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "viewKeysSegue", sender: vc)
        }
    }
    
    @IBAction func addSigner(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.addSeed = true
            vc.performSegue(withIdentifier: "refillMultisig", sender: vc)
        }
    }
    
    
    @IBAction func refillKeypool(_ sender: Any) {
        
        DispatchQueue.main.async {
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            
            let alert = UIAlertController(title: "Refill Keypool", message: "", preferredStyle: alertStyle)

            alert.addAction(UIAlertAction(title: "Refill Now", style: .default, handler: { [unowned vc = self] action in
                
                if vc.wallet.type == "MULTI" {
                    
                    vc.refillMultisig()
                    
                } else {
                    
                    vc.refillSingleSig()
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "What is this?", style: .default, handler: { [unowned vc = self] action in
               
                let message = "This tool allows you to manually refill the keypool associated with this wallet on your node at anytime. Due to the way the app works we have to choose a limited number of keys to import into your node during the wallet creation process (currently 0 to 2500). This can be an issue when you reach your last key as your node will not hold the keys necessary to build transactions or produce addresses. Therefore we offer you the ability to manually refill your nodes keypool. The app is smart eough to know how many keys are in your keypool and will import an additional 2500 keys. This will be reflected on your wallet just under the \"Updated:\" label and in the node pane on the wallet."
                
                showAlert(vc: vc, title: "Keypool Refill Info", message: message)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func rescanNow(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            
            let alert = UIAlertController(title: "Rescan the blockchain?", message: "This button will start a blockchain rescan for your current wallet. This is useful if you imported the wallet and do not see balances yet. If you recovered a wallet then the app will automatically rescan the blockchain for you.", preferredStyle: alertStyle)
            
            alert.addAction(UIAlertAction(title: "Rescan from birthdate", style: .default, handler: { [unowned vc = self] action in
                
                vc.rescanFromBirthdate()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Full Rescan", style: .default, handler: { [unowned vc = self] action in
                
                vc.fullRescan()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Check Scan Status", style: .default, handler: { [unowned vc = self] action in
                
                vc.checkScanStatus()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Abort Rescan", style: .default, handler: { [unowned vc = self] action in
                
                vc.abortRescan()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func sweepToAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "goSweep", sender: self)
            
        }
        
    }
    
    
    private func rescanFromBirthdate() {
        
        self.creatingView.addConnectingView(vc: self, description: "initiating rescan")
        Reducer.makeCommand(walletName: self.wallet.name!, command: .rescanblockchain, param: "\(self.wallet.blockheight)") { [unowned vc = self] (object, errorDesc) in
            
            if errorDesc != nil {
                vc.creatingView.removeConnectingView()
                if errorDesc!.contains("Wallet is currently rescanning") {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                    }
                }
                showAlert(vc: vc, title: "Error", message: errorDesc!)
            } else {
                DispatchQueue.main.async {
                    
                    vc.creatingView.label.text = "confirming rescan status"
                    
                }
                
                Reducer.makeCommand(walletName: vc.wallet.name!, command: .getwalletinfo, param: "") { (object, errorDesc) in
                    
                    if let result = object as? NSDictionary {
                        
                        if let scanning = result["scanning"] as? NSDictionary {
                            
                            if let _ = scanning["duration"] as? Int {
                                
                                vc.creatingView.removeConnectingView()
                                let progress = (scanning["progress"] as! Double)
                                showAlert(vc: vc, title: "Rescanning", message: "Wallet is rescanning with current progress: \((progress * 100).rounded())%")
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                                }
                            }
                            
                        } else if (result["scanning"] as? Int) == 0 {
                            
                            vc.creatingView.removeConnectingView()
                            showAlert(vc: vc, title: "Scan Complete", message: "The wallet is not currently scanning.")
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                            }
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: "Unable to determine if wallet is rescanning.")
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        showAlert(vc: vc, title: "Scan Complete", message: errorDesc ?? "unknown error")
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    private func fullRescan() {
        
        self.creatingView.addConnectingView(vc: self, description: "initiating rescan")
        
        func rescanNow(param: String) {
            Reducer.makeCommand(walletName: self.wallet.name!, command: .rescanblockchain, param: param) { [unowned vc = self] (object, errorDesc) in
                if errorDesc != nil {
                    vc.creatingView.removeConnectingView()
                    if errorDesc!.contains("Wallet is currently rescanning") {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                        }
                    }
                    showAlert(vc: vc, title: "Error", message: errorDesc!)
                } else {
                    DispatchQueue.main.async {
                        
                        vc.creatingView.label.text = "confirming rescan status"
                        
                    }
                    
                    Reducer.makeCommand(walletName: vc.wallet.name!, command: .getwalletinfo, param: "") { (object, errorDesc) in
                        
                        if let result = object as? NSDictionary {
                            
                            if let scanning = result["scanning"] as? NSDictionary {
                                
                                if let _ = scanning["duration"] as? Int {
                                    
                                    vc.creatingView.removeConnectingView()
                                    let progress = (scanning["progress"] as! Double)
                                    showAlert(vc: vc, title: "Rescanning", message: "Wallet is rescanning with current progress: \((progress * 100).rounded())%")
                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                                    }
                                    
                                }
                                
                            } else if (result["scanning"] as? Int) == 0 {
                                
                                vc.creatingView.removeConnectingView()
                                showAlert(vc: vc, title: "Scan Complete", message: "The wallet is not currently scanning.")
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                                }
                                
                            } else {
                                
                                vc.creatingView.removeConnectingView()
                                showAlert(vc: vc, title: "Scan Complete", message: "Unable to determine if wallet is rescanning.")
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                                }
                                
                            }
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: errorDesc ?? "unknown error")
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        Reducer.makeCommand(walletName: self.wallet.name!, command: .getblockchaininfo, param: "") { [unowned vc = self] (object, errorDescription) in
            if let dict = object as? NSDictionary {
                if let pruned = dict["pruned"] as? Bool {
                    if pruned {
                        if let pruneHeight = dict["pruneheight"] as? Int {
                            Reducer.makeCommand(walletName: self.wallet.name!, command: .rescanblockchain, param: "\(pruneHeight)") { (response, errorMessage) in
                                rescanNow(param: "\(pruneHeight)")
                            }
                        } else {
                            vc.creatingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: errorDescription ?? "unknown error")
                        }
                    } else {
                        rescanNow(param: "")
                    }
                } else {
                    vc.creatingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: errorDescription ?? "unknown error")
                }
            } else {
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: errorDescription ?? "unknown error")
            }
        }
    }
    
    private func checkScanStatus() {
        
        self.creatingView.addConnectingView(vc: self, description: "checking scan status")
        
        Reducer.makeCommand(walletName: self.wallet.name!, command: .getwalletinfo, param: "") { [unowned vc = self] (object, errorDesc) in
            
            if let result = object as? NSDictionary {
                
                if let scanning = result["scanning"] as? NSDictionary {
                    
                    if let _ = scanning["duration"] as? Int {
                        
                        vc.creatingView.removeConnectingView()
                        let progress = (scanning["progress"] as! Double)
                        showAlert(vc: vc, title: "Rescanning", message: "Wallet is rescanning with current progress: \((progress * 100).rounded())%")
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                        }
                    }
                    
                } else if (result["scanning"] as? Int) == 0 {
                    
                    vc.creatingView.removeConnectingView()
                    showAlert(vc: vc, title: "Scan Complete", message: "Wallet not rescanning.")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                    }
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "Unable to determine if wallet is rescanning.")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .didRescanAccount, object: nil, userInfo: nil)
                    }
                    
                }
                
            } else {
                
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: errorDesc ?? "unknown error")
                
            }
            
        }
        
    }
    
    private func abortRescan() {
        creatingView.addConnectingView(vc: self, description: "aborting rescan")
        Reducer.makeCommand(walletName: self.wallet.name!, command: .abortrescan, param: "") { [unowned vc = self] (object, errorDesc) in
            
            if object != nil {
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Rescan aborted", message: "")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .didAbortRescan, object: nil, userInfo: nil)
                }
            } else {
                vc.creatingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: errorDesc ?? "unknown error")
                
            }
            
        }
        
    }
    
    // MARK: - Info Button's
    @IBAction func rescanInfo(_ sender: Any) {
        showInfo(title: "Rescan Info", message: TextBlurbs.rescanInfoText())
    }
    
    @IBAction func sweepToInfo(_ sender: Any) {
        showInfo(title: "Sweep To Info", message: TextBlurbs.sweepToInfoText())
    }
    
    @IBAction func refillKeypoolInfo(_ sender: Any) {
        showInfo(title: "Refill Keypool Info", message: TextBlurbs.refillKeypoolText())
    }
    
    @IBAction func addSignerInfo(_ sender: Any) {
        showInfo(title: "Add Signer Info", message: TextBlurbs.addSignerText())
    }
    
    @IBAction func backupInfo(_ sender: Any) {
        showInfo(title: "Backup Info", message: TextBlurbs.backupInfoText())
    }
    
    @IBAction func viewUtxosInfo(_ sender: Any) {
        showInfo(title: "UTXO's Info", message: TextBlurbs.viewUtxosText())
    }
    
    @IBAction func exportKeysInfo(_ sender: Any) {
        showInfo(title: "Export Keys Info", message: TextBlurbs.exportKeysText())
    }
    
    private func showInfo(title: String, message: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: alertStyle)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch segue.identifier {
            
        case "goSweep":
            
            if let vc = segue.destination as? SweepToViewController {
                
                vc.doneBlock = { [unowned thisVc = self] result in
                    
                    DispatchQueue.main.async {
                        
                        thisVc.dismiss(animated: true) {
                            
                            thisVc.sweepDoneBlock!(true)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        case "refillMultisig":
            
            if let vc = segue.destination as? RefillMultisigViewController {
                
                vc.addSeed = addSeed
                vc.wallet = wallet
                vc.multiSigRefillDoneBlock = { [unowned thisVc = self] result in
                    
                    DispatchQueue.main.async {
                        
                        thisVc.dismiss(animated: true) {
                            
                            thisVc.refillDoneBlock!(true)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }

}
