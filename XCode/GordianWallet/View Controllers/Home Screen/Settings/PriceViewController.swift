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
    let localeConfig = LocaleConfig()
    let cellReuseIdentifier = "cell"
    var selectedRow: Int = 0
    var selectedRowC: Int = 0
    var selectedRowE: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedRow = priceServer.getCurrentServerIndex()
        selectedRowC = localeConfig.getSavedIndex()
        selectedRowE = priceServer.getSavedExchangeIndex()
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

   func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.priceServer.getServers().count
        } else if section == 1 {
            return self.localeConfig.getCurrencyList().count
        } else {
            return self.priceServer.getExchangeList().count
        }
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell?)!

        if indexPath.section == 0 {
            cell.textLabel?.text = self.priceServer.getServers()[indexPath.row]
        } else if indexPath.section == 1 {
            cell.textLabel?.text = self.localeConfig.getCurrencyList()[indexPath.row]
        } else {
            cell.textLabel?.text = self.priceServer.getExchangeList()[indexPath.row]
        }


        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return true
        } else {
            return false
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Server"
        } else if section == 1 {
            return "Currency"
        } else {
            return "Exchange"
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
        if indexPath.section == 0 {
            priceServer.setCurrentServer(server: priceServer.getServers()[indexPath.row], index: indexPath.row)
            selectedRow = indexPath.row
            print(self.priceServer.getServers())
        } else if indexPath.section == 1 {
            let selectedValue = localeConfig.getCurrencyList()[indexPath.row]
            localeConfig.changeLocale(newLocale: selectedValue)
            selectedRowC = indexPath.row
            selectedRowE = priceServer.getSavedExchangeIndex()
            tableView.reloadData()
        } else {
            let selectedValue = priceServer.getExchangeList()[indexPath.row]
            selectedRowE = indexPath.row
            priceServer.changeExchange(newExchange: selectedValue)
        }
        print(self.priceServer.createSpotBitURL())
        if let unwrappedIndexes = tableView.indexPathsForVisibleRows {
            for cellIndex in unwrappedIndexes {
                if cellIndex.section == indexPath.section {
                    if let unwrappedCell = tableView.cellForRow(at: cellIndex) {
                        unwrappedCell.accessoryType = .none
                    }
                }
            }
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            cell.accessoryType = indexPath.row == selectedRow ? .checkmark : .none
        } else if indexPath.section == 1 {
            cell.accessoryType = indexPath.row == selectedRowC ? .checkmark : .none
        } else {
            cell.accessoryType = indexPath.row == selectedRowE ? .checkmark : .none
        }
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
