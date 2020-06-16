//
//  SeedsViewController.swift
//  FullyNoded2
//
//  Created by Peter on 01/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import AuthenticationServices

class SeedsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var indPath:IndexPath!
    var idToDelete:UUID!
    var addButton = UIBarButtonItem()
    var editButton = UIBarButtonItem()
    var seedsArray = [[String:Any]]()
    @IBOutlet weak var seedsTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        seedsTable.delegate = self
        seedsTable.dataSource = self
        navigationController?.delegate = self
        addButton = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(addSeed))
        editButton = UIBarButtonItem.init(barButtonSystemItem: .edit, target: self, action: #selector(editSeeds))
        navigationItem.setRightBarButtonItems([addButton, editButton], animated: true)
        load()
        
    }
    
    private func load() {
        
        func getWalletLabels() {
            
            for (i, seed) in seedsArray.enumerated() {
                let seedStruct = SeedStruct(dictionary: seed)
                
                SeedParser.parseSeed(seed: seedStruct) { [unowned vc = self] walletsLabels in
                    
                    if walletsLabels != nil {
                        var labels = (walletsLabels!.description).replacingOccurrences(of: "[", with: "")
                        labels = labels.replacingOccurrences(of: "]", with: "")
                        labels = labels.replacingOccurrences(of: "\"", with: "")
                        vc.seedsArray[i]["walletLabel"] = labels
                        
                        if labels == "" {
                            vc.seedsArray[i]["walletLabel"] = "no associated account"
                            
                        }
                        
                    } else {
                        vc.seedsArray[i]["walletLabel"] = "no associated account"
                        
                    }
                    
                    if i + 1 == vc.seedsArray.count {
                        vc.seedsTable.reloadData()
                        
                    }
                    
                }
                
            }
    
        }
        
        CoreDataService.retrieveEntity(entityName: .seeds) { [unowned vc = self] (seeds, errorDescription) in
            
            if seeds != nil {
                
                if seeds!.count > 0 {
                    
                    for (i, seed) in seeds!.enumerated() {
                        vc.seedsArray.append(seed)
                        
                        if i + 1 == seeds!.count {
                            getWalletLabels()
                            
                        }
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seedsArray.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "seedCell", for: indexPath)
        cell.textLabel?.textColor = .lightGray
        cell.textLabel?.text = seedsArray[indexPath.row]["walletLabel"] as? String ?? "not associated with an account"
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let id = seedsArray[indexPath.row]["id"] as? UUID {
                idToDelete = id
                indPath = indexPath
                #if DEBUG
                deleteSeed()
                #else
                showAuth()
                #endif
            }
        }
    }
    
    private func deleteSeed() {
        
        CoreDataService.deleteEntity(id: idToDelete, entityName: .seeds) { [unowned vc = self] (success, errorDescription) in
            
            if success {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.seedsArray.remove(at: vc.indPath.row)
                    vc.seedsTable.deleteRows(at: [vc.indPath], with: .fade)
                    NotificationCenter.default.post(name: .seedDeleted, object: nil, userInfo: nil)
                    
                }
                
            } else {
                displayAlert(viewController: vc, isError: true, message: errorDescription ?? "error")
                
            }
        }
    }
    
    @objc func addSeed() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "addSeedSegue", sender: vc)
            
        }
        
    }
    
    @objc func editSeeds() {
        seedsTable.setEditing(!seedsTable.isEditing, animated: true)
        
        if seedsTable.isEditing {
            editButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(editSeeds))
            
        } else {
            editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editSeeds))
            
        }
        
        navigationItem.setRightBarButtonItems([addButton, editButton], animated: true)
        
    }
    
    func showAuth() {
        
        DispatchQueue.main.async {
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
            
        }
        
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let data = KeyChain.getData("userIdentifier") {
            if let username = String(data: data, encoding: .utf8) {
                switch authorization.credential {

                case _ as ASAuthorizationAppleIDCredential:
                    let authorizationProvider = ASAuthorizationAppleIDProvider()
                    authorizationProvider.getCredentialState(forUserID: username) { [unowned vc = self] (state, error) in
                        
                        switch (state) {
                            
                        case .authorized:
                            print("Account Found - Signed In")
                            vc.deleteSeed()
                            
                        case .revoked:
                            print("No Account Found")
                            fallthrough
                            
                        case .notFound:
                            print("No Account Found")
                            
                        default:
                            break
                            
                        }
                        
                    }
                    
                default:

                    break

                }

            }
                
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "addSeedSegue":
            
            if let vc = segue.destination as? WordRecoveryViewController {
                
                vc.addingIndpendentSeed = true
                
            }
            
        default:
            break
            
        }
        
    }

}
