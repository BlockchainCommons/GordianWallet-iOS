//
//  VerifyKeysViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 07/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class VerifyKeysViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var address = ""
    var words = ""
    var derivation = ""
    var keys = [String]()
    let connectingView = ConnectingView()
    var wallet:WalletStruct!
    @IBOutlet var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        loadActiveWallet()
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    func labelText(derivation: String) -> String {
        
        if derivation.contains("84") {
            
            return "Native Segwit Account 0 (BIP84 \(derivation))"
            
        } else if derivation.contains("44") {
            
            return "Legacy Account 0 (BIP44 \(derivation))"
            
        } else if derivation.contains("49") {
            
            return "P2SH Nested Segwit Account 0 (BIP49 \(derivation))"
            
        } else {
            
            return ""
            
        }
        
    }
    
    func loadActiveWallet() {
        
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            
            if wallet != nil && !error {
                
                vc.wallet = wallet!
                vc.getKeysFromBitcoinCore()
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 77
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return keys.count
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Index #\(section)"
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "keyCell", for: indexPath)
        cell.selectionStyle = .none
        
        let keyLabel = cell.viewWithTag(2) as! UILabel
        let pathLabel = cell.viewWithTag(3) as! UILabel
        
        pathLabel.text = "\(wallet.derivation)/0/\(indexPath.section)"
        keyLabel.text = "\(keys[indexPath.section])"
        
        keyLabel.adjustsFontSizeToFitWidth = true
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        
    }
    
    func getKeysFromBitcoinCore() {
        
        connectingView.addConnectingView(vc: self, description: "getting the addresses from your node")
        
        Reducer.makeCommand(walletName: wallet.name!, command: .deriveaddresses, param: "\"\(wallet.descriptor)\", ''[0,999]''") { [unowned vc = self] (object, errorDesc)  in
            
            if let result = object as? NSArray {
                
                vc.keys = result as! [String]
                
                DispatchQueue.main.async {
                    
                    vc.table.reloadData()
                    
                }
                
                vc.connectingView.removeConnectingView()
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: "error getting addresses from your node")
                vc.connectingView.removeConnectingView()
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
        (view as! UITableViewHeaderFooterView).textLabel?.alpha = 1
        
    }

}
