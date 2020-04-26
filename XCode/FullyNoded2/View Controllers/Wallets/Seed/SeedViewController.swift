//
//  SeedViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit
import AuthenticationServices
import LibWally

class SeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var verified = Bool()
    let qrGenerator = QRGenerator()
    var recoveryQr = ""
    var recoveryImage = UIImage()
    var seed = ""
    var itemToDisplay = ""
    var infoText = ""
    var barTitle = ""
    var privateKeyDescriptor = ""
    var publicKeyDescriptor = ""
    var birthdate = "\"now\""
    var recoveryText = ""
    var wallet:WalletStruct!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.alpha = 0
        verified = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        #if !targetEnvironment(simulator)
        showAuth()
        #else
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            
            if wallet != nil && !error {
                
                vc.tableView.alpha = 1
                vc.wallet = wallet!
                vc.loadData()
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: "no active wallet")
                
            }
            
        }
        #endif
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @objc func handleCopyTap(_ sender: UIButton) {
        
        print("copy tapped")
        
        let section = sender.tag
        
        var textToCopy = ""
        var message = ""
        
        switch section {
            
        case 0:
            textToCopy = recoveryQr
            message = "your recovery QR text was copied to your clipboard and will be erased in one minute"
            
        case 1:
            textToCopy = "Devices seed:" + " " + seed + "derivation: \(wallet.derivation)/0" + "birthdate unix: \(wallet.birthdate)"
            message = "your seed was copied to your clipboard and will be erased in one minute"
            
        case 2:
            textToCopy = "Public Key Descriptors: \(publicKeyDescriptor)"
            message = "your public key descriptor was copied to your clipboard and will be erased in one minute"
            
        case 3:
            textToCopy = "Private Key Descriptors: \(privateKeyDescriptor)"
            message = "your private key descriptor was copied to your clipboard and will be erased in one minute"
            
//        case 4:
//            textToCopy = "Bitcoin Core recovery commands: \(recoveryText)"
//            message = "your recovery command was copied to your clipboard and will be erased in one minute"
            
        default:
            break
        }
        
        UIPasteboard.general.string = textToCopy
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            
            UIPasteboard.general.string = ""
            
        }
        
        displayAlert(viewController: self, isError: false, message: message)
        
    }
    
    @objc func handleShareTap(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        let section = sender.tag
        
        switch section {
            
        case 0:
            shareImage()
        case 1:
            itemToDisplay = seed
            shareText()
        case 2:
            itemToDisplay = publicKeyDescriptor
            shareText()
        case 3:
            itemToDisplay = privateKeyDescriptor
            shareText()
        case 4:
            itemToDisplay = recoveryText
            shareText()
        default:
            break
        }
        
    }
    
    @objc func handleQRTap(_ sender: UIButton) {
        
        let section = sender.tag
        
        switch section {
            
        case 1:
            
            itemToDisplay = seed
            infoText = "Your BIP39 recovery phrase which can be imported into BIP39 compatible wallets, by default StandUp does not create a password for your recovery phrase."
            barTitle = "BIP39 Mnemonic"
            goToQRDisplayer()
            
        case 2:
            
            itemToDisplay = publicKeyDescriptor
            infoText = "Your public key descriptor which can be used with the importmulti command to create a watch-only wallet with Bitcoin Core."
            barTitle = "Pubkey Descriptor"
            goToQRDisplayer()
            
        case 3:
            
            itemToDisplay = privateKeyDescriptor
            infoText = "Your private key descriptor which can be used with the importmulti command to recover your StandUp wallet with Bitcoin Core."
            barTitle = "Private Key Descriptor"
            goToQRDisplayer()
            
//        case 4:
//
//            itemToDisplay = recoveryText
//            infoText = "This command can be pasted into a terminal to add all your devices private keys to your node, this would be useful if you lost your device as you can use your node to recover your wallet."
//            barTitle = "Recovery Command"
//            goToQRDisplayer()
            
        default:
            
            break
            
        }
        
    }
    
    func shareText() {
        
        DispatchQueue.main.async {
            
            let textToShare = [self.itemToDisplay]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    func shareImage() {
        
        DispatchQueue.main.async {
            
            let imageToShare = [self.recoveryImage]
            
            let activityViewController = UIActivityViewController(activityItems: imageToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    func loadData() {
        
        let p = DescriptorParser()
        let s = p.descriptor(self.wallet.descriptor)
        self.publicKeyDescriptor = "\(self.wallet.descriptor)\n\n\(self.wallet.changeDescriptor)"
        
        self.xprv { [unowned vc = self] (xprv) in
            
            if xprv != "" {
                
                let encryptedWords = vc.wallet.seed
                Encryption.decryptData(dataToDecrypt: encryptedWords) { (decryptedWords) in
                    
                    if decryptedWords != nil {
                        
                        if let words = String(data: decryptedWords!, encoding: .utf8) {
                            
                            if let bip39words = BIP39Mnemonic(words) {
                                
                                let entropyString = bip39words.entropy.description
                                
                                vc.xpub(descriptorStruct: s) { (xpub) in
                                
                                    if xpub != "" {
                                        
                                        if !s.isMulti {
                                         
                                            // its single sig
                                            var privKeyDesc = vc.wallet.descriptor
                                            privKeyDesc = privKeyDesc.replacingOccurrences(of: xpub, with: xprv)
                                            let recoveryDesc = privKeyDesc.replacingOccurrences(of: xpub, with: xprv)
                                            let arr = privKeyDesc.split(separator: "#")
                                            privKeyDesc = "\(arr[0])"
                                            
                                            var changeDescriptor = vc.wallet.changeDescriptor
                                            changeDescriptor = changeDescriptor.replacingOccurrences(of: xpub, with: xprv)
                                            let arr1 = changeDescriptor.split(separator: "#")
                                            changeDescriptor = "\(arr1[0])"
                                            
                                            let recoveryQr = ["entropy": entropyString, "descriptor":"\(recoveryDesc)","birthdate":vc.wallet.birthdate, "blockheight":vc.wallet.blockheight, "label": vc.wallet.label] as [String : Any]
                                            
                                            if let json = recoveryQr.json() {
                                                
                                                let (qr, error) = vc.qrGenerator.getQRCode(textInput: json)
                                                vc.recoveryImage = qr
                                                
                                                if error {
                                                    
                                                    showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
                                                    
                                                }
                                                
                                            }
                                            
                                            vc.privateKeyDescriptor = "\(privKeyDesc)\n\n\(changeDescriptor)"
                                            
                                        } else {
                                         
                                            // its multisig
                                            var primaryDesc = vc.wallet.descriptor
                                            var changeDesc = vc.wallet.changeDescriptor
                                            
                                            primaryDesc = primaryDesc.replacingOccurrences(of: xpub, with: xprv)
                                            let arr = primaryDesc.split(separator: "#")
                                            primaryDesc = "\(arr[0])"
                                            
                                            changeDesc = changeDesc.replacingOccurrences(of: xpub, with: xprv)
                                            let arr1 = changeDesc.split(separator: "#")
                                            changeDesc = "\(arr1[0])"
                                            
                                            // we need to preserve the public key descriptor checksum when creating the recovery qr as the descriptor is manipulated and converted back to a public key descriptor during the recovery process. It is more efficient to do it this way then making extra rpc calls to the node during recovery.
                                            let recoveryDesc = (vc.wallet.descriptor).replacingOccurrences(of: xpub, with: xprv)
                                            
                                            let recoveryQr = ["entropy": entropyString, "descriptor":"\(recoveryDesc)","birthdate":vc.wallet.birthdate, "blockheight":vc.wallet.blockheight, "label": vc.wallet.label] as [String : Any]
                                            
                                            if let json = recoveryQr.json() {
                                                
                                                let (qr, error) = vc.qrGenerator.getQRCode(textInput: json)
                                                vc.recoveryImage = qr
                                                
                                                if error {
                                                    
                                                    showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
                                                    
                                                }
                                                
                                            }
                                                                                        
                                            vc.privateKeyDescriptor = "\(primaryDesc)\n\n\(changeDesc)"
                                            
//                                            vc.recoveryText = "bitcoin-cli -rpcwallet=\(vc.wallet.name!) importmulti { \"desc\": \"\(primaryDesc)\", \"timestamp\": \(vc.wallet.birthdate), \"range\": [0,999], \"watchonly\": false, \"label\": \"StandUp\", \"keypool\": false, \"internal\": false }\n\nbitcoin-cli -rpcwallet=\(vc.wallet.name!) importmulti { \"desc\": \"\(changeDesc)\", \"timestamp\": \(vc.wallet.birthdate), \"range\": [0,999], \"watchonly\": false, \"keypool\": false, \"internal\": false }"
                                            
                                        }
                                        
                                        DispatchQueue.main.async {
                                            
                                            vc.tableView.reloadData()
                                            
                                        }
                                        
                                    }
                                    
                                }
                                                            
                            }
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                // wallet is cold
                
                let recoveryQr = ["descriptor":"\(vc.wallet.descriptor)","birthdate":vc.wallet.birthdate, "blockheight":vc.wallet.blockheight] as [String : Any]
                
                if let json = recoveryQr.json() {
                    
                    let (qr, error) = vc.qrGenerator.getQRCode(textInput: json)
                    vc.recoveryImage = qr
                    
                    if error {
                        
                        showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
                        
                    }
                    
                }
                
                DispatchQueue.main.async {
                    
                    vc.tableView.reloadData()
                    
                }
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 0:
            return 345
        default:
            tableView.estimatedRowHeight = 55
            return UITableView.automaticDimension
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
                
        return 4//5
        
    }
    
    
    
    private func recoveryCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let recoveryCell = tableView.dequeueReusableCell(withIdentifier: "recoveryCell", for: indexPath)
        let imageview = recoveryCell.viewWithTag(1) as! UIImageView
        imageview.image = self.recoveryImage
        return recoveryCell
        
    }
    
    private func seedCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.backgroundColor = #colorLiteral(red: 0.0507061556, green: 0.05862525851, blue: 0.0711022839, alpha: 1)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = .lightGray
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)
     
        if wallet != nil {
            
            if wallet.type == "CUSTOM" {
                
                cell.textLabel?.text = "⚠︎ No seed on device"
                
            }
            
        }
        
        if wallet?.seed != nil {
            
            let encryptedSeed = wallet!.seed
            
            Encryption.decryptData(dataToDecrypt: encryptedSeed) { [unowned vc = self] (decryptedData) in
                
                if decryptedData != nil {
                    
                    let decryptedSeed = String(bytes: decryptedData!, encoding: .utf8)!
                    vc.seed = decryptedSeed
                    let arr = decryptedSeed.split(separator: " ")
                    var str = ""
                    
                    for (i, word) in arr.enumerated() {
                        
                        if i + 1 == arr.count {
                            
                            str += "\(i + 1). \(word)"
                            
                        } else {
                            
                            str += "\(i + 1). \(word)\n"
                            
                        }
                        
                    }
                    
                    cell.textLabel?.text = str
                    
                }
                
            }
            
        } else {
            
            cell.textLabel?.text = "⚠︎ No seed on device"
            
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.backgroundColor = #colorLiteral(red: 0.0507061556, green: 0.05862525851, blue: 0.0711022839, alpha: 1)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = .lightGray
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        
        switch indexPath.section {
            
        case 0:
            
            return recoveryCell(indexPath)
            
        case 1:
            
            if wallet != nil {
                
                if String(data: wallet.seed, encoding: .utf8) != "no seed" {
                    
                    return seedCell(indexPath)
                    
                } else {
                    
                    cell.textLabel?.text = "No BIP39 Menmonic available"
                    return cell
                    
                }
                
            } else {
                
                return cell
                
            }
                        
        case 2:
            
            cell.textLabel?.text = self.publicKeyDescriptor
            return cell
            
        case 3:
            
            if self.wallet != nil {
                
                if self.wallet.type == "CUSTOM" {
                    
                    cell.textLabel?.text = "⚠︎ No private keys on device"
                    
                } else {
                    
                    cell.textLabel?.text = self.privateKeyDescriptor
                    
                }
                
            }
            
            return cell
            
//        case 4:
//
//            cell.textLabel?.text = self.recoveryText
//            return cell
            
        default:
            
            return UITableViewCell()
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 30
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30)
        
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        textLabel.textColor = .systemGray
        textLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        
        let shareButton = UIButton()
        let image = UIImage(systemName: "arrowshape.turn.up.right.fill")
        shareButton.setImage(image, for: .normal)
        shareButton.tintColor = .systemTeal
        shareButton.tag = section
        shareButton.addTarget(self, action: #selector(handleShareTap(_:)), for: .touchUpInside)
        shareButton.frame = CGRect(x: header.frame.maxX - 70, y: 0, width: 20, height: 20)
        shareButton.center.y = textLabel.center.y
        
        let qrButton = UIButton()
        let qrImage = UIImage(systemName: "qrcode")
        qrButton.setImage(qrImage, for: .normal)
        qrButton.tintColor = .systemTeal
        qrButton.tag = section
        qrButton.addTarget(self, action: #selector(handleQRTap(_:)), for: .touchUpInside)
        qrButton.frame = CGRect(x: shareButton.frame.minX - 30, y: 0, width: 20, height: 20)
        qrButton.center.y = textLabel.center.y
        
        let copyButton = UIButton()
        let copyImage = UIImage(systemName: "doc.on.doc")
        copyButton.setImage(copyImage, for: .normal)
        copyButton.tintColor = .systemTeal
        copyButton.tag = section
        copyButton.addTarget(self, action: #selector(handleCopyTap(_:)), for: .touchUpInside)
        copyButton.frame = CGRect(x: qrButton.frame.minX - 30, y: 0, width: 20, height: 20)
        copyButton.center.y = textLabel.center.y
        
        switch section {
            
        case 0:
            textLabel.text = "Recovery QR"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            
        case 1:
            textLabel.text = "BIP39 Mnemonic"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(qrButton)
            header.addSubview(copyButton)
            
        case 2:
            textLabel.text = "Public Key Descriptors"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(qrButton)
            header.addSubview(copyButton)
            
        case 3:
            textLabel.text = "Private Key Descriptors"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(qrButton)
            header.addSubview(copyButton)
            
        case 4:
            textLabel.text = "Bitcoin Core Recovery"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(qrButton)
            header.addSubview(copyButton)
            
        default:
            
            break
            
        }
        
        return header
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        if wallet != nil {
            
            if wallet.type == "MULTI" {
                
                switch section {
                
                case 0: return 50
                    
                case 1: return 130
                    
                case 2: return 80
                    
                case 3: return 150
                    
                //case 4: return 120
                    
                default:
                    
                    return 0
                    
                }
                
            } else if wallet.type == "DEFAULT"  {
                
                return 80
                
            } else if wallet.type == "CUSTOM" {
                
                switch section {
                    
                case 1, 3: return 80
                                        
                default:
                    
                    return 0
                    
                }
                
            } else {
                
                return 0
                
            }
            
        } else {
            
            return 0
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footerView = UIView()
        footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 20, height: 150)
        footerView.backgroundColor = .clear
        let label = UILabel()
        label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 20, height: 150)
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .light)
        label.textColor = .darkGray
        label.numberOfLines = 0
        
        if wallet != nil {
            
            if wallet.type == "MULTI" {
                
                switch section {
                    
                case 0:
                    
                    label.text = "This Recovery QR can be used with either FullyNoded 2 or StandUp.app to recover this wallet. ENSURE you back it up safely."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 50)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 50)
                    
                case 1:
                    
                    label.text = "This BIP39 mnemonic represents one of three seeds associated with your multisig wallet, this is the only seed held on this device for this wallet. You may use this seed to derive all the private keys needed for signing one of the two required signatures for spending from your StandUp multisig wallet. You should back this up in multiple places, because it is a multisig wallet an attacker can not do anything with this seed alone."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 130)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 130)
                    
                case 2:
                    
                    label.text = "You must back this up in order to recover your wallet. Your public key descriptor can be used to easily create watch-only wallets with Bitcoin Core or to supplement multisig wallet recovery. You may use it to derive the public keys and addresses associated with this wallet."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                case 3:
                    
                    label.text = "Your private key descriptor can be used to recover or spend from your wallet by importing it into your node. You may use it to derive the private keys associated with the seed which is held on this device for the current wallet. This private key descriptor will only allow you to sign for one of the two required signatures needed to spend from your StandUp multisig wallet. In order to fully recover your wallet you also need either your node that you created the wallet on or your recovery seed which should have been saved by you when you created this wallet."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 150)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 150)
                    
//                case 4:
//
//                    label.text = "You may paste this command directly into a terminal where Bitcoin Core is running and it will automatically import all the private keys from the seed which is held on this device for the current wallet. In order to fully recover your wallet you will also need either your node that you created the wallet on or your recovery seed which should have been saved by you when you created this wallet."
//                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 120)
//                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 120)
                    
                default:
                    
                    label.text = ""
                    
                }
                
            } else if wallet.type == "DEFAULT"  {
                
                switch section {
                    
                case 0:
                
                    label.text = "This Recovery QR can be used with either FullyNoded 2 or StandUp.app to recover this wallet. ENSURE you back it up safely."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 50)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 50)
                    
                case 1: label.text = "You can recover this wallet with BIP39 compatible wallets and tools, by default there is no passphrase associated with this mnemonic."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                case 2: label.text = "Your public key descriptor can be used to easily create watch-only wallets with Bitcoin Core or supplement multisig wallet recovery. You may use it to derive the addresses associated with this wallet."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                case 3: label.text = "Your private key descriptor can be used to recover or spend from your wallet by importing it into your node. You may use it to derive the private keys associated with this wallet which are held on this device."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
//                case 4: label.text = "You may paste these two commands directly into a terminal where Bitcoin Core is running and your node will automatically import all the private keys from the current wallet."
//                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
//                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                default:
                    
                    label.text = ""
                    
                }
                
            } else {
                
                label.text = ""
                
            }
            
        } else {
            
            label.text = ""
            
        }
        
        footerView.addSubview(label)
        
        return footerView
        
    }
    
    func goToQRDisplayer() {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "showQR", sender: self)
            
        }
        
    }
    
    func xpub(descriptorStruct: DescriptorStruct, completion: @escaping ((String)) -> Void) {
        
        KeyFetcher.accountXpub(descriptorStruct: descriptorStruct) { (xpub, error) in
            
            if !error {
                
                completion((xpub!))
                
            } else {
                
                completion((""))
                
            }
            
        }
        
    }
    
    func xprv(completion: @escaping ((String)) -> Void) {
        
        KeyFetcher.accountXprv { [unowned vc = self] (xprv, error) in
            
            if !error {
                
                completion((xprv!))
                
            } else {
                
                if vc.wallet.xprv != nil {
                    
                    let encryptedXprv = vc.wallet.xprv!
                    Encryption.decryptData(dataToDecrypt: encryptedXprv) { (xprv) in
                        
                        if xprv != nil {
                            
                            if let xprvString = String(data: xprv!, encoding: .utf8) {
                                
                                completion((xprvString))
                                
                            } else {
                                
                                completion((""))
                                
                            }
                            
                            
                        } else {
                            
                            completion((""))
                            
                        }
                        
                    }
                    
                } else {
                    
                    completion((""))
                    
                }
                                
            }
            
        }
        
    }
    
//    func shareRecoveryCommand() {
//        
//        DispatchQueue.main.async {
//            
//            let activityViewController = UIActivityViewController(activityItems: [self.recoveryText],
//                                                                  applicationActivities: nil)
//            
//            activityViewController.popoverPresentationController?.sourceView = self.view
//            self.present(activityViewController, animated: true) {}
//            
//        }
//        
//    }
    
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
                            getActiveWalletNow { (wallet, error) in
                                
                                if wallet != nil && !error {
                                    
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        
                                        vc.tableView.alpha = 1
                                        vc.wallet = wallet!
                                        vc.loadData()
                                        
                                    }
                                    
                                } else {
                                    
                                    displayAlert(viewController: vc, isError: true, message: "no active wallet")
                                    
                                }
                                
                            }
                            
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
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        let id = segue.identifier
        
        switch id {
            
        case "showQR":
            
            if let vc = segue.destination as? QRViewController {
                
                vc.itemToDisplay = itemToDisplay
                vc.barTitle = barTitle
                vc.infoText = infoText
                
            }
            
        default:
            
            break
            
        }
        
    }

}
