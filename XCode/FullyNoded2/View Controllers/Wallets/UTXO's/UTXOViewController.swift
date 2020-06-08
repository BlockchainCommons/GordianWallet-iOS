//
//  UTXOViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class UTXOViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var walletName = ""
    var tapQRGesture = UITapGestureRecognizer()
    var tapTextViewGesture = UITapGestureRecognizer()
    let refresher = UIRefreshControl()
    var utxoArray = [[String:Any]]()
    var address = ""
    var creatingView = ConnectingView()
    var isFirstTime = Bool()
    var utxo = NSDictionary()
    @IBOutlet var utxoTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        utxoTable.delegate = self
        utxoTable.dataSource = self
        utxoTable.tableFooterView = UIView(frame: .zero)
        refresh()
    }
    
    @IBAction func goToLocked(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToLockedUtxos", sender: vc)
        }
    }
    
    @objc func refresh() {
        addSpinner()
        utxoArray.removeAll()
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
        utxoArray.removeAll()
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return utxoArray.count
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 102
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "utxoCell", for: indexPath)
        
        if utxoArray.count > 0 {
            
            let dict = utxoArray[indexPath.section]
            let address = cell.viewWithTag(1) as! UILabel
            let amount = cell.viewWithTag(4) as! UILabel
            let confs = cell.viewWithTag(8) as! UILabel
            let label = cell.viewWithTag(11) as! UILabel
            let infoButton = cell.viewWithTag(12) as! UIButton
            let lockUtxo = cell.viewWithTag(13) as! UIButton
            
            infoButton.addTarget(self, action: #selector(getInfo(_:)), for: .touchUpInside)
            infoButton.restorationIdentifier = "\(indexPath.section)"
            
            lockUtxo.addTarget(self, action: #selector(lock(_:)), for: .touchUpInside)
            lockUtxo.restorationIdentifier = "\(indexPath.section)"
            
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
    
    @objc func lock(_ sender: UIButton) {
        if sender.restorationIdentifier != nil {
            if let index = Int(sender.restorationIdentifier!) {
                promptToLock(utxoArray[index])
            }
        }
    }
    
    private func promptToLock(_ utxo: [String:Any]) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Lock UTXO?", message: "Locking this utxo will make it unspendable, the utxo will become unlocked automatically if your node reboots, you can always manually unlock it by tapping the lock button in the top right corner to see all locked utxo's.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "lock", style: .default, handler: { [unowned vc = self] action in
                vc.lockUtxo(utxo)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func lockUtxo(_ utxo: [String:Any]) {
        creatingView.addConnectingView(vc: self, description: "locking utxo...")
        let txid = utxo["txid"] as! String
        let vout = utxo["vout"] as! Int
        let param = "false, ''[{\"txid\":\"\(txid)\",\"vout\":\(vout)}]''"
        Reducer.makeCommand(walletName: walletName, command: .lockunspent, param: param) { [unowned vc = self] (object, errorDescription) in
            if let _ = object as? Bool {
                displayAlert(viewController: vc, isError: false, message: "utxo locked")
                vc.getUtxos()
            } else {
                vc.removeSpinner()
                showAlert(vc: vc, title: "Error", message: "There was an error unlocking your utxo: \(errorDescription ?? "unknown")")
            }
        }
    }
    
    @objc func getInfo(_ sender: UIButton) {
        if sender.restorationIdentifier != nil {
            if let index = Int(sender.restorationIdentifier!) {
                utxo = utxoArray[index] as NSDictionary
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.performSegue(withIdentifier: "utxoInfo", sender: vc)
                }
            }
        }
    }
    
    private func parseUnspent(utxos: NSArray) {
        if utxos.count > 0 {
            utxoArray = (utxos as NSArray).sortedArray(using: [NSSortDescriptor(key: "confirmations", ascending: true)]) as! [[String:AnyObject]]
            loadTable()
            removeSpinner()
        } else {
            loadTable()
            removeSpinner()
            showAlert(vc: self, title: "No unlocked UTXO's", message: "If you have any locked UTXO's you can interact with them by tapping the lock button in the top right corner.")
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
             
                vc.utxo = self.utxo
                
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



