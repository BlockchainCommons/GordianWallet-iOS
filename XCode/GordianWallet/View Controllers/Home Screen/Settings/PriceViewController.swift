//
//  PriceViewController.swift
//  FullyNoded2
//
//  Created by Gautham Elango on 22/7/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class PriceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    var editButton = UIBarButtonItem()
    var addButton = UIBarButtonItem()
    
    let priceServer = PriceServer()
    let cellReuseIdentifier = "cell"
    var selectedRow = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedRow = priceServer.getCurrentServerIndex()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        editButton = UIBarButtonItem.init(barButtonSystemItem: .edit, target: self, action: #selector(editNodes))
        addButton = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(addNode))
        if priceServer.getServers().count == 1 {
            self.navigationItem.setRightBarButtonItems([addButton], animated: true)
        } else {
            self.navigationItem.setRightBarButtonItems([addButton, editButton], animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.priceServer.getServers().count
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
 
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell?)!
        cell.textLabel?.text = self.priceServer.getServers()[indexPath.row]
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
        //if let cell = tableView.cellForRow(at: indexPath) {
        //    cell.accessoryType = .checkmark
        //
        //}
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        //    tableView.deselectRow(at: indexPath, animated: true)
        //}
        priceServer.setCurrentServer(server: priceServer.getServers()[indexPath.row], index: indexPath.row)
        print(self.priceServer.getServers())
        print(self.priceServer.createSpotBitURL())
        selectedRow = indexPath.row
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.accessoryType = indexPath.row == selectedRow ? .checkmark : .none
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) && (priceServer.getServers().count > 1) {
            priceServer.removeServerByIndex(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            if priceServer.getCurrentServerIndex() == indexPath.row {
                selectedRow = 0
                priceServer.setCurrentServer(server: priceServer.getServers()[0], index: 0)
                tableView.reloadData()
            }
            print(self.priceServer.getServers())
            print(self.priceServer.createSpotBitURL())
        } else if editingStyle == .insert {
            
        }
    }
    
    @objc func editNodes() {
        
        tableView.setEditing(!tableView.isEditing, animated: true)
        
        if tableView.isEditing {
            
            editButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(editNodes))
            
        } else {
            
            editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editNodes))
            
        }
        
        if priceServer.getServers().count == 1 {
            self.navigationItem.setRightBarButtonItems([addButton], animated: true)
        } else {
            self.navigationItem.setRightBarButtonItems([addButton, editButton], animated: true)
        }
        
    }
    
    @objc func addNode() {
        
        let alert = UIAlertController(title: "Enter Spotbit server", message: "Format: spotbitaddress.onion without http://", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = ""
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            let valu = "0"
            print("Text field: \(textField?.text ?? valu)")
            self.priceServer.addServer(server: (textField?.text)!)
            self.tableView.reloadData()
            print(self.priceServer.getServers())
            print(self.priceServer.createSpotBitURL())
            if self.priceServer.getServers().count == 1 {
                self.navigationItem.setRightBarButtonItems([self.addButton], animated: true)
            } else {
                self.navigationItem.setRightBarButtonItems([self.addButton, self.editButton], animated: true)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
        
    }
}
