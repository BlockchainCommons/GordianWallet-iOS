//
//  VerifyKeysViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 07/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class VerifyKeysViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var address = ""
    var words = ""
    var derivation = ""
    var keys = [String]()
    var comingFromSettings = Bool()
    let connectingView = ConnectingView()
    var wallet:WalletStruct!
    @IBOutlet var table: UITableView!
    @IBOutlet var saveButtonOutlet: UIButton!
    @IBOutlet var derivationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        if comingFromSettings {
            
            saveButtonOutlet.alpha = 0
            
        }
        
        saveButtonOutlet.clipsToBounds = true
        saveButtonOutlet.layer.cornerRadius = 8
        derivationLabel.adjustsFontSizeToFitWidth = true
        derivationLabel.text = ""
        loadActiveWallet()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if comingFromSettings {
            
            table.translatesAutoresizingMaskIntoConstraints = true
            table.frame = CGRect(x: table.frame.origin.x, y: table.frame.origin.y, width: table.frame.width, height: view.frame.height)
            
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    func addExistingDerivationLabel() {
        
        let derivation = wallet.derivation
        derivationLabel.text = labelText(derivation: derivation)
        derivationLabel.adjustsFontSizeToFitWidth = true
        
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
        print("loadActiveWallet")
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil && !error {
                
                self.wallet = wallet!
                self.getKeysFromBitcoinCore()
                
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
        
        let index = indexPath.section
        address = keys[index]
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "verifyAddress", sender: self)
            
        }
        
    }
    
    func getKeysFromBitcoinCore() {
        
        connectingView.addConnectingView(vc: self, description: "getting the addresses from your node")
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: wallet.name, command: .deriveaddresses, param: "\"\(wallet.descriptor)\", ''[0,999]''") {
            
            if !reducer.errorBool {
                
                let result = reducer.arrayToReturn
                self.keys = result as! [String]
                
                DispatchQueue.main.async {
                    
                    self.table.reloadData()
                    
                }
                
                self.connectingView.removeConnectingView()
                
            } else {
                
                displayAlert(viewController: self, isError: true, message: "error getting addresses from your node")
                self.connectingView.removeConnectingView()
                
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        switch id {
            
        case "verifyAddress":
            
            if let vc = segue.destination as? VerifyAddressViewController {
                
                vc.address = address
                
            }
            
        default:
            
            break
            
        }
        
    }

}
