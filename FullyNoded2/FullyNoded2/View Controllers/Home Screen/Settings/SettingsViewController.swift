//
//  SettingsViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//
import KeychainSwift
import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let ud = UserDefaults.standard
    var miningFeeText = ""
    @IBOutlet var settingsTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsTable.delegate = self
        
    }

    override func viewDidAppear(_ animated: Bool) {
        
        load()
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
    func load() {
        
        DispatchQueue.main.async {
            
            self.settingsTable.reloadData()
            
        }
        
    }
    
    func updateFeeLabel(label: UILabel, numberOfBlocks: Int) {
        
        let seconds = ((numberOfBlocks * 10) * 60)
        
        func updateFeeSetting() {
            
            ud.set(numberOfBlocks, forKey: "feeTarget")
            
        }
        
        DispatchQueue.main.async {
            
            if seconds < 86400 {
                
                if seconds < 3600 {
                    
                    DispatchQueue.main.async {
                        
                        label.text = "Confirmation target \(numberOfBlocks) blocks (\(seconds / 60) minutes)"
                        
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        
                        label.text = "Confirmation target \(numberOfBlocks) blocks (\(seconds / 3600) hours)"
                        
                    }
                    
                }
                
            } else {
                
                DispatchQueue.main.async {
                    
                    label.text = "Confirmation target \(numberOfBlocks) blocks (\(seconds / 86400) days)"
                    
                }
                
            }
            
            updateFeeSetting()
            
        }
            
    }
    
    @objc func setFee(_ sender: UISlider) {
        
        let cell = settingsTable.cellForRow(at: IndexPath.init(row: 0, section: 4))
        let label = cell?.viewWithTag(1) as! UILabel
        let numberOfBlocks = Int(sender.value) * -1
        updateFeeLabel(label: label, numberOfBlocks: numberOfBlocks)
            
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let settingsCell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        let label = settingsCell.viewWithTag(1) as! UILabel
        label.textColor = .lightGray
        let thumbnail = settingsCell.viewWithTag(2) as! UIImageView
        settingsCell.selectionStyle = .none
        
        switch indexPath.section {
            
        case 0:
            
            thumbnail.image = UIImage(systemName: "lock.shield")
            label.text = "Security Center"
            return settingsCell
            
        case 1:
            
            thumbnail.image = UIImage(systemName: "lock.shield")
            label.text = "Export Authentication Public Key"
            return settingsCell
            
        case 2:
            
            thumbnail.image = UIImage(systemName: "desktopcomputer")
            label.text = "Node Manager"
            return settingsCell
            
        case 3:
            
            thumbnail.image = UIImage(systemName: "exclamationmark.triangle")
            label.text = "Reset app"
            return settingsCell
            
        case 4:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "miningFeeCell", for: indexPath)
            let label = cell.viewWithTag(1) as! UILabel
            let slider = cell.viewWithTag(2) as! UISlider
            let thumbnail = cell.viewWithTag(3) as! UIImageView
            thumbnail.image = UIImage(systemName: "timer")
            
            slider.addTarget(self, action: #selector(setFee), for: .allEvents)
            slider.maximumValue = 2 * -1
            slider.minimumValue = 432 * -1
            
            if ud.object(forKey: "feeTarget") != nil {
                
                let numberOfBlocks = ud.object(forKey: "feeTarget") as! Int
                slider.value = Float(numberOfBlocks) * -1
                updateFeeLabel(label: label, numberOfBlocks: numberOfBlocks)
                
            } else {
                
                label.text = "Minimum fee set"
                slider.value = 432 * -1
                
            }
            
            label.text = ""
            
            return cell
            
        default:
            
            let cell = UITableViewCell()
            cell.backgroundColor = UIColor.clear
            return cell
            
        }
        
        }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 5
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 20
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
        case 0:
            
            return 50
            
        default:
            
            return 30
            
        }
                
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        DispatchQueue.main.async {
            
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            
        }
        
        switch indexPath.section {
            
        case 0:
            
            goToSecurityCenter()
            
        case 1:
            
            goToAuth()
            
        case 2:
            
            nodeManager()
            
        case 3:
        
            resetApp()
            
        default:
            
            break
            
        }
        
    }
    
    func goToSecurityCenter() {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "security", sender: self)
            
        }
        
    }
    
    func resetApp() {
        
        let cd = CoreDataService()
        let ud = UserDefaults.standard
        
        let domain = Bundle.main.bundleIdentifier!
        ud.removePersistentDomain(forName: domain)
        ud.synchronize()
        
        cd.retrieveEntity(entityName: .nodes) { (nodes, errorDescription) in
            
            if nodes != nil {
                
               for n in nodes! {
                    
                    let str = NodeStruct(dictionary: n)
                    let id = str.id
                    
                    cd.deleteEntity(id: id, entityName: .nodes) {
                        
                        if !cd.errorBool {
                            
                            let success = cd.boolToReturn
                            
                            if success {
                                
                                cd.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                                    
                                    if wallets != nil {
                                        
                                        for h in wallets! {
                                            
                                            let str = WalletStruct(dictionary: h)
                                            let id = str.id
                                            
                                            cd.deleteEntity(id: id, entityName: .wallets) {
                                                
                                                if !cd.errorBool {
                                                    
                                                    let success = cd.boolToReturn
                                                    
                                                    if success {
                                                        
                                                        let keychain = KeychainSwift()
                                                        
                                                        if keychain.clear() {
                                                            
                                                            displayAlert(viewController: self, isError: false, message: "app has been reset")
                                                            
                                                        } else {
                                                            
                                                            displayAlert(viewController: self, isError: true, message: "app reset partially failed")
                                                            
                                                        }
                                                        
                                                    } else {
                                                        
                                                        displayAlert(viewController: self, isError: true, message: "app reset partially failed")
                                                        
                                                    }
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            } else {
                                
                                displayAlert(viewController: self, isError: true, message: "app reset failed")
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func nodeManager() {
        
        DispatchQueue.main.async {
        
            self.performSegue(withIdentifier: "nodeManager", sender: self)
            
        }
        
    }
    
    func goToAuth() {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "goToAuth", sender: self)
            
        }
        
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        let id = segue.identifier
//
//        switch id {
//
//        default:
//
//            break
//
//        }
//
//    }
    
}



