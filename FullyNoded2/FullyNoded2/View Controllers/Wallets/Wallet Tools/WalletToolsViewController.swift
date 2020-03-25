//
//  WalletToolsViewController.swift
//  FullyNoded2
//
//  Created by Peter on 10/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletToolsViewController: UIViewController {
    
    var wallet:WalletStruct!
    var sweepDoneBlock : ((Bool) -> Void)?
    @IBOutlet var rescanOutlet: UIButton!
    @IBOutlet var sweepToOutlet: UIButton!
    
    let creatingView = ConnectingView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        rescanOutlet.layer.cornerRadius = 8
        sweepToOutlet.layer.cornerRadius = 8
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func rescanNow(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Rescan the blockchain?", message: "This button will start a blockchain rescan for your current wallet. This is useful if you imported the wallet and do not see balances yet. If you recovered a wallet then the app will automatically rescan the blockchain for you.", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Rescan from birthdate", style: .default, handler: { action in
                
                self.rescanFromBirthdate()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Full Rescan", style: .default, handler: { action in
                
                self.fullRescan()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Check Scan Status", style: .default, handler: { action in
                
                self.checkScanStatus()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Abort Rescan", style: .default, handler: { action in
                
                self.abortRescan()
                
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
        let reducer = Reducer()
        reducer.makeCommand(walletName: self.wallet.name, command: .rescanblockchain, param: "\(self.wallet.blockheight)") {
            
            DispatchQueue.main.async {
                
                self.creatingView.label.text = "confirming rescan status"
                
            }
            
            reducer.errorBool = false
            reducer.errorDescription = ""
            
            reducer.makeCommand(walletName: self.wallet.name, command: .getwalletinfo, param: "") {
                
                if !reducer.errorBool || reducer.errorDescription.description.contains("abort") {
                    
                    if let result = reducer.dictToReturn {
                        
                        if let scanning = result["scanning"] as? NSDictionary {
                            
                            if let _ = scanning["duration"] as? Int {
                                
                                self.creatingView.removeConnectingView()
                                let progress = (scanning["progress"] as! Double)
                                showAlert(vc: self, title: "Rescanning", message: "Wallet is rescanning with current progress: \((progress * 100).rounded())%")
                                
                            }
                            
                        } else if (result["scanning"] as? Int) == 0 {
                            
                            self.creatingView.removeConnectingView()
                            showAlert(vc: self, title: "Scan Complete", message: "The wallet is not currently scanning.")
                            
                        } else {
                            
                            self.creatingView.removeConnectingView()
                            showAlert(vc: self, title: "Error", message: "Unable to determine if wallet is rescanning.")
                            
                        }
                        
                    }
                    
                } else {
                    
                    self.creatingView.removeConnectingView()
                    displayAlert(viewController: self, isError: true, message: reducer.errorDescription)
                    
                }
                
            }
            
        }
        
    }
    
    private func fullRescan() {
        
        self.creatingView.addConnectingView(vc: self, description: "initiating rescan")
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: self.wallet.name, command: .rescanblockchain, param: "") {
            
            DispatchQueue.main.async {
                
                self.creatingView.label.text = "confirming rescan status"
                
            }
            
            reducer.errorBool = false
            reducer.errorDescription = ""
            
            reducer.makeCommand(walletName: self.wallet.name, command: .getwalletinfo, param: "") {
                
                if !reducer.errorBool || reducer.errorDescription.description.contains("abort") {
                    
                    if let result = reducer.dictToReturn {
                        
                        if let scanning = result["scanning"] as? NSDictionary {
                            
                            if let _ = scanning["duration"] as? Int {
                                
                                self.creatingView.removeConnectingView()
                                let progress = (scanning["progress"] as! Double)
                                showAlert(vc: self, title: "Rescanning", message: "Wallet is rescanning with current progress: \((progress * 100).rounded())%")
                                
                            }
                            
                        } else if (result["scanning"] as? Int) == 0 {
                            
                            self.creatingView.removeConnectingView()
                            showAlert(vc: self, title: "Scan Complete", message: "The wallet is not currently scanning.")
                            
                        } else {
                            
                            self.creatingView.removeConnectingView()
                            showAlert(vc: self, title: "Scan Complete", message: "Unable to determine if wallet is rescanning.")
                            
                        }
                        
                    }
                    
                } else {
                    
                    self.creatingView.removeConnectingView()
                    displayAlert(viewController: self, isError: true, message: reducer.errorDescription)
                    
                }
                
            }
            
        }
        
    }
    
    private func checkScanStatus() {
        
        self.creatingView.addConnectingView(vc: self, description: "checking scan status")
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: self.wallet.name, command: .getwalletinfo, param: "") {
            
            if !reducer.errorBool || reducer.errorDescription.description.contains("abort") {
                
                if let result = reducer.dictToReturn {
                    
                    if let scanning = result["scanning"] as? NSDictionary {
                        
                        if let _ = scanning["duration"] as? Int {
                            
                            self.creatingView.removeConnectingView()
                            let progress = (scanning["progress"] as! Double)
                            showAlert(vc: self, title: "Rescanning", message: "Wallet is rescanning with current progress: \((progress * 100).rounded())%")
                            
                        }
                        
                    } else if (result["scanning"] as? Int) == 0 {
                        
                        self.creatingView.removeConnectingView()
                        showAlert(vc: self, title: "Scan Complete", message: "Wallet not rescanning.")
                        
                    } else {
                        
                        self.creatingView.removeConnectingView()
                        showAlert(vc: self, title: "Error", message: "Unable to determine if wallet is rescanning.")
                        
                    }
                    
                }
                
            } else {
                
                self.creatingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: reducer.errorDescription)
                
            }
            
        }
        
    }
    
    private func abortRescan() {
        
        self.creatingView.addConnectingView(vc: self, description: "aborting rescan")
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: self.wallet.name, command: .abortrescan, param: "") {
            
            if !reducer.errorBool {
                
                self.creatingView.removeConnectingView()
                showAlert(vc: self, title: "Rescan aborted", message: "")
                
            } else {
                
                self.creatingView.removeConnectingView()
                showAlert(vc: self, title: "Error", message: reducer.errorDescription)
                
            }
            
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
                
                vc.doneBlock = { result in
                    
                    DispatchQueue.main.async {
                        
                        self.dismiss(animated: true) {
                            
                            self.sweepDoneBlock!(true)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        default:
            
            break
            
        }
    }
    

}
