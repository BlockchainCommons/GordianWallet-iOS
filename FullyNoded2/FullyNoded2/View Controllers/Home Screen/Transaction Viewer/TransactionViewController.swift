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
        
        executeNodeCommand(method: BTC_CLI_COMMAND.gettransaction,
                              param: "\"\(txid)\", true")
        
    }

    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
        
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            
            let reducer = Reducer()
            
            func getResult() {
                
                if !reducer.errorBool {
                    
                    switch method {
                        
                    case BTC_CLI_COMMAND.gettransaction:
                        
                        if let dict = reducer.dictToReturn {
                            
                            DispatchQueue.main.async {
                                
                                vc.textView.text = "\(dict)"
                                vc.creatingView.removeConnectingView()
                                
                            }
                            
                        } else {
                            
                            vc.creatingView.removeConnectingView()
                            
                            displayAlert(viewController: vc,
                                         isError: true,
                                         message: "error")
                            
                        }
                        
                    default:
                        
                        break
                        
                    }
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    
                    displayAlert(viewController: vc,
                                 isError: true,
                                 message: reducer.errorDescription)
                    
                }
                
            }

            
            if wallet != nil && !error {
                
                reducer.makeCommand(walletName: wallet!.name, command: method,
                                    param: param,
                                    completion: getResult)
                
            }
            
        }
        
    }

}
