//
//  ConfirmRecoveryViewController.swift
//  FullyNoded2
//
//  Created by Peter on 17/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally
import CryptoKit

class ConfirmRecoveryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var nodeLogic = NodeLogic.sharedInstance
    let connectingView = ConnectingView()
    var words = ""
    var walletDict = [String:Any]()
    var derivation = ""
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
        walletName.text = "loading..."
        walletBirthdate.text = "no data available"
        walletNetwork.text = "no data available"
        walletBalance.text = "no data available"
        walletType.text = "Single-sig"
        walletDerivation.text = "\(derivation)/0"
        
        let mnemonicCreator = MnemonicCreator()
        mnemonicCreator.convert(words: words) { [unowned vc = self] (mnemonic, error) in
            
            if !error && mnemonic != nil {
                
                let mk = HDKey(mnemonic!.seedHex(), network(path: vc.derivation))!
                let fingerprint = mk.fingerprint.hexString
                
                for i in 0...4 {
                    
                    do {
                        
                        let key = try mk.derive(BIP32Path("\(vc.derivation)/0/\(i)")!)
                        var addressType:AddressType!
                        
                        if vc.derivation.contains("84") {
                            
                            addressType = .payToWitnessPubKeyHash
                            
                        } else if vc.derivation.contains("44") {
                            
                            addressType = .payToPubKeyHash
                            
                        } else if vc.derivation.contains("49") {
                            
                            addressType = .payToScriptHashPayToWitnessPubKeyHash
                            
                        }
                        
                        let address = key.address(addressType).description
                        vc.addresses.append(address)
                        
                    } catch {
                        
                        displayAlert(viewController: vc, isError: false, message: "error deriving addresses from those words")
                        
                    }
                    
                }
                
                var param = ""
                
                do {
                    
                    let xpub = try mk.derive(BIP32Path(vc.derivation)!).xpub
                    
                    switch vc.derivation {
                        
                    case "m/84'/1'/0'":
                        param = "\"wpkh([\(fingerprint)/84'/1'/0']\(xpub)/0/*)\""
                        
                    case "m/84'/0'/0'":
                        param = "\"wpkh([\(fingerprint)/84'/0'/0']\(xpub)/0/*)\""
                        
                    case "m/44'/1'/0'":
                        param = "\"pkh([\(fingerprint)/44'/1'/0']\(xpub)/0/*)\""
                         
                    case "m/44'/0'/0'":
                        param = "\"pkh([\(fingerprint)/44'/0'/0']\(xpub)/0/*)\""
                        
                    case "m/49'/1'/0'":
                        param = "\"sh(wpkh([\(fingerprint)/49'/1'/0']\(xpub)/0/*))\""
                        
                    case "m/49'/0'/0'":
                        param = "\"sh(wpkh([\(fingerprint)/49'/0'/0']\(xpub)/0/*))\""
                        
                    default:
                        
                        break
                        
                    }
                    
                    let reducer = Reducer()
                    reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) {
                        
                        if !reducer.errorBool {
                            
                            if let dict = reducer.dictToReturn {
                                
                                let desc = dict["descriptor"] as! String
                                let digest = SHA256.hash(data: desc.dataUsingUTF8StringEncoding)
                                let walletName = digest.map { String(format: "%02hhx", $0) }.joined()
                                
                                DispatchQueue.main.async {
                                    
                                    vc.walletName.text = vc.reducedName(name: walletName)
                                    vc.addressTable.reloadData()
                                    
                                }
                                
                            } else {
                                
                                displayAlert(viewController: vc, isError: true, message: "unknown error")
                                
                            }
                            
                        } else {
                            
                            displayAlert(viewController: vc, isError: true, message: reducer.errorDescription)
                            
                        }
                        
                    }
                                        
                } catch {
                    
                    displayAlert(viewController: vc, isError: true, message: "error constructing descriptor")
                    
                }
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: "error deriving addresses from those words")
                
            }
            
        }
        
    }
    
    private func loadSingleSigAddressesFromQR() {
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        
        let xprv = descriptorStruct.accountXprv
        let xpub = HDKey(xprv)!.xpub
        let desc = (walletDict["descriptor"] as! String).replacingOccurrences(of: xprv, with: xpub)
        let digest = SHA256.hash(data: desc.dataUsingUTF8StringEncoding)
        let walletName = digest.map { String(format: "%02hhx", $0) }.joined()
        
        DispatchQueue.main.async {
            
            self.walletName.text = self.reducedName(name: walletName)
            
        }
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: walletName, command: .getdescriptorinfo, param: "\"\(desc)\"") { [unowned vc = self] in
            
            if !reducer.errorBool {
                
                if let result = reducer.dictToReturn {
                    
                    let descriptor = result["descriptor"] as! String
                    reducer.makeCommand(walletName: walletName, command: .deriveaddresses, param: "\"\(descriptor)\", [0,4]") { [unowned vc = self] in
                        
                        if !reducer.errorBool {
                            
                            if let result = reducer.arrayToReturn {
                                
                                for address in result {
                                    
                                    vc.addresses.append(address as! String)
                                    
                                }
                                
                                vc.connectingView.removeConnectingView()
                                
                            } else {
                                
                                vc.connectingView.removeConnectingView()
                                displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
                                
                            }
                                            
                            DispatchQueue.main.async {
                                
                                vc.addressTable.reloadData()
                                
                            }
                            
                            vc.walletDict["name"] = walletName
                            let wallet = WalletStruct(dictionary: vc.walletDict)
                            vc.nodeLogic?.loadWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                                
                                if success && dictToReturn != nil {
                                
                                    let s = HomeStruct(dictionary: dictToReturn!)
                                    let doub = (s.coldBalance).doubleValue
                                    
                                    DispatchQueue.main.async {
                                        
                                        vc.walletBalance.text = "\(doub)"
                                        
                                    }
                                    
                                } else {
                                    
                                    DispatchQueue.main.async {
                                        
                                        vc.walletBalance.text = "error fetching balance"
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            vc.connectingView.removeConnectingView()
                            displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
                            
                        }
                        
                    }
                    
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "getdesriptorinfo error")
                    
                }
                
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "getdesriptorinfo error: \(reducer.errorDescription)")
                
            }
            
        }
        
    }
    
    
    private func loadMultiSigAddressesFromQR() {
        
        connectingView.addConnectingView(vc: self, description: "deriving addresses")
        
        // need to replace xprv with xpub so the checksum is valid
        let xprv = descriptorStruct.multiSigKeys[1]
        let xpub = HDKey(xprv)!.xpub
        let desc = (walletDict["descriptor"] as! String).replacingOccurrences(of: xprv, with: xpub)
        let digest = SHA256.hash(data: desc.dataUsingUTF8StringEncoding)
        let walletName = digest.map { String(format: "%02hhx", $0) }.joined()
        
        DispatchQueue.main.async {
            
            self.walletName.text = self.reducedName(name: walletName)
            
        }
        
        let reducer = Reducer()
        reducer.makeCommand(walletName: walletName, command: .deriveaddresses, param: "\"\(desc)\", [0,4]") { [unowned vc = self] in
            
            if !reducer.errorBool {
                
                if let result = reducer.arrayToReturn {
                    
                    for address in result {
                        
                        vc.addresses.append(address as! String)
                        
                    }
                    
                    vc.connectingView.removeConnectingView()
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
                    
                }
                                
                DispatchQueue.main.async {
                    
                    vc.addressTable.reloadData()
                    
                }
                
                vc.walletDict["name"] = walletName
                let wallet = WalletStruct(dictionary: vc.walletDict)
                vc.nodeLogic?.loadWalletData(wallet: wallet) { [unowned vc = self] (success, dictToReturn, errorDesc) in
                    
                    if success && dictToReturn != nil {
                    
                        let s = HomeStruct(dictionary: dictToReturn!)
                        let doub = (s.coldBalance).doubleValue
                        
                        DispatchQueue.main.async {
                            
                            vc.walletBalance.text = "\(doub)"
                            
                        }
                        
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            vc.walletBalance.text = "error fetching balance"
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "Error fetching addresses for that wallet")
                
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
            
            self.dismiss(animated: true) { [unowned vc = self] in
                
                vc.confirmedDoneBlock!(false)
                
            }
            
        }
        
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        
        print("confirm")
        DispatchQueue.main.async {
            
            self.dismiss(animated: true) { [unowned vc = self] in
                
                vc.confirmedDoneBlock!(true)
                
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
    
    private func reducedName(name: String) -> String {
        
        let first = String(name.prefix(5))
        let last = String(name.suffix(5))
        return "\(first)*****\(last).dat"
        
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
