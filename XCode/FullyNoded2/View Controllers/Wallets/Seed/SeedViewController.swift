//
//  SeedViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit
import AuthenticationServices

class SeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var xpubs = ""
    var verified = Bool()
    let qrGenerator = QRGenerator()
    var recoveryQr = ""
    var recoveryImage = UIImage()
    var seed = ""
    var itemToDisplay = ""
    var infoText = ""
    var barTitle = ""
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
        showAlert(vc: self, title: "Coming soon", message: "This button will delete this account in the very near future.")
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
            textToCopy = recoveryQr
            message = "your \"Account Map\" text was copied to your clipboard and will be erased in one minute"
            
        case 1:
            textToCopy = "Devices seed:" + " " + seed + "derivation: \(wallet.derivation)/0" + "blockheight: \(wallet.blockheight)"
            message = "your seed was copied to your clipboard and will be erased in one minute"
            
        case 2:
            textToCopy = "Account xpub's: \(xpubs)"
            message = "your xpub's were copied to your clipboard and will be erased in one minute"
            
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
            itemToDisplay = xpubs
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
            infoText = "Your BIP39 seed phrase which can be imported into BIP39 compatible wallets, by default Fully Noded does not create a passphrase for your seed words."
            barTitle = "BIP39 Mnemonic"
            goToQRDisplayer()
            
        case 2:

            itemToDisplay = xpubs
            infoText = "Your account xpub's along with fingerprints and derivation paths."
            barTitle = "Account XPUB's"
            goToQRDisplayer()

            
        default:
            
            break
            
        }
        
    }
    
    @objc func deleteSeed() {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Delete seed?", message: "Are you sure!? You WILL NOT be able to spend from this wallet and it will be watch-only.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "💀 Delete", style: .destructive, handler: { [unowned vc = self] action in
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
        CoreDataService.retrieveEntity(entityName: .seeds) { [unowned vc = self] (seeds, errorDescription) in
            if seeds != nil {
                var idsToDelete = [UUID]()
                for (i, seed) in seeds!.enumerated() {
                    let seedStruct = SeedStruct(dictionary: seed)
                    if let encryptedSeed = seedStruct.seed {
                        Encryption.decryptData(dataToDecrypt: encryptedSeed) { [unowned vc = self] decryptedSeed in
                            if decryptedSeed != nil {
                                if let words = String(data: decryptedSeed!, encoding: .utf8) {
                                    for accountSeed in vc.accountSeeds {
                                        if accountSeed == words {
                                            if seedStruct.id != nil {
                                                idsToDelete.append(seedStruct.id!)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if i + 1 == seeds!.count {
                        var succeeded = false
                        for (x, id) in idsToDelete.enumerated() {
                            CoreDataService.deleteEntity(id: id, entityName: .seeds) { (success, errorDescription) in
                                if success {
                                    succeeded = true
                                } else {
                                    succeeded = false
                                }
                                if x + 1 == idsToDelete.count {
                                    vc.loadData()
                                    if succeeded {
                                        displayAlert(viewController: vc, isError: false, message: "Device's seed deleted")
                                    } else {
                                        showAlert(vc: vc, title: "Error", message: "There was an error deleting one of your device's seeds.")
                                    }
                                    spinner.removeConnectingView()
                                }
                            }
                        }
                    }
                }
            }
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
        
        let recoveryQr = ["descriptor":"\(wallet.descriptor)", "blockheight":wallet.blockheight, "label": wallet.label] as [String : Any]
        
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
                
        return 3
        
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
            
            return seedCell(indexPath)
                        
        case 2:
            
            return xpubsCell(indexPath)
            
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
        deleteButton.addTarget(self, action: #selector(deleteSeed), for: .touchUpInside)
        deleteButton.frame = CGRect(x: copyButton.frame.minX - 30, y: 0, width: 20, height: 20)
        deleteButton.center.y = textLabel.center.y
        
        switch section {
            
        case 0:
            textLabel.text = "Account Map (public keys)"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(copyButton)
            copyButton.frame = CGRect(x: shareButton.frame.minX - 30, y: 0, width: 20, height: 20)
            copyButton.center.y = shareButton.center.y
            
        case 1:
            textLabel.text = "Seed Words"
            header.addSubview(textLabel)
            header.addSubview(shareButton)
            header.addSubview(qrButton)
            header.addSubview(copyButton)
            header.addSubview(deleteButton)
            
        case 2:
            textLabel.text = "Account XPUB's"
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
                                        
                default:
                    
                    return 0
                    
                }
                
            } else if wallet.type == "DEFAULT"  {
                
                return 80
                
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
                    
                    label.text = "This \"Account Map\" QR can be used with FullyNoded 2 to recreate this wallet as watch-only. ENSURE you back it up safely, it is required to recover multi-sig wallets."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 50)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 50)
                    
                case 1:
                    
                    label.text = "This BIP39 mnemonic represents one of three seeds associated with your multisig wallet, this is the only seed held on this device for this wallet. You may use this seed to derive all the private keys needed for signing one of the two required signatures for spending from your StandUp multisig wallet. You should back this up in multiple places, because it is a multisig wallet an attacker can not do anything with this seed alone."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 130)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 130)
                    
                case 2:
                    
                    label.text = "The account xpub's along with their fingerprint's and paths. Your Account Map already holds all the xpub's but we export them here so you may use them in other wallets."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                default:
                    
                    label.text = ""
                    
                }
                
            } else if wallet.type == "DEFAULT"  {
                
                switch section {
                    
                case 0:
                
                    label.text = "This \"Wallet Import QR\" can be used with either FullyNoded 2 or StandUp.app to recreate this wallet as watch-only. ENSURE you back it up safely."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 50)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 50)
                    
                case 1: label.text = "You can recover this account with BIP39 compatible wallets and tools, by default there is no passphrase associated with the seed words created by Fully Noded 2."
                    footerView.frame = CGRect(x: 0, y: 10, width: tableView.frame.size.width - 50, height: 80)
                    label.frame = CGRect(x: 10, y: 0, width: tableView.frame.size.width - 50, height: 80)
                    
                case 2: label.text = "The account xpub's along with their fingerprint's and paths. Your Account Map already holds all the xpub's but if you want we export them here so you may use them in other wallets."
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
