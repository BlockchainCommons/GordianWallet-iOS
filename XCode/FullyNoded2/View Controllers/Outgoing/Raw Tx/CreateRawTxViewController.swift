//
//  CreateRawTxViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import UIKit

class CreateRawTxViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UINavigationControllerDelegate {
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    var qrCode = UIImage()
    var spendable = Double()
    var rawTxUnsigned = String()
    var incompletePsbt = String()
    var rawTxSigned = String()
    var amountAvailable = Double()
    let qrImageView = UIImageView()
    var stringURL = String()
    var address = String()
    let nextButton = UIButton()
    var amount = String()
    var blurArray = [UIVisualEffectView]()
    let rawDisplayer = RawDisplayer()
    var scannerShowing = false
    var isFirstTime = Bool()
    var outputs = [Any]()
    var outputsString = ""
    var recipients = [String]()
    let scannerButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    
    @IBOutlet weak var addOutlet: UIButton!
    @IBOutlet var addressInput: UITextView!
    @IBOutlet var amountInput: UITextField!
    @IBOutlet var amountLabel: UILabel!
    @IBOutlet var actionOutlet: UIButton!
    @IBOutlet var receivingLabel: UILabel!
    @IBOutlet var outputsTable: UITableView!
    @IBOutlet var scannerView: UIImageView!
    @IBOutlet weak var availableBalance: UILabel!
    @IBOutlet weak var createOutlet: UIButton!
    @IBOutlet weak var feeSliderOutlet: UISlider!
    @IBOutlet weak var blockTargetOutlet: UILabel!
    
    
    let creatingView = ConnectingView()
    let qrScanner = QRScanner()
    var isTorchOn = Bool()
    var outputArray = [[String:String]]()
    
    func configureScanner() {
        
        isFirstTime = true
        addOutlet.alpha = 0
        createOutlet.alpha = 0
        scannerView.alpha = 0
        scannerView.frame = view.frame
        scannerView.isUserInteractionEnabled = true
        
        qrScanner.scanningBip21 = true
        qrScanner.keepRunning = false
        qrScanner.vc = self
        qrScanner.imageView = scannerView
        qrScanner.textField.alpha = 0
        qrScanner.downSwipeAction = { self.back() }
        qrScanner.completion = { self.getQRCode() }
        qrScanner.didChooseImage = { self.didPickImage() }
        
        qrScanner.uploadButton.addTarget(self,
                                         action: #selector(self.chooseQRCodeFromLibrary),
                                         for: .touchUpInside)
        
        qrScanner.torchButton.addTarget(self,
                                        action: #selector(toggleTorch),
                                        for: .touchUpInside)
        
        isTorchOn = false
        
        qrScanner.closeButton.addTarget(self,
                                        action: #selector(back),
                                        for: .touchUpInside)
        
    }
    
    func addScannerButtons() {
        
        self.addBlurView(frame: CGRect(x: self.scannerView.frame.maxX - 80,
                                       y: self.scannerView.frame.maxY - 80,
                                       width: 70,
                                       height: 70), button: self.qrScanner.uploadButton)
        
        self.addBlurView(frame: CGRect(x: 10,
                                       y: self.scannerView.frame.maxY - 80,
                                       width: 70,
                                       height: 70), button: self.qrScanner.torchButton)
        
    }
    
    func updateLeftBarButton(isShowing: Bool){
        
        scannerButton.addTarget(self, action: #selector(scanNow(_:)), for: .touchUpInside)
        scannerButton.tintColor = .white

        if isShowing {
            
            let pasteImage = UIImage.init(systemName: "doc.append")
            scannerButton.setImage(pasteImage, for: .normal)
            
        } else {
            
            let qrImage = UIImage.init(systemName: "qrcode.viewfinder")
            scannerButton.setImage(qrImage, for: .normal)
            
        }
        
        let leftButton = UIBarButtonItem(customView: scannerButton)
        
        self.navigationItem.setLeftBarButtonItems([leftButton], animated: true)
        
    }
    
    @IBAction func scanNow(_ sender: Any) {
        
        print("scanNow")
        
        if scannerShowing {
            
            back()
            
        } else {
            
            scannerShowing = true
            addressInput.resignFirstResponder()
            amountInput.resignFirstResponder()
            
            if isFirstTime {
                
                DispatchQueue.main.async {
                    
                    self.qrScanner.scanQRCode()
                    self.addScannerButtons()
                    self.scannerView.addSubview(self.qrScanner.closeButton)
                    self.isFirstTime = false
                    
                    UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                        
                        vc.scannerView.alpha = 1
                        
                    })
                                                            
                }
                
            } else {
                
                self.qrScanner.startScanner()
                self.addScannerButtons()
                
                DispatchQueue.main.async {
                    
                    UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                        
                        vc.scannerView.alpha = 1
                        
                    })
                    
                }
                
            }
            
            self.updateLeftBarButton(isShowing: true)
            
        }
        
    }
    
    func addOut() {
        
        if amountInput.text != "" && addressInput.text != "" && amountInput.text != "0.0" {
            
            let dict = ["address":addressInput.text!, "amount":amountInput.text!] as [String : String]
            
            outputArray.append(dict)
            recipients.append(addressInput.text!)
            
            DispatchQueue.main.async { [unowned vc = self] in
                vc.amountInput.text = ""
                vc.addressInput.text = ""
                vc.outputsTable.reloadData()
                
            }
            
        } else {
            
            displayAlert(viewController: self,
                         isError: true,
                         message: "You need to fill out a recipient and amount first then tap this button, this button is used for adding multiple recipients aka \"batching\".")
            
        }
        
    }
    
    @IBAction func addOutput(_ sender: Any) {
        outputsTable.alpha = 1
        addOut()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Recipients:"
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 30
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
        (view as! UITableViewHeaderFooterView).textLabel?.textAlignment = .left
        (view as! UITableViewHeaderFooterView).textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)//UIFont.init(name: "System", size: 12)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return outputArray.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 85
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = view.backgroundColor
        
        if outputArray.count > 0 {
            
            if outputArray.count > 1 {
                
                tableView.separatorColor = UIColor.white
                tableView.separatorStyle = .singleLine
                
            }
            
            let address = outputArray[indexPath.row]["address"]!
            let amount = outputArray[indexPath.row]["amount"]!
            
            cell.textLabel?.text = "Value: \(String(describing: amount))\n\n\(String(describing: address))"
            
        } else {
            
           cell.textLabel?.text = ""
            
        }
        
        return cell
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        amountInput.delegate = self
        addressInput.delegate = self
        outputsTable.delegate = self
        outputsTable.dataSource = self
        navigationController?.delegate = self
        outputsTable.tableFooterView = UIView(frame: .zero)
        outputsTable.alpha = 0
        availableBalance.alpha = 0
        configureScanner()
        addTapGesture()
        scannerView.alpha = 0
        scannerView.backgroundColor = UIColor.black
        updateLeftBarButton(isShowing: false)
        addressInput.layer.borderWidth = 1.0
        addressInput.layer.borderColor = UIColor.darkGray.cgColor
        addressInput.clipsToBounds = true
        addressInput.layer.cornerRadius = 4
        feeSliderOutlet.addTarget(self, action: #selector(setFee), for: .allEvents)
        feeSliderOutlet.maximumValue = 2 * -1
        feeSliderOutlet.minimumValue = 432 * -1
        let ud = UserDefaults.standard
        
        if ud.object(forKey: "feeTarget") != nil {
            
            let numberOfBlocks = ud.object(forKey: "feeTarget") as! Int
            feeSliderOutlet.value = Float(numberOfBlocks) * -1
            updateFeeLabel(label: blockTargetOutlet, numberOfBlocks: numberOfBlocks)
            
        } else {
            
            blockTargetOutlet.text = "Minimum fee set"
            feeSliderOutlet.value = 432 * -1
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        scannerButton.tintColor = .white
        amount = ""
        outputs.removeAll()
        outputArray.removeAll()
        outputsString = ""
        outputsTable.reloadData()
        incompletePsbt = ""
        rawTxSigned = ""
        outputsTable.alpha = 0
        
        getActiveWalletNow() { (wallet, error) in
            
            if wallet != nil {
                
                NodeLogic.sharedInstance.loadWalletData(wallet: wallet!) { (success, dictToReturn, errorDesc) in
                    
                    if success && dictToReturn != nil {
                        let s = HomeStruct(dictionary: dictToReturn!)
                        let btc = (s.coldBalance).doubleValue
                        let fiat = s.fiatBalance
                        
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.availableBalance.text = "\(btc) btc / \(fiat) available"
                            vc.availableBalance.alpha = 1
                            
                        }
                        
                    }
                    
                }
                                
            }
            
        }
        
        if amountInput.text != "" && addressInput.text != "" {
            createOutlet.alpha = 1
            addOutlet.alpha = 1
            
        } else {
            createOutlet.alpha = 0
            addOutlet.alpha = 0
            
        }
        
    }
    
    func addTapGesture() {
        
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(self.dismissKeyboard (_:)))
        
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        
    }
    
    func getQRCode() {
        
        let stringURL = qrScanner.stringToReturn
        processBIP21(url: stringURL)
        
    }
    
    // MARK: User Actions
    
    func confirm(raw: String) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.creatingView.removeConnectingView()
            vc.amount = ""
            vc.amountInput.text = ""
            vc.addressInput.text = ""
            vc.outputs.removeAll()
            vc.outputArray.removeAll()
            vc.outputsString = ""
            vc.outputsTable.reloadData()
            vc.rawTxSigned = raw
            vc.performSegue(withIdentifier: "goConfirm", sender: vc)
            
        }
        
    }
    
    func confirmUnsigned(psbt: String) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.creatingView.removeConnectingView()
            vc.amount = ""
            vc.amountInput.text = ""
            vc.addressInput.text = ""
            vc.outputs.removeAll()
            vc.outputArray.removeAll()
            vc.outputsString = ""
            vc.outputsTable.reloadData()
            vc.incompletePsbt = psbt
            vc.performSegue(withIdentifier: "goConfirm", sender: vc)
            
        }
    }
    
    @IBAction func tryRawNow(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.addressInput.resignFirstResponder()
            self.amountInput.resignFirstResponder()
            
        }
        
        func noNodeOrWallet() {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.outputs.removeAll()
                vc.outputArray.removeAll()
                vc.outputsString = ""
                vc.outputsTable.reloadData()
                
            }
            
            displayAlert(viewController: self, isError: true, message: "no active node or no active wallet!")
            
        }
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                getActiveWalletNow { (wallet, error) in
                    
                    if !error && wallet != nil {
                        
                        vc.tryRaw()
                        
                    } else {
                        
                        noNodeOrWallet()
                        
                    }
                    
                }
                
            } else {
                
                noNodeOrWallet()
                
            }
            
        }
        
    }
    
    @objc func tryRaw() {
        
        creatingView.addConnectingView(vc: self, description: "Creating psbt")
        
        if amountInput.text != "" && addressInput.text != "" && amountInput.text != "0.0" {
            let dict = ["address":addressInput.text!, "amount":amountInput.text!] as [String : String]
            
            outputArray.append(dict)
            recipients.append(addressInput.text!)
            
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            vc.scannerButton.tintColor = .clear
            vc.amountInput.text = ""
            vc.addressInput.text = ""
            vc.scannerButton.tintColor = .clear
            vc.createOutlet.alpha = 0
            vc.addOutlet.alpha = 0
            vc.outputsTable.reloadData()
            
        }
            
        func convertOutputs() {
            
            for output in outputArray {
                
                if let amount = output["amount"] {
                    
                    if let address = output["address"] {
                        
                        if address != "" {
                            
                            // .doubleValue extension now handles commas and decimals for Russian localization converting String to double
                            let out = [address:amount.doubleValue]
                            outputs.append(out)
                            
                        }
                        
                    }
                    
                }
                
            }
            
            outputsString = outputs.description
            outputsString = outputsString.replacingOccurrences(of: "[", with: "")
            outputsString = outputsString.replacingOccurrences(of: "]", with: "")
            getRawTx()
            
        }
        
        if outputArray.count == 0 {
            
            if self.amountInput.text != "" && self.amountInput.text != "0.0" && self.addressInput.text != "" {
                
                let dict = ["address":addressInput.text!, "amount":amountInput.text!] as [String : String]
                
                outputArray.append(dict)
                convertOutputs()
                
            } else {
                
                creatingView.removeConnectingView()
                
                displayAlert(viewController: self,
                             isError: true,
                             message: "You need to fill out an amount and a recipient")
                
            }
            
        } else if outputArray.count > 0 {
            
            convertOutputs()
            
        }
        
    }
    
    func didPickImage() {
        
        let qrString = qrScanner.qrString
        processBIP21(url: qrString)
        
    }
    
    @objc func chooseQRCodeFromLibrary() {
        
        qrScanner.chooseQRCodeFromLibrary()
        
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        
        amountInput.resignFirstResponder()
        addressInput.resignFirstResponder()
        
    }
    
    //MARK: User Interface
    
    func addBlurView(frame: CGRect, button: UIButton) {
        
        button.removeFromSuperview()
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
        blur.frame = frame
        blur.clipsToBounds = true
        blur.layer.cornerRadius = frame.width / 2
        blur.contentView.addSubview(button)
        self.scannerView.addSubview(blur)
        
    }
    
    @objc func back() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.updateLeftBarButton(isShowing: false)
            vc.scannerView.alpha = 0
            vc.scannerShowing = false
            
        }
        
    }
    
    @objc func toggleTorch() {
        
        if isTorchOn {
            
            qrScanner.toggleTorch(on: false)
            isTorchOn = false
            
        } else {
            
            qrScanner.toggleTorch(on: true)
            isTorchOn = true
            
        }
        
    }
    
    //MARK: Textfield methods
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField.text?.contains("."))! {
           let decimalCount = (textField.text?.components(separatedBy: ".")[1])?.count
            
            if decimalCount! > 7 {
                
                if let char = string.cString(using: String.Encoding.utf8) {
                    let isBackSpace = strcmp(char, "\\b")
                    
                    if (isBackSpace == -92) {
                        print("Backspace was pressed")
                        
                    } else {
                        DispatchQueue.main.async { [unowned vc = self] in
                            displayAlert(viewController: self, isError: true, message: "Only 8 decimal places allowed")
                            let txt = vc.amountInput.text!.dropLast()
                            vc.amountInput.text = "\(txt)"
                            
                        }
                    }
                }
            }
        }
        
        return true
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView == addressInput && addressInput.text != "" {
            
            processBIP21(url: addressInput.text!)
            
        } else if textView == addressInput && addressInput.text == "" {
            
            shakeAlert(viewToShake: self.qrScanner.textField)
            
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        textField.resignFirstResponder()
        
        if addressInput.text != "" {
            
            if amountInput.text != "" && amountInput.text != "0.0" && addressInput.text != "" {
                
                createOutlet.alpha = 1
                addOutlet.alpha = 1
                
            }
            
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.endEditing(true)
        return true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if isTorchOn {
            
            toggleTorch()
            
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        amount = ""
        outputs.removeAll()
        outputArray.removeAll()
        outputsString = ""
        outputsTable.reloadData()
        rawTxSigned = ""
        outputsTable.alpha = 0
        
    }
    
    //MARK: Helpers
    
    func rounded(number: Double) -> Double {
        
        return Double(round(100000000*number)/100000000)
        
    }
    
    func processBIP21(url: String) {
        
        let addressParser = AddressParser()
        let errorBool = addressParser.parseAddress(url: url).errorBool
        let errorDescription = addressParser.parseAddress(url: url).errorDescription
        
        if !errorBool {
            
            let address = addressParser.parseAddress(url: url).address
            let amount = "\(addressParser.parseAddress(url: url).amount)"
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.addressInput.resignFirstResponder()
                vc.amountInput.resignFirstResponder()
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    if amount != "0.0" {
                        
                        vc.amountInput.text = amount
                        
                    }
                    
                    if address != "" {
                        
                        vc.addressInput.text = address
                        
                    }
                    
                    if vc.amountInput.text != "" && vc.amountInput.text != "0.0" && vc.addressInput.text != "" {
                        
                        vc.createOutlet.alpha = 1
                        vc.addOutlet.alpha = 1
                        
                    }
                    
                }
                
                vc.back()
                                
            }
            
        } else {
            
            displayAlert(viewController: self, isError: true, message: errorDescription)
            
        }
        
    }
    
    enum error: Error {
        
        case noCameraAvailable
        case videoInputInitFail
        
    }
    
    //MARK: Result Parsers
    
    func getRawTx() {
        
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            
            if wallet != nil && !error {
                
                if wallet!.type == "MULTI" {
                    
                    vc.createMultiSig(wallet: wallet!)
                    
                } else if wallet!.type == "DEFAULT" {
                    
                    vc.createSingleSig()
                    
                } else {
                    
                    let descParser = DescriptorParser()
                    let descStr = descParser.descriptor(wallet!.descriptor)
                    
                    if descStr.isMulti {
                        
                        vc.createMultiSig(wallet: wallet!)
                        
                    } else {
                        
                        vc.createSingleSig()
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func createMultiSig(wallet: WalletStruct) {
        
        var amount = Double()
        for output in outputArray {
            
            let outputAmount = Double(output["amount"]!)!
            amount += outputAmount
            
        }
        
        MultiSigTxBuilder.build(outputs: outputs) { [unowned vc = self] (signedTx, unsignedPsbt, errorDescription) in
            
            if signedTx != nil {
                
                vc.confirm(raw: signedTx!)
                
            } else if unsignedPsbt != nil {
                
                vc.confirmUnsigned(psbt: unsignedPsbt!)
                
            } else {
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    //vc.amount = ""
                    vc.outputArray.removeAll()
                    vc.outputsTable.reloadData()
                    vc.rawTxSigned = ""
                    vc.outputsTable.alpha = 0
                    vc.outputsString = ""
                    vc.outputs.removeAll()
                    vc.creatingView.removeConnectingView()
                    
                    displayAlert(viewController: vc,
                                 isError: true,
                                 message: errorDescription!)
                    
                }
                
            }
            
        }
        
    }
    
    func createSingleSig() {
        
        SingleSigBuilder.build(outputs: outputs) { [unowned vc = self] (signedTx, psbt, errorDescription) in
            
            if signedTx != nil {
                
                vc.confirm(raw: signedTx!)
                
            } else if psbt != nil {
                
                vc.confirmUnsigned(psbt: psbt!)
                
            } else {
                
                DispatchQueue.main.async { [unowned vc = self] in
                    
                    //vc.amount = ""
                    vc.outputArray.removeAll()
                    vc.outputsTable.reloadData()
                    vc.rawTxSigned = ""
                    vc.outputsTable.alpha = 0
                    vc.outputsString = ""
                    vc.outputs.removeAll()
                    vc.creatingView.removeConnectingView()
                    
                    displayAlert(viewController: vc,
                                 isError: true,
                                 message: errorDescription!)
                    
                }
                
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            outputArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if outputArray.count == 0 {
                outputsTable.alpha = 0
                
                if amountInput.text == "" && addressInput.text == "" {
                    createOutlet.alpha = 0
                    addOutlet.alpha = 0
                    
                }
                
            }
            
        }
        
    }
    
    func updateFeeLabel(label: UILabel, numberOfBlocks: Int) {
        
        let seconds = ((numberOfBlocks * 10) * 60)
        let ud = UserDefaults.standard
        
        func updateFeeSetting() {
            
            ud.set(numberOfBlocks, forKey: "feeTarget")
            
        }
        
        DispatchQueue.main.async {
            
            if seconds < 86400 {
                
                if seconds < 3600 {
                    
                    DispatchQueue.main.async {
                        
                        label.text = "\(seconds / 60) minutes (\(numberOfBlocks) blocks)"
                        
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        
                        label.text = "\(seconds / 3600) hours (\(numberOfBlocks) blocks)"
                        
                    }
                    
                }
                
            } else {
                
                DispatchQueue.main.async {
                    
                    label.text = "\(seconds / 86400) days (\(numberOfBlocks) blocks)"
                    
                }
                
            }
            
            updateFeeSetting()
            
        }
            
    }
    
    @objc func setFee(_ sender: UISlider) {
        
        let numberOfBlocks = Int(sender.value) * -1
        updateFeeLabel(label: blockTargetOutlet, numberOfBlocks: numberOfBlocks)
            
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier
        
        switch id {
            
        case "goConfirm":
            
            if let vc = segue.destination as? ConfirmViewController {
                vc.signedRawTx = rawTxSigned
                vc.recipients = recipients
                vc.unsignedPsbt = incompletePsbt
                
            }
            
        default:
            
            break
            
        }
        
    }
    
}



