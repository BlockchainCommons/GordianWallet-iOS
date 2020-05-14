//
//  ConfirmViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit
import AuthenticationServices
import LibWally

class ConfirmViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var psbtDict = ""
    var doneBlock: ((Bool) -> Void)?
    let creatingView = ConnectingView()
    var unsignedPsbt = ""
    var signedRawTx = ""
    var outputsString = ""
    var inputsString = ""
    var inputArray = [[String:Any]]()
    var inputTableArray = [[String:Any]]()
    var outputArray = [[String:Any]]()
    var index = Int()
    var inputTotal = Double()
    var outputTotal = Double()
    var miningFee = ""
    var recipients = [String]()
    var addressToVerify = ""
    var sweeping = Bool()
    @IBOutlet var confirmTable: UITableView!
    @IBOutlet var broadcastButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        
        if unsignedPsbt == "" {
            
            creatingView.addConnectingView(vc: self, description: "verifying signed transaction")
            executeNodeCommand(method: .decoderawtransaction, param: "\"\(signedRawTx)\"")
            
        } else {
            
            let exportImage = UIImage(systemName: "arrowshape.turn.up.right")!
            broadcastButton.setImage(exportImage, for: .normal)
            broadcastButton.setTitle("  Export PSBT", for: .normal)
            creatingView.addConnectingView(vc: self, description: "verifying psbt")
            executeNodeCommand(method: .decodepsbt, param: "\"\(unsignedPsbt)\"")
            
        }
        
    }
    
    @IBAction func sendNow(_ sender: Any) {
        
        if unsignedPsbt == "" {
            
            DispatchQueue.main.async {
                            
                let alert = UIAlertController(title: "Broadcast transaction?", message: "We use blockstream's esplora Tor V3 api to broadcast your transactions for improved privacy. Once you broadcast there is no going back!", preferredStyle: .actionSheet)

                alert.addAction(UIAlertAction(title: "Yes, broadcast now", style: .default, handler: { [unowned vc = self] action in
                    
                    #if !targetEnvironment(simulator)
                    vc.showAuth()
                    #else
                    vc.broadcast()
                    #endif
                                        
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                alert.popoverPresentationController?.sourceView = self.view
                self.present(alert, animated: true, completion: nil)
                
            }
            
        } else {
            
            showPsbtOptions()
            
        }
        
    }
    
    func showPsbtOptions() {
        
        DispatchQueue.main.async {
                        
            let alert = UIAlertController(title: "Export as:", message: "", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: ".psbt data file", style: .default, handler: { [unowned vc = self] action in
                
                vc.convertPSBTtoData(string: vc.unsignedPsbt)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Base64 encoded text", style: .default, handler: { [unowned vc = self] action in
                
                DispatchQueue.main.async {
                    
                    let textToShare = [vc.unsignedPsbt]
                    
                    let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                          applicationActivities: nil)
                    
                    activityViewController.popoverPresentationController?.sourceView = vc.view
                    vc.present(activityViewController, animated: true) {}
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Plain text", style: .default, handler: { [unowned vc = self] action in
                
                DispatchQueue.main.async {
                    
                    let textToShare = [vc.psbtDict]
                    
                    let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                          applicationActivities: nil)
                    
                    activityViewController.popoverPresentationController?.sourceView = vc.view
                    vc.present(activityViewController, animated: true) {}
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    func stripPSBTdownForSpecter(psbt: String) {
        
//        Reducer.makeCommand(walletName: "", command: .decodepsbt, param: "\"\(psbt)\"") { (object, errorDescription) in
//
//            if let decodedPsbt = object as? NSDictionary {
//                let strippedPsbt1: NSMutableDictionary = NSMutableDictionary(dictionary: decodedPsbt)
//                strippedPsbt1.removeObjects(forKeys: ["fee"])
//                let inputs = decodedPsbt["inputs"] as! NSArray
//                let outputs = decodedPsbt["outputs"] as! NSArray
//                let strippedInputs:NSMutableArray = []
//                let strippedOutputs:NSMutableArray = []
//
//                for (i, input) in inputs.enumerated() {
//                    let dict = input as! NSDictionary
//                    let mutable = NSMutableDictionary(dictionary: dict)
//                    mutable.removeObjects(forKeys: ["witness_script", "bip32_derivs", "witness_utxo"])
//                    strippedInputs.add(mutable)
//
//                    if i + 1 == inputs.count {
//                        strippedPsbt1.setValue(strippedInputs, forKey: "inputs")
//
//                    }
//                }
//
//                for (i, output) in outputs.enumerated() {
//                    let dict = output as! NSDictionary
//                    let mutable = NSMutableDictionary(dictionary: dict)
//                    mutable.removeObjects(forKeys: ["witness_script", "bip32_derivs"])
//                    strippedOutputs.add(mutable)
//
//                    if i + 1 == outputs.count {
//                        strippedPsbt1.setValue(strippedOutputs, forKey: "outputs")
//
//                    }
//                }
//
//
//
//            } else {
//                print("error parsing result")
//
//            }
//
//        }
        
        /*
         {
             fee = "2.01e-06";
             inputs =     (
                         {
                     "bip32_derivs" =             (
                                         {
                             "master_fingerprint" = 5222e39c;
                             path = "m/48'/1'/0'/2'/0/2";
                             pubkey = 02605fda0f9dc0f16b83167f12ddbebe52e0c9df804cb04d0500cfa154b150a8c9;
                         },
                                         {
                             "master_fingerprint" = 82be8e74;
                             path = "m/48'/1'/0'/2'/0/2";
                             pubkey = 0286392f732c9eef76d4779604d0b1ec14a10d91ce6a3cec06101e9a839a7147d8;
                         },
                                         {
                             "master_fingerprint" = 81202613;
                             path = "m/48'/1'/0'/2'/0/2";
                             pubkey = 03a8c367c69f821ac284b7b2018eeec8e66ac8e2d5516550e78181ddf8b7cdd84d;
                         }
                     );
                     "partial_signatures" =             {
                         02605fda0f9dc0f16b83167f12ddbebe52e0c9df804cb04d0500cfa154b150a8c9 = 304402207213f46467c8f86de6289aa8daffd6a25d52fbfdc5c26acfaf4e86b63a1a9b4402205be6dc9e8fcd22f42fae7b891c54b38026d0789a903f8ecbbabea70e1af920ad01;
                     };
                     "witness_script" =             {
                         asm = "2 02605fda0f9dc0f16b83167f12ddbebe52e0c9df804cb04d0500cfa154b150a8c9 0286392f732c9eef76d4779604d0b1ec14a10d91ce6a3cec06101e9a839a7147d8 03a8c367c69f821ac284b7b2018eeec8e66ac8e2d5516550e78181ddf8b7cdd84d 3 OP_CHECKMULTISIG";
                         hex = 522102605fda0f9dc0f16b83167f12ddbebe52e0c9df804cb04d0500cfa154b150a8c9210286392f732c9eef76d4779604d0b1ec14a10d91ce6a3cec06101e9a839a7147d82103a8c367c69f821ac284b7b2018eeec8e66ac8e2d5516550e78181ddf8b7cdd84d53ae;
                         type = multisig;
                     };
                     "witness_utxo" =             {
                         amount = "0.000111";
                         scriptPubKey =                 {
                             address = tb1qxcznacpt4y5pzpqxhueqyp7vsprq0ysyska0sq9sqfez5fv0y0nspmg7rr;
                             asm = "0 36053ee02ba928110406bf320207cc804607920485baf800b002722a258f23e7";
                             hex = 002036053ee02ba928110406bf320207cc804607920485baf800b002722a258f23e7;
                             type = "witness_v0_scripthash";
                         };
                     };
                 }
             );
             outputs =     (
                         {
                     "bip32_derivs" =             (
                                         {
                             "master_fingerprint" = 82be8e74;
                             path = "m/48'/1'/0'/2'/1/4";
                             pubkey = 0216af4b360ff03c5d4d93c568446a713d31ba877cf083e2d2d9217ce7578303a7;
                         },
                                         {
                             "master_fingerprint" = 81202613;
                             path = "m/48'/1'/0'/2'/1/4";
                             pubkey = 029af5301c82878b63571eba90c9f483b0e4d4d739897e16b846d766fb9b8a339c;
                         },
                                         {
                             "master_fingerprint" = 5222e39c;
                             path = "m/48'/1'/0'/2'/1/4";
                             pubkey = 036953a379bd46894488927bd1cc1509ff3dcf1a280bbe901c56c59d8dee03a8f5;
                         }
                     );
                     "witness_script" =             {
                         asm = "2 0216af4b360ff03c5d4d93c568446a713d31ba877cf083e2d2d9217ce7578303a7 029af5301c82878b63571eba90c9f483b0e4d4d739897e16b846d766fb9b8a339c 036953a379bd46894488927bd1cc1509ff3dcf1a280bbe901c56c59d8dee03a8f5 3 OP_CHECKMULTISIG";
                         hex = 52210216af4b360ff03c5d4d93c568446a713d31ba877cf083e2d2d9217ce7578303a721029af5301c82878b63571eba90c9f483b0e4d4d739897e16b846d766fb9b8a339c21036953a379bd46894488927bd1cc1509ff3dcf1a280bbe901c56c59d8dee03a8f553ae;
                         type = multisig;
                     };
                 },
                         {
                     "bip32_derivs" =             (
                                         {
                             "master_fingerprint" = 82be8e74;
                             path = "m/48'/1'/0'/2'/0/4";
                             pubkey = 02361b2143b5ad78221320e9259a835aea2c4ed37e7e4ac7fa4ad4e14823e1c71f;
                         },
                                         {
                             "master_fingerprint" = 5222e39c;
                             path = "m/48'/1'/0'/2'/0/4";
                             pubkey = 0265361dcdd9591b5be0c6df90f5413fb0dd93fc039ddaf50956a6e2def73db2f7;
                         },
                                         {
                             "master_fingerprint" = 81202613;
                             path = "m/48'/1'/0'/2'/0/4";
                             pubkey = 034f1c0d38c14d452f69e0c5c3f1585ce210b61c4bdb12b488eb7bab818af3572b;
                         }
                     );
                     "witness_script" =             {
                         asm = "2 02361b2143b5ad78221320e9259a835aea2c4ed37e7e4ac7fa4ad4e14823e1c71f 0265361dcdd9591b5be0c6df90f5413fb0dd93fc039ddaf50956a6e2def73db2f7 034f1c0d38c14d452f69e0c5c3f1585ce210b61c4bdb12b488eb7bab818af3572b 3 OP_CHECKMULTISIG";
                         hex = 522102361b2143b5ad78221320e9259a835aea2c4ed37e7e4ac7fa4ad4e14823e1c71f210265361dcdd9591b5be0c6df90f5413fb0dd93fc039ddaf50956a6e2def73db2f721034f1c0d38c14d452f69e0c5c3f1585ce210b61c4bdb12b488eb7bab818af3572b53ae;
                         type = multisig;
                     };
                 }
             );
             tx =     {
                 hash = 5901935ef956f7bb6c05afbfbd41b0c43c150f1a5a5af3b8bc0e0b7c0f3abd96;
                 locktime = 0;

                 size = 137;
                 txid = 5901935ef956f7bb6c05afbfbd41b0c43c150f1a5a5af3b8bc0e0b7c0f3abd96;
                 version = 2;
                 vin =         (
                                 {
                         scriptSig =                 {
                             asm = "";
                             hex = "";
                         };
                         sequence = 4294967293;
                         txid = 7b7bb719a4ea0f4f684e14b48d319e75b5dfaf42d9991136f4addf756de44566;
                         vout = 1;
                     }
                 );
                 vout =         (
                                 {
                         n = 0;
                         scriptPubKey =                 {
                             addresses =                     (
                                 tb1qsyvfsvcj9yv8zxgxwn05huq0fsgvag8ed95p2sc2fz4gn0mqtwlsmrvjuw
                             );
                             asm = "0 8118983312291871190674df4bf00f4c10cea0f9696815430a48aa89bf605bbf";
                             hex = 00208118983312291871190674df4bf00f4c10cea0f9696815430a48aa89bf605bbf;
                             reqSigs = 1;
                             type = "witness_v0_scripthash";
                         };
                         value = "8.99e-06";
                     },
                                 {
                         n = 1;
                         scriptPubKey =                 {
                             addresses =                     (
                                 tb1qk57prsyctjp323rff4g7h45yj5k6fy9zcx44y9xh8yee0zhgn90sg9dxmj
                             );
                             asm = "0 b53c11c0985c831544694d51ebd684952da490a2c1ab5214d73933978ae8995f";
                             hex = 0020b53c11c0985c831544694d51ebd684952da490a2c1ab5214d73933978ae8995f;
                             reqSigs = 1;
                             type = "witness_v0_scripthash";
                         };
                         value = "0.0001";
                     }
                 );
                 vsize = 137;
                 weight = 548;
             };
             unknown =     {
             };
         }
         */
        
        /*
         {
           "tx": {
             "txid": "58f819ff1944eea4bce5b09f50035aad5048bda69a9529abda2c36b443a52f34",
             "hash": "58f819ff1944eea4bce5b09f50035aad5048bda69a9529abda2c36b443a52f34",
             "version": 2,
             "size": 167,
             "vsize": 167,
             "weight": 668,
             "locktime": 0,
             "vin": [
               {
                 "txid": "fe4455275577bb7a5e24fdca5731e7ae3a293f01b1ac3a2e45063889a0f95f6b",
                 "vout": 0,
                 "scriptSig": {
                   "asm": "",
                   "hex": ""
                 },
                 "sequence": 4294967295
               },
               {
                 "txid": "71db88f6edff287a151f1714729373247371ea2d555cf225e13e209bfa31f285",
                 "vout": 0,
                 "scriptSig": {
                   "asm": "",
                   "hex": ""
                 },
                 "sequence": 4294967295
               }
             ],
             "vout": [
               {
                 "value": 0.00200000,
                 "n": 0,
                 "scriptPubKey": {
                   "asm": "OP_HASH160 fe3616aac0334d7876610ec69ed32a02e2cd4955 OP_EQUAL",
                   "hex": "a914fe3616aac0334d7876610ec69ed32a02e2cd495587",
                   "reqSigs": 1,
                   "type": "scripthash",
                   "addresses": [
                     "2NGRNR9Tqz8kBeYMQKe94DF9XmCTgWvxBPh"
                   ]
                 }
               },
               {
                 "value": 0.00019100,
                 "n": 1,
                 "scriptPubKey": {
                   "asm": "0 d28036491ad91061dc911d3e151bee8ee5954e20bc82f7ab8291e8ab9356046f",
                   "hex": "0020d28036491ad91061dc911d3e151bee8ee5954e20bc82f7ab8291e8ab9356046f",
                   "reqSigs": 1,
                   "type": "witness_v0_scripthash",
                   "addresses": [
                     "tb1q62qrvjg6mygxrhy3r5lp2xlw3mje2n3qhjp002uzj852hy6kq3hsllcaxd"
                   ]
                 }
               }
             ]
           },
           "unknown": {
           },
           "inputs": [
             {
               "partial_signatures": {
                 "03c4c709396595d11662c9e14e0abc634038db7b196bde1156646affaee89682b1": "3045022100937d430109a2685890e16624b099272b34e9f97ed71bfdafda36d9a10b842dbf022072f69fed542c5a40b56960a499c430cf1f331021e5609ec58a51648cdb1963b101"
               }
             },
             {
               "partial_signatures": {
                 "022eaf1053e23f8c5bbb560582e2d877551501e35add4e9b0e9f8197df6c1ac1d4": "3045022100eab8b9b92ed4787d622143f688da6898d4e0868a043a885fabef487a04c0f9e102204d73f42d2545a3443081255b4cd7984190f22610002b2ac63fe0bdb095f2ce0701"
               }
             }
           ],
           "outputs": [
             {
             },
             {
             }
           ]
         }
         */
        
    }
    
    func convertPSBTtoData(string: String) {
     
        if let data = Data(base64Encoded: string) {
         
            DispatchQueue.main.async {
                
                let activityViewController = UIActivityViewController(activityItems: [data],
                                                                      applicationActivities: nil)
                
                activityViewController.popoverPresentationController?.sourceView = self.view
                self.present(activityViewController, animated: true) {}
                
            }
            
        }
        
    }

    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
            
            func send(walletName: String) {
                
                Reducer.makeCommand(walletName: walletName, command: .sendrawtransaction, param: param) { [unowned vc = self] (object, errorDesc) in
                    
                    if let result = object as? String {
                        
                        DispatchQueue.main.async {
                            
                            UIPasteboard.general.string = result
                            vc.creatingView.removeConnectingView()
                            vc.navigationItem.title = "Sent ✓"
                            vc.broadcastButton.alpha = 0
                            
                            displayAlert(viewController: vc,
                                         isError: false,
                                         message: "Transaction sent ✓")
                            
                            if !vc.sweeping {
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    
                                    vc.navigationController?.popToRootViewController(animated: true)
                                    
                                }
                                
                            } else {
                                
                                NotificationCenter.default.post(name: .didSweep, object: nil, userInfo: nil)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    
                                    vc.navigationController?.popToRootViewController(animated: true)
                                    
                                }
                                
                            }
                            
                        }
                        
                    } else {
                        
                        vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDesc ?? "")
                        
                    }
                    
                }
                
            }
            
            func decodePsbt(walletName: String) {
                
                Reducer.makeCommand(walletName: walletName, command: .decodepsbt, param: param) { [unowned vc = self] (object, errorDesc) in
                    
                    if let dict = object as? NSDictionary {
                        
                        vc.psbtDict = "\(dict)"
                        
                        if let txDict = dict["tx"] as? NSDictionary {
                            
                            vc.parseTransaction(tx: txDict)
                            
                        }
                        
                    } else {
                        
                       vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDesc ?? "")
                        
                    }
                    
                }
                
            }
            
            func decodeTx(walletName: String) {
                
                Reducer.makeCommand(walletName: walletName, command: .decoderawtransaction, param: param) { [unowned vc = self] (object, errorDesc) in
                    
                    if let dict = object as? NSDictionary {
                        
                        vc.parseTransaction(tx: dict)
                        
                    } else {
                        
                       vc.creatingView.removeConnectingView()
                        displayAlert(viewController: vc, isError: true, message: errorDesc ?? "")
                        
                    }
                    
                }
                
            }
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil {
                
                if wallet!.name != nil {
                    
                    switch method {
                        
                    case .sendrawtransaction:
                        send(walletName: wallet!.name!)
                        
                    case .decodepsbt:
                        decodePsbt(walletName: wallet!.name!)
                        
                    case .decoderawtransaction:
                        decodeTx(walletName: wallet!.name!)
                        
                    default:
                        
                        break
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func parseTransaction(tx: NSDictionary) {
        
        let inputs = tx["vin"] as! NSArray
        let outputs = tx["vout"] as! NSArray
        parseOutputs(outputs: outputs)
        parseInputs(inputs: inputs, completion: getFirstInputInfo)
        
    }
    
    func getFirstInputInfo() {
        
        index = 0
        getInputInfo(index: index)
        
    }
    
    func getInputInfo(index: Int) {
        
        let dict = inputArray[index]
        let txid = dict["txid"] as! String
        let vout = dict["vout"] as! Int
        
        parsePrevTx(method: .getrawtransaction,
                    param: "\"\(txid)\"",
                    vout: vout)
        
    }
    
    func parseInputs(inputs: NSArray, completion: @escaping () -> Void) {
        
        for (index, i) in inputs.enumerated() {
            
            let input = i as! NSDictionary
            let txid = input["txid"] as! String
            let vout = input["vout"] as! Int
            let dict = ["inputNumber":index + 1, "txid":txid, "vout":vout as Any] as [String : Any]
            inputArray.append(dict)
            
            if index + 1 == inputs.count {
                
                completion()
                
            }
            
        }
        
    }
    
    func parseOutputs(outputs: NSArray) {
        
        for (i, o) in outputs.enumerated() {
            
            let output = o as! NSDictionary
            let scriptpubkey = output["scriptPubKey"] as! NSDictionary
            let addresses = scriptpubkey["addresses"] as? NSArray ?? []
            let amount = output["value"] as! Double
            let number = i + 1
            var addressString = ""
            
            if addresses.count > 1 {
                
                for a in addresses {
                    
                    addressString += a as! String + " "
                    
                }
                
            } else {
                
                addressString = addresses[0] as! String
                
            }
            
            outputTotal += amount
            outputsString += "Output #\(number):\nAmount: \(amount.avoidNotation)\nAddress: \(addressString)\n\n"
            var isChange = true
            
            for recipient in recipients {
                
                if addressString == recipient {
                    
                    isChange = false
                    
                }
                
            }
            
            if sweeping {
                
                isChange = false
                
            }
            
            let outputDict:[String:Any] = [
            
                "index": number,
                "amount": amount.avoidNotation,
                "address": addressString,
                "isChange": isChange
            
            ]
            
            outputArray.append(outputDict)
            
        }
        
    }
    
    func parsePrevTxOutput(outputs: NSArray, vout: Int) {
        
        for o in outputs {
            
            let output = o as! NSDictionary
            let n = output["n"] as! Int
            
            if n == vout {
                
                //this is our inputs output, get amount and address
                let scriptpubkey = output["scriptPubKey"] as! NSDictionary
                let addresses = scriptpubkey["addresses"] as! NSArray
                let amount = output["value"] as! Double
                var addressString = ""
                
                if addresses.count > 1 {
                    
                    for a in addresses {
                        
                        addressString += a as! String + " "
                        
                    }
                    
                } else {
                    
                    addressString = addresses[0] as! String
                    
                }
                
                inputTotal += amount
                inputsString += "Input #\(index + 1):\nAmount: \(amount.avoidNotation)\nAddress: \(addressString)\n\n"
                
                let inputDict:[String:Any] = [
                
                    "index": index + 1,
                    "amount": amount.avoidNotation,
                    "address": addressString
                
                ]
                
                inputTableArray.append(inputDict)
                
            }
            
        }
        
        if index + 1 < inputArray.count {
            
            index += 1
            getInputInfo(index: index)
            
        } else if index + 1 == inputArray.count {
            
            let txfee = (self.inputTotal - self.outputTotal).avoidNotation
            self.miningFee = "\(txfee) btc"
            loadTableData()
            
        }
        
    }
    
    func loadTableData() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.confirmTable.reloadData()
            
        }
        
        creatingView.removeConnectingView()
    }
    
    func parsePrevTx(method: BTC_CLI_COMMAND, param: String, vout: Int) {
        
        func decodeRaw(walletName: String) {
            
            Reducer.makeCommand(walletName: walletName, command: .decoderawtransaction, param: param) { [unowned vc = self] (object, errorDescription) in
                
                if let txDict = object as? NSDictionary {
                    
                    if let outputs = txDict["vout"] as? NSArray {
                        
                        vc.parsePrevTxOutput(outputs: outputs, vout: vout)
                        
                    }
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "Error parsing inputs")
                    
                }
                
            }
            
        }
        
        func getRawTx(walletName: String) {
            
            Reducer.makeCommand(walletName: walletName, command: .getrawtransaction, param: param) { [unowned vc = self] (object, errorDescription) in
                
                if let rawTransaction = object as? String {
                    
                    vc.parsePrevTx(method: .decoderawtransaction,
                                param: "\"\(rawTransaction)\"",
                                vout: vout)
                    
                } else {
                    
                    vc.creatingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "Error parsing inputs")
                    
                }
                
            }
            
        }
        
        getActiveWalletNow { (wallet, error) in
            
            if wallet != nil {
                
                if wallet!.name != nil {
                    
                    switch method {
                        
                    case .decoderawtransaction:
                        
                        decodeRaw(walletName: wallet!.name!)
                        
                    case .getrawtransaction:
                        
                        getRawTx(walletName: wallet!.name!)
                        
                    default:
                        
                        break
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 4
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
        case 0:
            
            return inputArray.count
            
        case 1:
            
            return outputArray.count
            
        case 2, 3:
            
            return 1
            
        default:
            
            return 0
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
        case 0, 1:
            
            return 78
            
        case 2, 3:
            
            return 44
            
        default:
            
            return 0
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        case 0:
            
            let inputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath)
            
            if unsignedPsbt != "" {
                
                inputCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            } else {
                
                
            }
            
            let inputIndexLabel = inputCell.viewWithTag(1) as! UILabel
            let inputAmountLabel = inputCell.viewWithTag(2) as! UILabel
            let inputAddressLabel = inputCell.viewWithTag(3) as! UILabel
            let input = inputTableArray[indexPath.row]
            inputIndexLabel.text = "Input #\(input["index"] as! Int)"
            inputAmountLabel.text = "\((input["amount"] as! String)) btc"
            inputAddressLabel.text = (input["address"] as! String)
            inputAddressLabel.adjustsFontSizeToFitWidth = true
            inputCell.selectionStyle = .none
            inputIndexLabel.textColor = .lightGray
            inputAmountLabel.textColor = .lightGray
            inputAddressLabel.textColor = .lightGray
            return inputCell
            
        case 1:
            
            let outputCell = tableView.dequeueReusableCell(withIdentifier: "outputCell", for: indexPath)
            
            if unsignedPsbt != "" {
            
                outputCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            }
            
            let outputIndexLabel = outputCell.viewWithTag(1) as! UILabel
            let outputAmountLabel = outputCell.viewWithTag(2) as! UILabel
            let outputAddressLabel = outputCell.viewWithTag(3) as! UILabel
            let changeLabel = outputCell.viewWithTag(4) as! UILabel
            changeLabel.textColor = .darkGray
            let output = outputArray[indexPath.row]
            let address = (output["address"] as! String)
            let isChange = (output["isChange"] as! Bool)
            
            if isChange {
                
                outputAddressLabel.textColor = .darkGray
                outputAmountLabel.textColor = .darkGray
                outputIndexLabel.textColor = .darkGray
                changeLabel.alpha = 1
                
            } else {
                
                outputAddressLabel.textColor = .lightGray
                outputAmountLabel.textColor = .lightGray
                outputIndexLabel.textColor = .lightGray
                changeLabel.alpha = 0
                
            }
            
            outputIndexLabel.text = "Output #\(output["index"] as! Int)"
            outputAmountLabel.text = "\((output["amount"] as! String)) btc"
            outputAddressLabel.text = address
            outputAddressLabel.adjustsFontSizeToFitWidth = true
            outputCell.selectionStyle = .none
            return outputCell
            
        case 2:
            
            let miningFeeCell = tableView.dequeueReusableCell(withIdentifier: "miningFeeCell", for: indexPath)
            
            if unsignedPsbt != "" {
            
                miningFeeCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            }
            
            let miningLabel = miningFeeCell.viewWithTag(1) as! UILabel
            miningLabel.text = self.miningFee
            miningFeeCell.selectionStyle = .none
            miningLabel.textColor = .lightGray
            return miningFeeCell
            
        case 3:
            
            let etaCell = tableView.dequeueReusableCell(withIdentifier: "miningFeeCell", for: indexPath)
            
            if unsignedPsbt != "" {
            
                etaCell.backgroundColor = #colorLiteral(red: 0, green: 0.1354581723, blue: 0.2808335977, alpha: 1)
                
            }
            
            let etaLabel = etaCell.viewWithTag(1) as! UILabel
            etaLabel.text = eta()
            etaLabel.textColor = .lightGray
            etaCell.selectionStyle = .none
            return etaCell
            
        default:
            
            return UITableViewCell()
            
        }
        
    }
    
    private func eta() -> String {
        var eta = ""
        let ud = UserDefaults.standard
        let numberOfBlocks = ud.object(forKey: "feeTarget") as? Int ?? 432
        let seconds = ((numberOfBlocks * 10) * 60)
        
        if seconds < 86400 {
            
            if seconds < 3600 {
                eta = "\(seconds / 60) minutes"
                
            } else {
                eta = "\(seconds / 3600) hours"
                
            }
            
        } else {
            eta = "\(seconds / 86400) days"
            
        }
        
        return eta
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var sectionString = ""
        
        switch section {
        case 0:
            sectionString = "Inputs"
        case 1:
            sectionString = "Outputs"
        case 2:
            sectionString = "Mining fee"
        case 3:
            sectionString = "Estimated time to confirmation"
        default:
            break
        }
        
        return sectionString
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.lightGray
        (view as! UITableViewHeaderFooterView).textLabel?.alpha = 1
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            
            return 30
            
        } else {
            
            return 20
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 || indexPath.section == 1 {
            
            let cell = tableView.cellForRow(at: indexPath)!
            let addressLabel = cell.viewWithTag(3) as! UILabel
            self.addressToVerify = addressLabel.text!
            
            DispatchQueue.main.async {
                                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    cell.alpha = 0
                    
                }) { _ in
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        
                        cell.alpha = 1
                        
                    }) { [unowned vc = self] _ in
                        
                        DispatchQueue.main.async {
                            
                            vc.performSegue(withIdentifier: "verify", sender: vc)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    private func broadcast() {
        
        self.creatingView.addConnectingView(vc: self, description: "broadcasting transaction")
        let broadcaster = Broadcaster.sharedInstance
        broadcaster.send(rawTx: self.signedRawTx) { [unowned vc = self] txid in
            
            if txid != nil {
                
                DispatchQueue.main.async {
                    
                    UIPasteboard.general.string = txid!
                    vc.creatingView.removeConnectingView()
                    vc.navigationItem.title = "Sent ✓"
                    vc.broadcastButton.alpha = 0
                    
                    displayAlert(viewController: vc,
                                 isError: false,
                                 message: "Transaction sent ✓")
                    
                    if !vc.sweeping {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            
                            vc.navigationController?.popToRootViewController(animated: true)
                            
                        }
                        
                    } else {
                        
                        NotificationCenter.default.post(name: .didSweep, object: nil, userInfo: nil)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            
                            vc.navigationController?.popToRootViewController(animated: true)
                            
                        }
                        
                    }
                    
                }
            } else {
                
                DispatchQueue.main.async {
                                
                    let alert = UIAlertController(title: "There was an error broadcasting your transaction with blockstream's node.", message: "Broadcast the transaction with your node?", preferredStyle: .actionSheet)

                    alert.addAction(UIAlertAction(title: "Yes, broadcast now", style: .default, handler: { [unowned vc = self] action in
                        
                        vc.executeNodeCommand(method: .sendrawtransaction, param: "\"\(vc.signedRawTx)\"")
                                            
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    alert.popoverPresentationController?.sourceView = self.view
                    self.present(alert, animated: true, completion: nil)
                    
                }
            }
        }
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
                            vc.broadcast()
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
        
        let id = segue.identifier
        
        switch id {
            
        case "verify":
            
            if let vc = segue.destination as? VerifyViewController {
                
                vc.address = self.addressToVerify
                
            }
            
        default:
            
            break
            
        }
        
    }

}

