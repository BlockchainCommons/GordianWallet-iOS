//
//  ScannerViewController.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import URKit
import UIKit
import LibWally
import AVFoundation

class ScannerViewController: UIViewController, UINavigationControllerDelegate {
    
    var isUpdatingNode = Bool()
    var scanningShards = Bool()
    var verifying = Bool()
    var scanningBip21 = Bool()
    var scanningRecovery = Bool()
    var isScanningNode = Bool()
    var isImporting = Bool()
    let label = UILabel()
    let labelDetail = UILabel()
    let addTestingNodeButton = UIButton()
    let avCaptureSession = AVCaptureSession()
    var stringToReturn = ""
    var keepRunning = true
    let imagePicker = UIImagePickerController()
    var qrString = ""
    let uploadButton = UIButton()
    let torchButton = UIButton()
    let closeButton = UIButton()
    let blurHeaderView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemChromeMaterialDark))
    let downSwipe = UISwipeGestureRecognizer()
    var blurArray = [UIVisualEffectView]()
    var decoder:URDecoder!
    var isScanningInvoice = Bool()
    var unsignedPsbt = ""
    var signedRawTx = ""
    var nodeId:UUID!
    var words = ""
    var isRecovering = Bool()
    var onDoneRecoveringBlock : (([String:Any]) -> Void)?
    var onDoneBlock : ((Bool) -> Void)?
    var returnStringBlock: ((String) -> Void)?
    var onPsbtScanDoneBlock: ((String) -> Void)?
    var isTorchOn = Bool()
    let connectingView = ConnectingView()
    var alertStyle = UIAlertController.Style.actionSheet
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var backgroundView: UIVisualEffectView!
    @IBOutlet weak var progressDescriptionLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectingView.addConnectingView(vc: self, description: "")
        
        navigationController?.delegate = self
        
        if (UIDevice.current.userInterfaceIdiom == .pad) {
          alertStyle = UIAlertController.Style.alert
        }
        
        decoder = URDecoder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        scanNow()
        
        if UIPasteboard.general.hasImages {
            
            if let image = UIPasteboard.general.image {
                
                let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
                let ciImage:CIImage = CIImage(image: image)!
                var qrCodeLink = ""
                let features = detector.features(in: ciImage)
                for feature in features as! [CIQRCodeFeature] {
                    qrCodeLink += feature.messageString!
                }
                
                if qrCodeLink.hasPrefix("btcrpc://") || qrCodeLink.hasPrefix("btcstandup://") {
                
                DispatchQueue.main.async { [unowned vc = self] in
                                
                    let alert = UIAlertController(title: "There is a QuickConnect uri on your clipboard", message: "Would you like to add this node?", preferredStyle: vc.alertStyle)

                    alert.addAction(UIAlertAction(title: "Add Node", style: .default, handler: { action in
                        
                        vc.processQRString(url: qrCodeLink)
                        
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    alert.popoverPresentationController?.sourceView = self.view
                    vc.present(alert, animated: true, completion: nil)
                    
                    }
                    
                }
                
            }
            
        } else if UIPasteboard.general.hasStrings {
            
            if let value = UIPasteboard.general.string {
                
                if value.hasPrefix("btcrpc://") || value.hasPrefix("btcstandup://") {
                    
                    DispatchQueue.main.async { [unowned vc = self] in
                                    
                        let alert = UIAlertController(title: "There is a QuickConnect uri on your clipboard", message: "Would you like to add this node?", preferredStyle: vc.alertStyle)

                        alert.addAction(UIAlertAction(title: "Add Node", style: .default, handler: { action in
                            vc.processQRString(url: value)
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        alert.popoverPresentationController?.sourceView = self.view
                        vc.present(alert, animated: true, completion: nil)
                        
                    }
                    
                } else if value.hasPrefix("01") || value.hasPrefix("02") {
                    connectingView.addConnectingView(vc: self, description: "converting to psbt")
                    Reducer.makeCommand(walletName: "", command: .converttopsbt, param: "\"\(value)\"") { (object, errorDescription) in
                        if let psbt = object as? String {
                            self.stopScanning(psbt)
                        }
                    }
                }
            }
        }
    }
    
    @objc func addTester() {
        
        if isScanningNode {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                let alert = UIAlertController(title: "Connect to our testing node?", message: "We have a testnet node you can borrow for testing purposes only, just tap \"Add Testing Node\" to use it. This is a great way to get comfortable with the app and gain an idea of how it works.", preferredStyle: vc.alertStyle)

                alert.addAction(UIAlertAction(title: "Add Testing Node", style: .default, handler: { [unowned vc = self] action in
                    vc.addnode()
                }))
                
                #if targetEnvironment(macCatalyst)
                alert.addAction(UIAlertAction(title: "Upload QR", style: .default, handler: { [unowned vc = self] action in
                    vc.chooseQRCodeFromLibrary()
                }))
                #endif
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        
                alert.popoverPresentationController?.sourceView = vc.view
                vc.present(alert, animated: true, completion: nil)
                
            }
            
        } else if isRecovering {
            
            let url = URL(string: "https://github.com/BlockchainCommons/GordianWallet-iOS/blob/master/Recovery.md")!
            UIApplication.shared.open(url) { (Bool) in }
            
        }
    
    }
    
    func addnode() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            let alert = UIAlertController(title: "Warning", message: "We may periodically delete testnet wallets from our testing node. Please make sure you save your recovery info when creating wallets so you can easily recover.", preferredStyle: vc.alertStyle)

            alert.addAction(UIAlertAction(title: "Add Testing Node", style: .default, handler: { [unowned vc = self] action in
                
                // Testnet Linode instance:
                let url = "btcstandup://StandUp:71e355f8e097857c932cc315f321eb4a@ftemeyifladknw3cpdhilomt7fhb3cquebzczjb7hslia77khc7cnwid.onion:1309/?label=BC%20Beta%20Test%20Node"
                vc.processQRString(url: url)

            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    func addScannerButtons() {
        self.addBlurView(frame: CGRect(x: self.view.frame.maxX - 80,
                                       y: self.view.frame.maxY - 140,
                                       width: 70,
                                       height: 70), button: self.uploadButton)
        
        self.addBlurView(frame: CGRect(x: 10,
                                       y: self.view.frame.maxY - 140,
                                       width: 70,
                                       height: 70), button: self.torchButton)
    }
    
    func didPickImage() {
        processQRString(url: qrString)
    }
    
    @objc func chooseQRCodeFromLibrary() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            #if targetEnvironment(macCatalyst)
            self.configureImagePicker()
            #endif
            
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }
    
    func addBlurView(frame: CGRect, button: UIButton) {
        button.removeFromSuperview()
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
        blur.frame = frame
        blur.clipsToBounds = true
        blur.layer.cornerRadius = frame.width / 2
        blur.contentView.addSubview(button)
        blurArray.append(blur)
        self.imageView.addSubview(blur)
    }
    
    @objc func close() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func scanNow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.scanQRNow()
            self.addScannerButtons()
            self.configure()
            self.connectingView.removeConnectingView()
        }
    }
    
    func getQRCode() {
        processQRString(url: stringToReturn)
    }
    
    @objc func toggleTorchNow() {
        if isTorchOn {
            toggleTorch(on: false)
            isTorchOn = false
        } else {
            toggleTorch(on: true)
            isTorchOn = true
        }
    }
    
    private func stopScanning(_ psbt: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeScanner()
            
            self.dismiss(animated: true) {
                self.onPsbtScanDoneBlock!(psbt)
            }
        }
    }
    
    private func processUrPsbt(text: String) {
        // Stop if we're already done with the decode.
        guard decoder.result == nil else {
            guard let result = try? decoder.result?.get(), let psbt = URHelper.psbtUrToBase64Text(result) else { return }
            stopScanning(psbt)
            return
        }

        decoder.receivePart(text.lowercased())
        
        let expectedParts = decoder.expectedPartCount ?? 0
        
        guard expectedParts != 0 else {
            guard let result = try? decoder.result?.get(), let psbt = URHelper.psbtUrToBase64Text(result) else { return }
            stopScanning(psbt)
            return
        }
        
        let percentageCompletion = "\(Int(decoder.estimatedPercentComplete * 100))% complete"
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.blurArray.count > 0 {
                for i in self.blurArray {
                    i.removeFromSuperview()
                }
                self.blurArray.removeAll()
            }
            
            self.progressView.setProgress(Float(self.decoder.estimatedPercentComplete), animated: false)
            self.progressDescriptionLabel.text = percentageCompletion
            self.backgroundView.alpha = 1
            self.progressView.alpha = 1
            self.progressDescriptionLabel.alpha = 1
        }
    }
    
    func processQRString(url: String) {
        
        func addnode() {
            let qc = QuickConnect()
            qc.addNode(vc: self, url: url) { (success, errorDesc) in
                if success {
                    DispatchQueue.main.async {
                        self.onDoneBlock!(true)
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    showAlert(vc: self, title: "Error", message: "Error adding node: \(errorDesc ?? "unknown error")")
                }
            }
        }
        
        func updateNode() {
            let qc = QuickConnect()
            qc.nodeToUpdate = self.nodeId
            qc.addNode(vc: self, url: url) { (success, errorDesc) in
                if success {
                    DispatchQueue.main.async {
                        self.onDoneBlock!(true)
                        self.dismiss(animated: true, completion: nil)
                    }
                } else {
                    showAlert(vc: self, title: "Error", message: "Error adding node: \(errorDesc ?? "unknown error")")
                }
            }
        }
        
        if isScanningInvoice {
            dismiss(animated: true) { [weak self] in
                self?.returnStringBlock!(url)
            }
        
        } else if url.hasPrefix("ur:crypto-psbt/") || url.hasPrefix("UR:CRYPTO-PSBT/") {
            processUrPsbt(text: url)
            
        } else if isImporting {
            dismiss(animated: true) { [weak self] in
                self?.returnStringBlock!(url)
            }
            
        } else if scanningShards || isScanningInvoice {
            if navigationController != nil {
                self.returnStringBlock!(url)
                navigationController?.popViewController(animated: true)
            } else {
                dismiss(animated: true) { [weak self] in
                    self?.returnStringBlock!(url)
                }
            }
            
        } else if isRecovering {
            returnStringBlock!(url)
            navigationController?.popViewController(animated: true)
            
        } else {
            if url.hasPrefix("btcrpc://") || url.hasPrefix("btcstandup://") {
                if !isUpdatingNode {
                    addnode()
                } else {
                    updateNode()
                }
                
            } else if let _ = Data(base64Encoded: url) {
                stopScanning(url)
                            
            } else if url.hasPrefix("01") || url.hasPrefix("02") {
                connectingView.addConnectingView(vc: self, description: "converting to psbt")
                Reducer.makeCommand(walletName: "", command: .converttopsbt, param: "\"\(url)\"") { (object, errorDescription) in
                    if let psbt = object as? String {
                        self.stopScanning(psbt)
                    }
                }
            } else {
                displayAlert(viewController: self, isError: true, message: "That's not a compatible QR Code!")
            }
            
        }
                
    }
    
    func configureDontHaveAnodeButton() {
        addTestingNodeButton.frame = CGRect(x: 20, y: self.labelDetail.frame.maxY + 5, width: self.blurHeaderView.frame.width - 40, height: 20)
        addTestingNodeButton.setTitleColor(.systemTeal, for: .normal)
        addTestingNodeButton.titleLabel?.font = .systemFont(ofSize: 10)
        addTestingNodeButton.backgroundColor = .clear
        blurHeaderView.contentView.addSubview(addTestingNodeButton)
    }
    
    func configureDetailLabel() {
        labelDetail.font = .systemFont(ofSize: 12, weight: .bold)
        labelDetail.numberOfLines = 0
        labelDetail.frame = CGRect(x: 20, y: self.label.frame.maxY + 5, width: self.blurHeaderView.frame.width - 40, height: 50)
        labelDetail.textColor = .systemGray
        labelDetail.clipsToBounds = true
        labelDetail.layer.cornerRadius = 8
        labelDetail.backgroundColor = .clear
        labelDetail.sizeToFit()
        blurHeaderView.contentView.addSubview(labelDetail)
        blurHeaderView.frame = CGRect(x: 16, y: 10, width: self.imageView.frame.width - 32, height: self.label.frame.height + self.labelDetail.frame.height + 55)
    }
    
    func configureLabel() {
        blurHeaderView.frame = CGRect(x: 16, y: 10, width: self.imageView.frame.width - 32, height: 150)
        blurHeaderView.clipsToBounds = true
        blurHeaderView.layer.cornerRadius = 10
        imageView.addSubview(blurHeaderView)
        label.font = .systemFont(ofSize: 28, weight: .heavy)
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.textColor = .white
        label.frame = CGRect(x: 16, y: 10, width: self.blurHeaderView.frame.width - 32, height: 50)
        label.sizeToFit()
        blurHeaderView.contentView.addSubview(label)
    }
    
    @objc func handleSwipes(_ sender: UIGestureRecognizer) {
        close()
    }
    
    func configureCloseButton() {
        closeButton.frame = CGRect(x: blurHeaderView.contentView.frame.maxX - 32, y: 5, width: 20, height: 20)
        closeButton.setImage(UIImage(systemName: "x.circle.fill"), for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        blurHeaderView.contentView.addSubview(closeButton)
    }
    
    func configureTorchButton() {
        torchButton.frame = CGRect(x: 17.5, y: 17.5, width: 35, height: 35)
        torchButton.setImage(UIImage(named: "strobe.png"), for: .normal)
        addShadow(view: torchButton)
    }
    
    func configureUploadButton() {
        uploadButton.frame = CGRect(x: 17.5, y: 17.5, width: 35, height: 35)
        uploadButton.showsTouchWhenHighlighted = true
        uploadButton.setImage(UIImage(named: "images.png"), for: .normal)
        addShadow(view: uploadButton)
    }
    
    func addShadow(view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        view.layer.shadowRadius = 1.5
        view.layer.shadowOpacity = 0.5
    }
    
    func configureImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
    }
    
    func configureDownSwipe() {
        downSwipe.direction = .down
        downSwipe.addTarget(self, action: #selector(handleSwipes(_:)))
        imageView.addGestureRecognizer(downSwipe)
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
                
            } catch {
                print("Torch could not be used")
            }
            
        } else {
            print("Torch is not available")
        }
    }
    
    func scanQRNow() {
            
        guard let avCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
            
        guard let avCaptureInput = try? AVCaptureDeviceInput(device: avCaptureDevice) else { return }
            
        let avCaptureMetadataOutput = AVCaptureMetadataOutput()
        avCaptureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
        if let inputs = avCaptureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                avCaptureSession.removeInput(input)
            }
        }
            
        if let outputs = avCaptureSession.outputs as? [AVCaptureMetadataOutput] {
            for output in outputs {
                avCaptureSession.removeOutput(output)
            }
        }
            
        avCaptureSession.addInput(avCaptureInput)
        avCaptureSession.addOutput(avCaptureMetadataOutput)
        avCaptureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        let avCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avCaptureSession)
        avCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        avCaptureVideoPreviewLayer.frame = self.imageView.bounds
        self.imageView.layer.addSublayer(avCaptureVideoPreviewLayer)
        avCaptureSession.startRunning()
            
    }
    
    func configure() {
        
        backgroundView.alpha = 0
        progressView.alpha = 0
        progressDescriptionLabel.alpha = 0
        
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = 8
        
        addTestingNodeButton.addTarget(self, action: #selector(addTester), for: .touchUpInside)
        torchButton.addTarget(self, action: #selector(toggleTorchNow), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(chooseQRCodeFromLibrary), for: .touchUpInside)
        
        isTorchOn = false
        
        #if targetEnvironment(macCatalyst)
        
        if isScanningNode {
            addTester()
        } else {
            configureImagePicker()
            chooseQRCodeFromLibrary()
        }
        
        #else
        
        configureImagePicker()
        configureUploadButton()
        configureTorchButton()
        configureDownSwipe()
        
        if isRecovering {
            label.text = "Scan an Account Map"
            labelDetail.text = "Gordian Wallet allows you to backup/export an Account Map QR code for each wallet you create. You can scan one at anytime to recreate the wallet as watch-only, you can then add signers to it."
            addTestingNodeButton.setTitle("more info please", for: .normal)
            configureLabel()
            configureDetailLabel()
            configureDontHaveAnodeButton()
        
        } else if isScanningInvoice {
            label.text = "Scan a Bitcoin address or invoice"
            labelDetail.text = "Gordian Wallet is compatible with BIP21 invoices"
            addTestingNodeButton.setTitle("", for: .normal)
            configureLabel()
            configureDetailLabel()
        
        } else if scanningShards {
            label.text = "Scan SSKR UR"
            labelDetail.text = "Gordian Wallet allows you to scan UR SSKR shards to add a signer to your account."
            addTestingNodeButton.setTitle("", for: .normal)
            configureLabel()
            configureDetailLabel()
            configureDontHaveAnodeButton()
            
        } else if isUpdatingNode {
            label.text = "Scan a QuickConnect QR Code"
            labelDetail.text = "This node will be updated with the credentials contained within the scanned QR"
            addTestingNodeButton.setTitle("", for: .normal)
            configureLabel()
            configureDetailLabel()
            
        } else if isScanningNode {
            label.text = "Scan a QuickConnect QR Code"
            labelDetail.text = "Compatible with Bitcoin Core 0.19.0, BTCPayServer, Nodl, Raspiblitz, and StandUp"
            addTestingNodeButton.setTitle("don't have a node? tap to add a tester", for: .normal)
            configureLabel()
            configureDetailLabel()
            configureDontHaveAnodeButton()
            
        } else if isImporting {
            label.text = "Import an Account"
            labelDetail.text = "You may scan an \"Account Map\", Bitcoin Core Descriptor, Specter \"Wallet Import\" QR, Coldcard skeleton json, crypto-seed UR or crypto-hdkey (master key only) UR"
            configureLabel()
            configureDetailLabel()
            configureDontHaveAnodeButton()
            
        } else if scanningRecovery {
            label.text = "Scan an Account Map"
            labelDetail.text = "Gordian Wallet allows you to backup/export an Account Map QR code for each wallet you create. You can scan one at anytime to recreate the wallet as watch-only, you can then add signers to it."
            addTestingNodeButton.setTitle("more info please", for: .normal)
            configureLabel()
            configureDetailLabel()
            configureDontHaveAnodeButton()
            
        } else if verifying {
            label.text = "Scan an Address to Verify"
            labelDetail.text = "If you want to be certain the address you are receiving to is the one you expect you can scan it with this tool to ensure they match."
            configureLabel()
            configureDetailLabel()
            
        } else if scanningBip21 {
            label.text = "Scan an Address or BIP21 Invoice"
            labelDetail.text = "You can scan a Bitcoin address or a BIP21 invoice."
            configureLabel()
            configureDetailLabel()
            
        } else {
            label.text = "Scan a QR Code"
            labelDetail.text = "You can scan a QuickConnect QR to add a node, or a PSBT to sign"
            configureLabel()
            configureDetailLabel()
        }
        
        configureCloseButton()
        
        #endif
    }
    
    func removeScanner() {
        DispatchQueue.main.async {
            //self.imageView.layer.sublayers = nil
            self.stopScanner()
            self.torchButton.removeFromSuperview()
            self.uploadButton.removeFromSuperview()
            self.imageView.removeFromSuperview()
        }
    }
    
    func stopScanner() {
        DispatchQueue.main.async {
            self.avCaptureSession.stopRunning()
        }
    }
    
    func startScanner() {
        DispatchQueue.main.async {
            self.avCaptureSession.startRunning()
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0,
            let machineReadableCode = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
            machineReadableCode.type == AVMetadataObject.ObjectType.qr else {
                return
        }
        
        let stringURL = machineReadableCode.stringValue!
        
        DispatchQueue.main.async {
            self.avCaptureSession.stopRunning()
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            AudioServicesPlaySystemSound(1103)
        }
        
        self.processQRString(url: stringURL)
        
        if keepRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.avCaptureSession.startRunning()
            }
        }
    }
}

extension ScannerViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        guard let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else { return }
        
        guard let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]) else { return }
        
        guard let ciImage:CIImage = CIImage(image:pickedImage) else { return }
        
        var qrCodeLink = ""
        
        guard let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else { return }
        
        for feature in features {
            guard let string = feature.messageString else { return }
            
            qrCodeLink += string
        }
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        picker.dismiss(animated: true, completion: {
            self.processQRString(url: qrCodeLink)
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
