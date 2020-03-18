//
//  ConfirmRecoveryViewController.swift
//  FullyNoded2
//
//  Created by Peter on 17/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class ConfirmRecoveryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let connectingView = ConnectingView()
    var words = ""
    var walletDict = [String:Any]()
    var confirmedDoneBlock: ((Bool) -> Void)?
    var addresses = [String]()
    var descriptorStruct:DescriptorStruct!
    @IBOutlet var walletLabel: UILabel!
    @IBOutlet var walletName: UILabel!
    @IBOutlet var walletDerivation: UILabel!
    @IBOutlet var walletBirthdate: UILabel!
    @IBOutlet var walletType: UILabel!
    @IBOutlet var walletNetwork: UILabel!
    @IBOutlet var walletBalance: UILabel!
    @IBOutlet var addressTable: UITableView!
    @IBOutlet var cancelOutlet: UIButton!
    @IBOutlet var confirmOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addressTable.delegate = self
        addressTable.dataSource = self
        addressTable.clipsToBounds = true
        addressTable.layer.cornerRadius = 8
        cancelOutlet.layer.cornerRadius = 8
        confirmOutlet.layer.cornerRadius = 8
        
        // QR only
        if words == "" && walletDict["descriptor"] != nil {
            
            let parser = DescriptorParser()
            descriptorStruct = parser.descriptor(walletDict["descriptor"] as! String)
            walletLabel.text = walletDict["label"] as? String ?? "no wallet label"
            walletName.text = "\(walletDict["walletName"] as! String).dat"
            walletBirthdate.text = getDate(unixTime: walletDict["birthdate"] as! Int32)
            walletNetwork.text = descriptorStruct.chain
            walletBalance.text = "...fetching balance"
            
            if descriptorStruct.isMulti {
                
                walletType.text = "\(descriptorStruct.mOfNType) multi-sig"
                walletDerivation.text = descriptorStruct.derivationArray[1] + "/\(descriptorStruct.multiSigPaths[1])"
                loadMultiSigAddressesFromQR()
                
                showAlert(vc: self, title: "Attention!", message: "You are recovering a multi-sig wallet. Please ensure you still have your backup words, otherwise you may not be able to fully recover this wallet if you lose your device and node in the future! If you are in doubt then it is recommended you use the \"sweep to\" tool to sweep all funds to a brand new 2 of 3 wallet.\n\nIf you are positive you still have the recovery words then you can ignore this message.")
                
            } else {
                
                walletType.text = "Single-sig"
                walletDerivation.text = descriptorStruct.derivation + "/0"
                loadSingleSigAddressesFromQR()
                
            }
            
        // Words only
        } else if words != "" && walletDict["descriptor"] == nil {
            
            loadAddressesFromLibWally()
            
        // Full multisig recovery
        } else if words != "" && walletDict["descriptor"] != nil {
            
            let parser = DescriptorParser()
            descriptorStruct = parser.descriptor(walletDict["descriptor"] as! String)
            walletLabel.text = walletDict["label"] as? String ?? "no wallet label"
            walletName.text = "\(walletDict["walletName"] as! String).dat"
            walletBirthdate.text = getDate(unixTime: walletDict["birthdate"] as! Int32)
            walletNetwork.text = descriptorStruct.chain
            walletBalance.text = "...fetching balance"
            walletType.text = "\(descriptorStruct.mOfNType) multi-sig"
            walletDerivation.text = descriptorStruct.derivationArray[1] + "/\(descriptorStruct.multiSigPaths[1])"
            loadMultiSigAddressesFromQR()
            
            showAlert(vc: self, title: "Attention!", message: "You are attempting to fully recover a multi-sig wallet.\n\nThis means your back up recovery words have been consumed to restore your lost wallet, if you lose the recovery words you will have no way of fully recovering this wallet again! This means your wallet has essentially become a 2 of 2. We urge you to sweep this wallet to a new multi-sig setup so that you get a new fresh backup phrase along with a new 2 of 3 setup, that can be achieved by using the \"sweep to\" tool once this recovery completes.")
            
        }
        
    }
    
    private func loadAddressesFromLibWally() {
        
        walletLabel.text = "no data available"
        walletName.text = "no data available"
        walletBirthdate.text = "no data available"
        walletNetwork.text = "no data available"
        walletBalance.text = "no data available"
        walletType.text = "Single-sig"
        let stringPath = self.walletDict["derivation"] as! String
        walletDerivation.text = "\(stringPath)/0"
        
        let mnemonicCreator = MnemonicCreator()
        mnemonicCreator.convert(words: words) { (mnemonic, error) in
            
            if !error && mnemonic != nil {
                
                let mk = HDKey(mnemonic!.seedHex(), network(path: stringPath))!
                
                for i in 0...4 {
                    
                    do {
                        
                        let key = try mk.derive(BIP32Path("\(stringPath)/0/\(i)")!)
                        var addressType:AddressType!
                        
                        if stringPath.contains("84") {
                            
                            addressType = .payToWitnessPubKeyHash
                            
                        } else if stringPath.contains("44") {
                            
                            addressType = .payToPubKeyHash
                            
                        } else if stringPath.contains("49") {
                            
                            addressType = .payToScriptHashPayToWitnessPubKeyHash
                        }
                        
                        let address = key.address(addressType).description
                        self.addresses.append(address)
                        
                    } catch {
                        
                        displayAlert(viewController: self, isError: false, message: "error deriving addresses from those words")
                        
                    }
                    
                }
                
                DispatchQueue.main.async {
                    
                    self.addressTable.reloadData()
                    
                }
                
            } else {
                
                displayAlert(viewController: self, isError: false, message: "error deriving addresses from those words")
                
            }
            
        }
        
    }
    
    private func loadSingleSigAddressesFromQR() {
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        
        let xprv = descriptorStruct.accountXprv
        let xpub = HDKey(xprv)!.xpub
        let desc = (walletDict["descriptor"] as! String).replacingOccurrences(of: xprv, with: xpub)
        let reducer = Reducer()
        reducer.makeCommand(walletName: (walletDict["walletName"] as! String), command: .getdescriptorinfo, param: "\"\(desc)\"") {
            
            if !reducer.errorBool {
                
                if let result = reducer.dictToReturn {
                    
                    let descriptor = result["descriptor"] as! String
                    reducer.makeCommand(walletName: (self.walletDict["walletName"] as! String), command: .deriveaddresses, param: "\"\(descriptor)\", [0,4]") {
                        
                        if !reducer.errorBool {
                            
                            if let result = reducer.arrayToReturn {
                                
                                for address in result {
                                    
                                    self.addresses.append(address as! String)
                                    
                                }
                                
                                self.connectingView.removeConnectingView()
                                
                            } else {
                                
                                self.connectingView.removeConnectingView()
                                displayAlert(viewController: self, isError: true, message: "Error fetching addresses for that wallet")
                                
                            }
                                            
                            DispatchQueue.main.async {
                                
                                self.addressTable.reloadData()
                                
                            }
                            
                            let nodeLogic = NodeLogic()
                            self.walletDict["name"] = self.walletDict["walletName"] as! String
                            nodeLogic.wallet = WalletStruct(dictionary: self.walletDict)
                            nodeLogic.loadWalletData {
                                
                                if !nodeLogic.errorBool {
                                
                                    let s = HomeStruct(dictionary: nodeLogic.dictToReturn)
                                    let doub = (s.coldBalance).doubleValue
                                    
                                    DispatchQueue.main.async {
                                        
                                        self.walletBalance.text = "\(doub)"
                                        
                                    }
                                    
                                } else {
                                    
                                    DispatchQueue.main.async {
                                        
                                        self.walletBalance.text = "error fetching balance"
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            self.connectingView.removeConnectingView()
                            displayAlert(viewController: self, isError: true, message: "Error fetching addresses for that wallet")
                            
                        }
                        
                    }
                    
                    
                } else {
                    
                    self.connectingView.removeConnectingView()
                    displayAlert(viewController: self, isError: true, message: "getdesriptorinfo error")
                    
                }
                
                
            } else {
                
                self.connectingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "getdesriptorinfo error: \(reducer.errorDescription)")
                
            }
            
        }
        
    }
    
    
    private func loadMultiSigAddressesFromQR() {
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        
        // need to replace xprv with xpub so the checksum is valid
        let xprv = descriptorStruct.multiSigKeys[1]
        let xpub = HDKey(xprv)!.xpub
        let desc = (walletDict["descriptor"] as! String).replacingOccurrences(of: xprv, with: xpub)
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: (walletDict["walletName"] as! String), command: .deriveaddresses, param: "\"\(desc)\", [0,4]") {
            
            if !reducer.errorBool {
                
                if let result = reducer.arrayToReturn {
                    
                    for address in result {
                        
                        self.addresses.append(address as! String)
                        
                    }
                    
                    self.connectingView.removeConnectingView()
                    
                } else {
                    
                    self.connectingView.removeConnectingView()
                    displayAlert(viewController: self, isError: true, message: "Error fetching addresses for that wallet")
                    
                }
                                
                DispatchQueue.main.async {
                    
                    self.addressTable.reloadData()
                    
                }
                
                let nodeLogic = NodeLogic()
                self.walletDict["name"] = self.walletDict["walletName"] as! String
                nodeLogic.wallet = WalletStruct(dictionary: self.walletDict)
                nodeLogic.loadWalletData {
                    
                    if !nodeLogic.errorBool {
                    
                        let s = HomeStruct(dictionary: nodeLogic.dictToReturn)
                        let doub = (s.coldBalance).doubleValue
                        
                        DispatchQueue.main.async {
                            
                            self.walletBalance.text = "\(doub)"
                            
                        }
                        
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            self.walletBalance.text = "error fetching balance"
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                self.connectingView.removeConnectingView()
                displayAlert(viewController: self, isError: true, message: "Error fetching addresses for that wallet")
                
            }
            
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        addresses.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row).  \(addresses[indexPath.row])"
        cell.textLabel?.textColor = .systemTeal
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.selectionStyle = .none
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 30
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        
        print("cancel")
        DispatchQueue.main.async {
            
            self.dismiss(animated: true) {
                
                self.confirmedDoneBlock!(false)
                
            }
            
        }
        
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        
        print("confirm")
        DispatchQueue.main.async {
            
            self.dismiss(animated: true) {
                
                self.confirmedDoneBlock!(true)
                
            }
            
        }
        
    }
    
    private func getDate(unixTime: Int32) -> String {
        
        let dateFormatter = DateFormatter()
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MMM-dd hh:mm" //Specify your format that you want
        let strDate = dateFormatter.string(from: date)
        return strDate
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
