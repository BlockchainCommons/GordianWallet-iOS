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
    
    var xprivs = ""
    var xpubs = ""
    var verified = Bool()
    let qrGenerator = QRGenerator()
    var recoveryQr = ""
    var recoveryImage = UIImage()
    var lifeHashImage:UIImage!
    var seed = ""
    var itemToDisplay = ""
    var wallet:WalletStruct!
    var accountSeeds = [String]()
    
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var editLabelOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editLabelOutlet.alpha = 0
        tableView.alpha = 0
        accountLabel.alpha = 0
        verified = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        #if !targetEnvironment(simulator)
        if !verified {
            showAuth()
        }
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
    
    @IBAction func deletAccount(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            let alert = UIAlertController(title: "Delete account?", message: "Are you sure!? It will be gone forever!", preferredStyle: alertStyle)
            alert.addAction(UIAlertAction(title: "💀 Delete", style: .destructive, handler: { [unowned vc = self] action in
                vc.deleteAccountNow()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func deleteAccountNow() {
        if wallet.id != nil {
            CoreDataService.deleteEntity(id: wallet.id!, entityName: .wallets) { [unowned vc = self] (success, errorDescription) in
                if success {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .seedDeleted, object: nil, userInfo: nil)
                        vc.navigationController?.popToRootViewController(animated: true)
                    }
                } else {
                    showAlert(vc: vc, title: "Error", message: "Ooops, there was an error deleting this account")
                }
            }
        }
    }
    
    @IBAction func editLabel(_ sender: Any) {
        let title = "Give your wallet a label"
        let message = "Add a label so you can easily identify your wallets"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Add a label"
            textField.keyboardAppearance = .dark
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [unowned vc = self] (alertAction) in
            let textFields = alert.textFields
            weak var textField:UITextField?
            
            if textFields != nil {
                
                if textFields!.count > 0 {
                    
                    textField = textFields![0]
                    
                    if textField!.text! != "" {
                        
                        let newLabel = textField!.text!
                        
                        CoreDataService.updateEntity(id: vc.wallet.id!, keyToUpdate: "label", newValue: newLabel, entityName: .wallets) { [unowned vc = self] (success, errorDescription) in
                            
                            if success {
                                
                                DispatchQueue.main.async {
                                    
                                    vc.accountLabel.text = newLabel
                                    
                                }
                                
                            } else {
                                
                                showAlert(vc: vc, title: "Error!", message: "There was a problem saving your wallets label")
                                
                            }
                                                        
                        }
                        
                    }
                    
                }
                
            }
            
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default) { _ in })
        self.present(alert, animated:true, completion: nil)
        
    }
    
    @objc func handleCopyTap(_ sender: UIButton) {
        
        let section = sender.tag
        
        var textToCopy = ""
        var message = ""
        
        switch section {
            
        case 0:
            message = "your \"Lifehash\" was copied to your clipboard"
            DispatchQueue.main.async { [unowned vc = self] in
                UIPasteboard.general.image = vc.lifeHashImage
            }
            
        case 1:
            message = "your \"Account Map\" was copied to your clipboard"
            DispatchQueue.main.async { [unowned vc = self] in
                UIPasteboard.general.image = vc.recoveryImage
            }
            
        case 2:
            textToCopy = "Devices seed:" + " " + seed + "derivation: \(wallet.derivation)/0" + "blockheight: \(wallet.blockheight)"
            message = "your seed was copied to your clipboard and will be erased in one minute"
            DispatchQueue.main.async {
                UIPasteboard.general.string = textToCopy
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                
                UIPasteboard.general.string = ""
                
            }
            
        case 3:
            textToCopy = "Account xpub's: \(xpubs)"
            message = "your xpub's were copied to your clipboard and will be erased in one minute"
            DispatchQueue.main.async {
                UIPasteboard.general.string = textToCopy
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                
                UIPasteboard.general.string = ""
                
            }
            
        default:
            break
        }
        
        
        
        displayAlert(viewController: self, isError: false, message: message)
        
    }
        
    @objc func handleShareTap(_ sender: UIButton) {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        let section = sender.tag
        
        switch section {
        
        case 0:
            shareImage(image: lifeHashImage)
            
        case 1:
            shareImage(image: recoveryImage)
            
        case 2:
            itemToDisplay = seed
            shareText()
            
        case 3:
            itemToDisplay = xpubs
            shareText()
            
        case 4:
            itemToDisplay = xprivs
            shareText()

        default:
            break
        }
        
    }
    
    @objc func handleQRTap(_ sender: UIButton) {
        
        let section = sender.tag
        
        switch section {
            
        case 2:
            itemToDisplay = seed
            goToQRDisplayer()
            
        case 3:
            itemToDisplay = xpubs
            goToQRDisplayer()
            
        case 4:
            itemToDisplay = xprivs
            goToQRDisplayer()

            
        default:
            break
            
        }
        
    }
    
    @objc func deleteSeed() {
        DispatchQueue.main.async { [unowned vc = self] in
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            let alert = UIAlertController(title: "Delete seed words?", message: "Make sure you have them backed up so that you can always recover this account with this app or others. If you are using these seed words for more then one account it is important to know they will be deleted from ALL accounts. You will still be able to spend using this account as we store your account xprv and use that for signing transactions, we only save seed words to give you a chance to back them up. If you want to make the account cold then you also need to delete the xprvs.", preferredStyle: alertStyle)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [unowned vc = self] action in
                vc.deleteSeedNow()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func deleteSeedNow() {
        let spinner = ConnectingView()
        spinner.addConnectingView(vc: self, description: "deleting seed...")
                
        if let encryptedSeeds = KeyChain.seeds() {
            var decryptedSeeds:[String] = []
            
            func removeSeeds() {
                var newSeeds:[String] = []
                for (i, seed) in decryptedSeeds.enumerated() {
                    for (a, accountSeed) in accountSeeds.enumerated() {
                        if accountSeed != seed {
                            newSeeds.append(seed)
                        }
                        if i + 1 == decryptedSeeds.count && a + 1 == accountSeeds.count {
                            decryptedSeeds = []
                            KeyChain.overWriteExistingSeeds(unencryptedSeeds: newSeeds) { [unowned vc = self] (success) in
                                if success {
                                    vc.loadData()
                                    showAlert(vc: vc, title: "Success ✓", message: "Seed has been removed")
                                    spinner.removeConnectingView()
                                    newSeeds = []
                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: .seedDeleted, object: nil, userInfo: nil)
                                    }
                                } else {
                                    showAlert(vc: vc, title: "Error", message: "There was an error removing your seed")
                                    spinner.removeConnectingView()
                                    newSeeds = []
                                }
                            }
                        }
                    }
                }
            }
            
            for (i, encryptedSeed) in encryptedSeeds.enumerated() {
                Encryption.decryptData(dataToDecrypt: encryptedSeed) { decryptedSeed in
                    if decryptedSeed != nil {
                        if let words = String(data: decryptedSeed!, encoding: .utf8) {
                            decryptedSeeds.append(words)
                            if i + 1 == encryptedSeeds.count {
                                removeSeeds()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func shareText() {
        DispatchQueue.main.async { [unowned vc = self] in
            let textToShare = [vc.itemToDisplay]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = vc.view
            activityViewController.popoverPresentationController?.sourceRect = vc.view.bounds
            vc.present(activityViewController, animated: true) {}
        }
    }
    
    func shareImage(image: UIImage) {
        DispatchQueue.main.async { [unowned vc = self] in
            let imageToShare = [image]
            let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = vc.view
            activityViewController.popoverPresentationController?.sourceRect = vc.view.bounds
            vc.present(activityViewController, animated: true) {}
        }
    }
    
    func loadData() {
        
        xprvs()
        
        let arr = wallet.descriptor.split(separator: "#")
        let plainDesc = "\(arr[0])".replacingOccurrences(of: "'", with: "h")
        let recoveryQr = ["descriptor":"\(plainDesc)", "blockheight":wallet.blockheight, "label": wallet.label] as [String : Any]
        
        if let json = recoveryQr.json() {
            
            let (qr, error) = qrGenerator.getQRCode(textInput: json)
            recoveryImage = qr
            
            if error {
                
                showAlert(vc: self, title: "QR Error", message: "There is too much data to squeeze into that small of an image")
                
            }
            
        }
        
        SeedParser.fetchSeeds(wallet: wallet) { [unowned vc = self] (seeds, fingerprints) in
            
            var str = ""
            vc.accountSeeds.removeAll()
            vc.seed = ""
            
            if seeds != nil {
                
                vc.accountSeeds = seeds!
                
                for (x, s) in seeds!.enumerated() {
                    
                    let arr = s.split(separator: " ")
                    
                    for (i, word) in arr.enumerated() {
                        
                        if i + 1 == arr.count {
                            
                            /// There are multiple seeds so split them up with a triple new line.
                            if x == 0 && seeds!.count > 1 {
                                
                               str += "\(i + 1). \(word)\n\n\n"
                                
                            } else {
                                
                                /// Its the last word of the last seed.
                                str += "\(i + 1). \(word)"
                                
                            }
                            
                        } else {
                            
                            /// Its not the last word, add a new line between each seed word.
                            str += "\(i + 1). \(word)\n"
                            
                        }
                        
                    }
                    
                    if x + 1 == seeds!.count {
                        vc.seed = str
                        
                        DispatchQueue.main.async { [unowned vc = self] in
                            
                            vc.tableView.reloadData()
                            
                        }
                        
                    }
                                
                }
                
            } else {
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    vc.tableView.reloadData()
                    
                }
                
            }
            
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            vc.accountLabel.text = vc.wallet.label
            vc.lifeHashImage = LifeHash.image(vc.wallet.descriptor)
            vc.tableView.reloadData()
            
            UIView.animate(withDuration: 0.2) {
                vc.editLabelOutlet.alpha = 1
                vc.accountLabel.alpha = 1
                vc.tableView.alpha = 1
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 0:
            return 126
        case 1:
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
                
        return 5
        
    }
    
    private func lifehashCell(_ indexPath: IndexPath) -> UITableViewCell {
        let lifehashCell = tableView.dequeueReusableCell(withIdentifier: "lifehashCell", for: indexPath)
        lifehashCell.selectionStyle = .none
        let imageview = lifehashCell.viewWithTag(1) as! UIImageView
        imageview.clipsToBounds = true
        imageview.layer.magnificationFilter = .nearest
        imageview.layer.cornerRadius = 5
        imageview.image = self.lifeHashImage
        return lifehashCell
    }
        
    private func recoveryCell(_ indexPath: IndexPath) -> UITableViewCell {
        let recoveryCell = tableView.dequeueReusableCell(withIdentifier: "recoveryCell", for: indexPath)
        recoveryCell.selectionStyle = .none
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
        
        if seed == "" {
            cell.textLabel?.text = "⚠︎ No seed on device"
        } else {
            cell.textLabel?.text = seed
        }
        
        return cell
    }
    
    private func xpubsCell(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.backgroundColor = #colorLiteral(red: 0.0507061556, green: 0.05862525851, blue: 0.0711022839, alpha: 1)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = .lightGray
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        
        if wallet != nil {
            let descriptorParser = DescriptorParser()
            let descriptorStruct = descriptorParser.descriptor(wallet.descriptor)
            var xpubtext = ""
            for key in descriptorStruct.keysWithPath {
                xpubtext += key.replacingOccurrences(of: "/0/*", with: "") + "\n\n"
            }
            xpubs = "\(xpubtext.split(separator: ")")[0])"
            cell.textLabel?.text = xpubs
            
        }
        
        return cell
        
    }
    
    private func decryptedValue(data: Data) -> String? {
        var stringToReturn:String?
        Encryption.decryptData(dataToDecrypt: data) { (decryptedValue) in
            if decryptedValue != nil {
                if let xprv = String(bytes: decryptedValue!, encoding: .utf8) {
                    stringToReturn = xprv
                }
            }
        }
        return stringToReturn
    }
    
    private func xprvs() {
        xprivs = ""
        if wallet != nil {
            if wallet.xprvs != nil {
                for encryptedXprv in wallet.xprvs! {
                    if let xprv = decryptedValue(data: encryptedXprv) {
                        let descriptorParser = DescriptorParser()
                        let descriptorStruct = descriptorParser.descriptor(wallet.descriptor)
                        let keysWithPath = descriptorStruct.keysWithPath
                        for xpubWithPath in keysWithPath {
                            let arr = xpubWithPath.split(separator: "]")
                            let arr2 = "\(arr[1])".split(separator: ")")
                            let xpub = "\(arr2[0])".replacingOccurrences(of: "/0/*", with: "")
                            if let hdkey = HDKey(xprv) {
                                if xpub == hdkey.xpub {
                                    xprivs += "\(arr[0])]" + xprv + "\n\n"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func xprvsCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = #colorLiteral(red: 0.0507061556, green: 0.05862525851, blue: 0.0711022839, alpha: 1)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = .lightGray
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        if xprivs == "" {
            cell.textLabel?.text = "No xprvs on device ⚠︎"
        } else {
            cell.textLabel?.text = xprivs
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            return lifehashCell(indexPath)
            
        case 1:
            return recoveryCell(indexPath)
            
        case 2:
            return seedCell(indexPath)
                        
        case 3:
            return xpubsCell(indexPath)
            
        case 4:
            return xprvsCell(indexPath)
            
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
        
        let deleteButton = UIButton()
        let deleteImage = UIImage(systemName: "trash")
        deleteButton.setImage(deleteImage, for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.tag = section
        deleteButton.frame = CGRect(x: copyButton.frame.minX - 30, y: 0, width: 20, height: 20)
        deleteButton.center.y = textLabel.center.y
        
        switch section {
            
        case 0:
            textLabel.text = "Lifehash"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(copyButton)
            copyButton.frame = CGRect(x: shareButton.frame.minX - 30, y: 0, width: 20, height: 20)
            copyButton.center.y = shareButton.center.y
            
        case 1:
            textLabel.text = "Account Map (public keys)"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(copyButton)
            copyButton.frame = CGRect(x: shareButton.frame.minX - 30, y: 0, width: 20, height: 20)
            copyButton.center.y = shareButton.center.y
            
        case 2:
            textLabel.text = "Seed Words"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(qrButton)
            header.addSubview(copyButton)
            deleteButton.addTarget(self, action: #selector(deleteSeed), for: .touchUpInside)
            header.addSubview(deleteButton)
            
        case 3:
            textLabel.text = "Account xpubs"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(qrButton)
            header.addSubview(copyButton)
            
        case 4:
            textLabel.text = "Account xprvs"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(qrButton)
            header.addSubview(copyButton)
            deleteButton.addTarget(self, action: #selector(deleteXprvs), for: .touchUpInside)
            header.addSubview(deleteButton)
            
        default:
            
            break
            
        }
        
        return header
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        if wallet != nil {
            
            if wallet.type == "MULTI" {
                
                switch section {
                
                case 0: return 130
                
                case 1: return 50
                    
                case 2: return 130
                    
                case 3: return 80
                    
                case 4: return 150
                                        
                default:
                    
                    return 0
                    
                }
                
            } else if wallet.type == "DEFAULT"  {
                
                switch section {
                
                case 0: return 130
                
                case 1: return 50
                    
                default:
                    
                    return 80
                    
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
                
                    label.text = "Your Account's \"Lifehash\", this image can be used as a unique visualization of your Account. It is always generated on the fly, if you ever notice a change in it then something is wrong! If it changes you should proceed with caution and ensure you are using the intended Account. You will see this Lifehash displayed to you throughout the app to remind you which Account your are using."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 130)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 130)
                    
                case 1:
                    
                    label.text = "This \"Account Map\" QR can be used with FullyNoded 2 to recreate this wallet as watch-only. ENSURE you back it up safely, it is required to recover multi-sig wallets."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 50)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 50)
                    
                case 2:
                    
                    label.text = "These BIP39 mnemonics represent the seeds associated with your account. These seed words are only stored for the explicit purpose of allowing you to back them up, once you have backed them up please delete them here. The seed words are not used for any other purpose. No passphrase is used. Seed words are always encrypted and never backed up to the iCloud."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 130)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 130)
                    
                case 3:
                    
                    label.text = "The account xpubs along with their fingerprint's and paths. Your Account Map already holds all the xpubs but we export them here so you may use them in other wallets."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                case 4:
                
                    label.text = "The account xprvs along with their master key fingerprint's and paths. These xprvs are encrypted and stored on your device. We use them to sign your psbts. They will get backed up to the iCoud if you have iCloud enabled. If you want to make the device cold (not spendable) you can delete them here."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                default:
                    
                    label.text = ""
                    
                }
                
            } else if wallet.type == "DEFAULT"  {
                
                switch section {
                    
                case 0:
                
                    label.text = "Your Account's \"Lifehash\", this image can be used as a unique visualization of your Account. It is always generated on the fly, if you ever notice a change in it then something is wrong! If it changes you should proceed with caution and ensure you are using the intended Account. You will see this Lifehash displayed to you throughout the app to remind you which Account your are using."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 130)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 130)
                    
                case 1:
                    label.text = "This \"Wallet Import QR\" can be used with either FullyNoded 2 or StandUp.app to recreate this wallet as watch-only. ENSURE you back it up safely."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 50)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 50)
                    
                case 2:
                    label.text = "These BIP39 mnemonics represent the seeds associated with your account. These seed words are only stored for the explicit purpose of allowing you to back them up, once you have backed them up please delete them here. The seed words are not used for any other purpose. No passphrase is used. Seed words are always encrypted and never backed up to the iCloud."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                case 3:
                    label.text = "The account xpubs along with their fingerprint's and paths. Your Account Map already holds all the xpubs but if you want we export them here so you may use them in other wallets."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                case 4:
                    label.text = "The account xprvs along with their master key fingerprints and paths. These xprvs are encrypted and stored on your device. We use them to sign your psbts. They will get backed up to the iCoud if you have iCloud enabled. If you want to make the device cold (not spendable) you can delete them here."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                default:
                    label.text = ""
                    
                }
                
            }
            
        } else {
            
            label.text = ""
            
        }
        
        footerView.addSubview(label)
        
        return footerView
        
    }
    
    @objc func deleteXprvs() {
        DispatchQueue.main.async { [unowned vc = self] in
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            let alert = UIAlertController(title: "Delete xprvs?", message: "Are you sure!? They will be gone forever! You will no longer be able to sign transactions with this device for this account! YOU WILL NOT BE ABLE TO SPEND YOUR BITCOIN with the app alone.", preferredStyle: alertStyle)
            alert.addAction(UIAlertAction(title: "💀 Delete", style: .destructive, handler: { [unowned vc = self] action in
                vc.deleteXprvsNow()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func deleteXprvsNow() {
        if wallet != nil {
            if wallet.id != nil {
                CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "xprvs", newValue: [], entityName: .wallets) { [unowned vc = self] (success, errorDescription) in
                    if success {
                        getActiveWalletNow { (wallet, error) in
                            if wallet != nil {
                                vc.wallet = wallet!
                                vc.loadData()
                                showAlert(vc: vc, title: "xprvs deleted!", message: "The device will no longer be able to sign transactions for this account!")
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .seedDeleted, object: nil, userInfo: nil)
                                }
                            }
                        }
                    } else {
                        showAlert(vc: vc, title: "Error", message: "There was an error deleting your xprvs")
                    }
                }
            }
        }
    }
    
    func goToQRDisplayer() {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "showQR", sender: self)
            
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
                            getActiveWalletNow { (wallet, error) in
                                
                                if wallet != nil && !error {
                                    
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        vc.verified = true
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
            
            if let vc = segue.destination as? QRDisplayerViewController {
                
                vc.address = itemToDisplay
                
            }
            
        default:
            
            break
            
        }
        
    }

}
