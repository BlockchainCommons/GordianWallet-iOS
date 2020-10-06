//
//  NodeManagerViewController.swift
//  StandUp-Remote
//
//  Created by Peter on 31/01/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class NodeManagerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {

    @IBOutlet var table: UITableView!
    var nodes = [[String:Any]]()
    var addButton = UIBarButtonItem()
    var editButton = UIBarButtonItem()
    var id:UUID!
    var url = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        table.delegate = self
        table.dataSource = self
        navigationController?.delegate = self
        addButton = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(addNode))
        editButton = UIBarButtonItem.init(barButtonSystemItem: .edit, target: self, action: #selector(editNodes))
        self.navigationItem.setRightBarButtonItems([addButton, editButton], animated: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        load()
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @objc func addNode() {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            self.performSegue(withIdentifier: "addNode", sender: self)
            
        }
        
    }
    
    @objc func editNodes() {
        
        table.setEditing(!table.isEditing, animated: true)
        
        if table.isEditing {
            
            editButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(editNodes))
            
        } else {
            
            editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editNodes))
            
        }
        
        self.navigationItem.setRightBarButtonItems([addButton, editButton], animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let id = nodes[indexPath.section]["id"] as! UUID
            
            CoreDataService.retrieveEntity(entityName: .wallets) { [unowned vc = self] (wallets, errorDescription) in
                
                if errorDescription == nil && wallets != nil {
                    
                    var walletsExist = false
                    
                    for wallet in wallets! {
                        
                        let w = WalletStruct(dictionary: wallet)
                        
                        if w.nodeId == id && !w.isArchived {
                            
                            walletsExist = true
                            
                        }
                        
                    }
                    
                    if !walletsExist {
                        
                        CoreDataService.deleteEntity(id: id, entityName: .nodes) { [unowned vc = self] (success, errorDescription) in
                            
                            if success {
                                                    
                                DispatchQueue.main.async {
                                    
                                    vc.nodes.remove(at: indexPath.section)
                                    tableView.deleteSections(IndexSet.init(arrayLiteral: indexPath.section), with: .fade)
                                    NotificationCenter.default.post(name: .nodeSwitched, object: nil, userInfo: nil)
                                    
                                }
                                
                            } else {
                                
                                displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error")
                                
                            }
                            
                        }
                        
                    } else {
                        
                        showAlert(vc: vc, title: "Warning!", message: "That node has wallets associated with it! If you want to delete a node you first need to delete its wallets, ensure you sweep those wallets to a new node first or recover them on your new node.\n\nOnce all wallets associated with this node have been deleted you may delete the node, we do this to prevent you from accidentally deleting a node with wallets.")
                        
                    }
                    
                }
                
            }
                        
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section
        let node = NodeStruct.init(dictionary: nodes[section])
        id = node.id
         
        DispatchQueue.main.async {

            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()

        }
        
        refreshCredentials(node: node)
        
    }
    
    private func refreshCredentials(node: NodeStruct!) {
        
        DispatchQueue.main.async {
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            
            let alert = UIAlertController(title: "Choose an option", message: "You may update the nodes credentials which is useful if you have changed your hidden service url or rpc credentials. Or you may share the node with trusted others.", preferredStyle: alertStyle)

            alert.addAction(UIAlertAction(title: "Update this node", style: .default, handler: { [unowned vc = self] action in
                
                DispatchQueue.main.async {
                    
                    vc.performSegue(withIdentifier: "updateNode", sender: self)
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Share this node", style: .default, handler: { [unowned vc = self] action in
                
                DispatchQueue.main.async {
                    
                    let onionAddress = node.onionAddress
                    let rpcusername = node.rpcuser
                    let rpcpassword = node.rpcpassword
                    let label = (node.label).replacingOccurrences(of: " ", with: "%20")
                    vc.url = "btcstandup://\(rpcusername):\(rpcpassword)@\(onionAddress)/?label=\(label)"
                    vc.performSegue(withIdentifier: "shareNode", sender: vc)
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    func load() {
        
        self.nodes.removeAll()
        
        CoreDataService.retrieveEntity(entityName: .nodes) { [unowned vc = self] (nodes, errorDescription) in
            
            if errorDescription == nil {
                                
                for (i, node) in nodes!.enumerated() {
                    
                    vc.nodes.append(node)
                    
                    for (key, value) in node {
                        
                        if key != "isActive" && key != "id" && key != "network" {
                            
                            let encryptedData = value as! Data
                            Encryption.decryptData(dataToDecrypt: encryptedData) { (decryptedData) in
                                
                                if decryptedData != nil {
                                    
                                    let decryptedString = String(bytes: decryptedData!, encoding: .utf8)
                                    vc.nodes[i][key] = decryptedString!
                                    
                                }
                                
                            }
                            
                        }
                                                
                    }
                    
                    if i + 1 == nodes!.count {
                        
                        DispatchQueue.main.async {
                            
                            vc.table.reloadData()
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: errorDescription!)
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return nodes.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeCell", for: indexPath)
        
        cell.selectionStyle = .none
        let nodeLabel = cell.viewWithTag(1) as! UILabel
        let onionAddress = cell.viewWithTag(2) as! UILabel
        let isActive = cell.viewWithTag(3) as! UISwitch
        let node = NodeStruct.init(dictionary: nodes[indexPath.section])
        nodeLabel.text = node.label
        let onion = node.onionAddress
        isActive.isOn = node.isActive
        isActive.addTarget(self, action: #selector(alternate(_:)), for: .touchUpInside)
        isActive.restorationIdentifier = "\(indexPath.section)"
        
        let first10 = String(onion.prefix(10))
        let last15 = String(onion.suffix(15))
        
        onionAddress.text = "\(first10)*****\(last15)"
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 58
        
    }
    
    @objc func alternate(_ sender: UISwitch) {
        if sender.restorationIdentifier != nil {
            if let section = Int(sender.restorationIdentifier!) {
                let node = nodes[section]
                let idToActivate = NodeStruct.init(dictionary: node).id
                if sender.isOn {
                    //turning on
                    makeActive(nodeToActivate: idToActivate)
                } else {
                    table.reloadSections([section], with: .fade)
                    showAlert(vc: self, title: "Alert", message: "You must always have one active node, if you would like to use a different node simply switch it on and the other nodes will be switched off automatically.")
                }
            }
        }
    }
    
    func makeActive(nodeToActivate: UUID) {
        
        CoreDataService.retrieveEntity(entityName: .nodes) { [unowned vc = self] (nodes, errorDescription) in
            
            if errorDescription == nil {
                
                if nodes!.count > 0 {
                    
                    for node in nodes! {
                        
                        let str = NodeStruct.init(dictionary: node)
                        
                        if str.id == nodeToActivate {
                            
                            CoreDataService.updateEntity(id: nodeToActivate, keyToUpdate: "isActive", newValue: true, entityName: .nodes) { (success, errorDescription) in
                                
                                if success {
                                    
                                   vc.deactivateOtherNodes(nodeToActivate: nodeToActivate)
                                    
                                } else {
                                    
                                    displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error deactivating node")
                                    
                                }
                                
                            }
                            
                        }
                        
                    }

                }
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: "error deactivating node: \(errorDescription!)")
                
            }
            
        }
        
    }
    
    func deactivateOtherNodes(nodeToActivate: UUID) {
        CoreDataService.retrieveEntity(entityName: .nodes) { [unowned vc = self] (nodes, errorDescription) in
            if errorDescription == nil {
                if nodes!.count > 0 {
                    for (i, node) in nodes!.enumerated() {
                        let str = NodeStruct.init(dictionary: node)
                        if str.id != nodeToActivate {
                            CoreDataService.updateEntity(id: str.id, keyToUpdate: "isActive", newValue: false, entityName: .nodes) { (success1, errorDescription1) in
                                if !success1 {
                                    displayAlert(viewController: vc, isError: true, message: errorDescription1 ?? "error updating")
                                }
                            }
                        }
                        if i + 1 == nodes!.count {
                            vc.load()
                            vc.deactiveateWallets()
                        }
                    }
                }
            }
        }
    }
    
    private func deactiveateWallets() {
        
        CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
            
            if wallets != nil {
                
                for (i, wallet) in wallets!.enumerated() {
                    
                    if wallet["id"] != nil && wallet["isArchived"] != nil && wallet["nodeId"] != nil {
                        let w = WalletStruct(dictionary: wallet)
                        
                        if !w.isArchived && w.isActive {
                            
                            CoreDataService.updateEntity(id: w.id!, keyToUpdate: "isActive", newValue: false, entityName: .wallets) { (success, errorDescription) in
                                
                                if success {
                                    #if DEBUG
                                    print("wallet deactived after switching nodes")
                                    #endif
                                    
                                } else {
                                    #if DEBUG
                                    print("wallet deactivation failed after switching nodes!")
                                    #endif
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    if i + 1 == wallets!.count {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .nodeSwitched, object: nil, userInfo: nil)
                        }
                    }
                }
                
            }
            
        }
        
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        switch id {
            
        case "updateNode":
            
            if let vc = segue.destination as? ScannerViewController {
                
                vc.updatingNode = true
                vc.nodeId = self.id
                vc.onDoneBlock = { [unowned thisVc = self] result in
                    
                    showAlert(vc: thisVc, title: "Node Updated!", message: "The nodes credentials were successfully updated")
                    thisVc.load()
                    
                }
                
            }
            
        case "addNode":
            
            if let vc = segue.destination as? ScannerViewController {
                
                vc.scanningNode = true
                vc.onDoneBlock = { [unowned thisVc = self] result in
                    thisVc.deactiveateWallets()
                    thisVc.load()
                }
                
            }
            
        case "shareNode":
            
            if let vc = segue.destination as? QRDisplayerViewController {
                
                vc.address = url
                
            }
            
        default:
            
            break
            
        }
        
    }
    

}
