//
//  TransactionViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class TransactionViewController: UIViewController {
    
    var txid = ""
    let creatingView = ConnectingView()
    
    @IBOutlet var textView: UITextView!
    
    @IBAction func back(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        creatingView.addConnectingView(vc: self,
                                       description: "getting transaction")
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        executeNodeCommand(method: .gettransaction, param: "\"\(txid)\", true")
        
    }

    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
        
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            
            Reducer.makeCommand(walletName: wallet!.name!, command: .gettransaction, param: param) { (object, errorDescription) in
                
                if let dict = object as? NSDictionary {
                    
                    DispatchQueue.main.async {
                        
                        vc.textView.text = "\(dict)"
                        vc.creatingView.removeConnectingView()
                        
                    }
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "error")
                    
                }
                
            }
                
        }
                
    }

}
