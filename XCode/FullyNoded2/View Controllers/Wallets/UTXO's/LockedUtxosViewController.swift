//
//  LockedUtxosViewController.swift
//  FullyNoded2
//
//  Created by Peter on 08/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class LockedUtxosViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    var creatingView = ConnectingView()
    var utxo = [String:Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        textView.isEditable = false
        getTransaction()
    }
    
    private func getTransaction() {
        creatingView.addConnectingView(vc: self, description: "getting utxo data...")
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                vc.makeCommand(walletName: wallet!.name!)
            } else {
                vc.removeSpinner()
                showAlert(vc: self, title: "Error", message: "No active wallet.")
            }
        }
    }
    
    private func makeCommand(walletName: String) {
        let txid = utxo["txid"] as! String
        let vout = utxo["vout"] as! Int
        Reducer.makeCommand(walletName: walletName, command: .gettransaction, param: "\"\(txid)\", true") { [unowned vc = self] (object, errorDescription) in
            if let transaction = object as? NSDictionary {
                vc.parseTransaction(transaction: transaction, vout: vout)
            } else {
                vc.removeSpinner()
                showAlert(vc: self, title: "Error", message: "There was an error fetching your locked utxo.")
            }
        }
    }
    
    private func parseTransaction(transaction: NSDictionary, vout: Int) {
        if let details = transaction["details"] as? NSArray {
            for output in details {
                if let dict = output as? NSDictionary, let txVout = dict["vout"] as? Int {
                    if vout == txVout {
                        DispatchQueue.main.async { [unowned vc = self] in
                            var text = ""
                            text = "txid: \(transaction["txid"] as! String)\n\n"
                            for (key, value) in (output as! NSDictionary) {
                                if (key as! String) != "category" {
                                    text += "\(key): \(value)\n\n"
                                }
                            }
                            vc.textView.text = text
                            vc.removeSpinner()
                        }
                    }
                } else {
                    removeSpinner()
                    showAlert(vc: self, title: "Error", message: "There was an error parsing your locked utxo.")
                }
            }
        } else {
            removeSpinner()
            showAlert(vc: self, title: "Error", message: "There was an error parsing your locked utxo.")
        }
    }
    
    private func removeSpinner() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.creatingView.removeConnectingView()
        }
    }

}
