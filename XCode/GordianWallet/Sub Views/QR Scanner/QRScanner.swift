//
//  QRScanner.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class QRScanner: UIView, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    var imageView = UIImageView()
    var stringToReturn = ""
    var completion = {}
    var didChooseImage = {}
    var keepRunning = Bool()
    var downSwipeAction = {}
    var vc = UIViewController()
    let imagePicker = UIImagePickerController()
    var qrString = ""
    let textField = UITextField()
    var textFieldPlaceholder = ""
    let uploadButton = UIButton()
    let torchButton = UIButton()
    let closeButton = UIButton()
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemChromeMaterialDark))
    let downSwipe = UISwipeGestureRecognizer()
    
    func configureDontHaveAnodeButton() {
        
        addTestingNodeButton.frame = CGRect(x: 20, y: self.labelDetail.frame.maxY + 5, width: self.blurView.frame.width - 40, height: 20)
        addTestingNodeButton.setTitleColor(.systemTeal, for: .normal)
        addTestingNodeButton.titleLabel?.font = .systemFont(ofSize: 10)
        addTestingNodeButton.backgroundColor = .clear
        blurView.contentView.addSubview(addTestingNodeButton)
        
    }
    
    func configureDetailLabel() {
        
        labelDetail.font = .systemFont(ofSize: 12, weight: .bold)
        labelDetail.numberOfLines = 0
        labelDetail.frame = CGRect(x: 20, y: self.label.frame.maxY + 5, width: self.blurView.frame.width - 40, height: 50)
        labelDetail.textColor = .systemGray
        labelDetail.clipsToBounds = true
        labelDetail.layer.cornerRadius = 8
        labelDetail.backgroundColor = .clear
        labelDetail.sizeToFit()
        blurView.contentView.addSubview(labelDetail)
        blurView.frame = CGRect(x: 16, y: 10, width: self.imageView.frame.width - 32, height: self.label.frame.height + self.labelDetail.frame.height + 55)
        
    }
    
    func configureLabel() {
        
        blurView.frame = CGRect(x: 16, y: 10, width: self.imageView.frame.width - 32, height: 150)
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 10
        imageView.addSubview(blurView)
        label.font = .systemFont(ofSize: 28, weight: .heavy)
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.textColor = .white
        label.frame = CGRect(x: 16, y: 10, width: self.blurView.frame.width - 32, height: 50)
        label.sizeToFit()
        blurView.contentView.addSubview(label)
    }
    
    @objc func handleSwipes(_ sender: UIGestureRecognizer) {
        print("handleswipes")
     
        downSwipeAction()
        
    }
    
    func configureCloseButton() {
    
        closeButton.frame = CGRect(x: blurView.contentView.frame.maxX - 32,
                                   y: 5,
                                   width: 20,
                                   height: 20)
        
        closeButton.setImage(UIImage(systemName: "x.circle.fill"), for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        blurView.contentView.addSubview(closeButton)
        
    }
    
    @objc func close() {
        
        DispatchQueue.main.async {
            
            self.vc.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    func configureTorchButton() {
        
        torchButton.frame = CGRect(x: 35 / 2,
                                   y: 35 / 2,
                                   width: 35,
                                   height: 35)
        
        torchButton.setImage(UIImage(named: "strobe.png"), for: .normal)
        addShadow(view: torchButton)
    }
    
    func configureUploadButton() {
        
        uploadButton.frame = CGRect(x: 35 / 2,
                                    y: 35 / 2,
                                    width: 35,
                                    height: 35)
        
        uploadButton.showsTouchWhenHighlighted = true
        uploadButton.setImage(UIImage(named: "images.png"), for: .normal)
        addShadow(view: uploadButton)
        
    }
    
    func addShadow(view: UIView) {
        
        view.layer.shadowColor = UIColor.black.cgColor
        
        view.layer.shadowOffset = CGSize(width: 1.5,
                                         height: 1.5)
        
        view.layer.shadowRadius = 1.5
        view.layer.shadowOpacity = 0.5
        
    }
    
    func configureTextField() {
        
        let width = vc.view.frame.width - 20
        
        textField.frame = CGRect(x: 0,
                                 y: 0,
                                 width: width,
                                 height: 50)
        
        textField.layer.cornerRadius = 12
        textField.textAlignment = .center
        textField.clipsToBounds = true
        addShadow(view: textField)
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textColor = UIColor.white
        textField.keyboardAppearance = UIKeyboardAppearance.dark
        textField.backgroundColor = UIColor.clear
        textField.returnKeyType = UIReturnKeyType.go
        textField.attributedPlaceholder = NSAttributedString(string: textFieldPlaceholder,
                                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
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
        
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)
            else {return}
        
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
    
    func scanQRCode() {
            
        func scanQRNow() throws {
                
            guard let avCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
                    
                print("no camera")
                throw error.noCameraAvailable
                    
            }
                
            guard let avCaptureInput = try? AVCaptureDeviceInput(device: avCaptureDevice) else {
                    
                print("failed to int camera")
                throw error.videoInputInitFail
                    
            }
                
            let avCaptureMetadataOutput = AVCaptureMetadataOutput()
            avCaptureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
            if let inputs = self.avCaptureSession.inputs as? [AVCaptureDeviceInput] {
                for input in inputs {
                    self.avCaptureSession.removeInput(input)
                }
            }
                
            if let outputs = self.avCaptureSession.outputs as? [AVCaptureMetadataOutput] {
                for output in outputs {
                    self.avCaptureSession.removeOutput(output)
                }
            }
                
            self.avCaptureSession.addInput(avCaptureInput)
            self.avCaptureSession.addOutput(avCaptureMetadataOutput)
            avCaptureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            let avCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avCaptureSession)
            avCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            avCaptureVideoPreviewLayer.frame = self.imageView.bounds
            self.imageView.layer.addSublayer(avCaptureVideoPreviewLayer)
            self.avCaptureSession.startRunning()
                
        }
            
        enum error: Error {
                
            case noCameraAvailable
            case videoInputInitFail
                
        }
            
        do {
                
            try scanQRNow()
            print("scanQRNow")
                
        } catch {
                
            print("Failed to scan QR Code")
            
        }
        
        #if targetEnvironment(macCatalyst)
            configureImagePicker()
            chooseQRCodeFromLibrary()
        
        #else
            configureImagePicker()
            configureTextField()
            configureUploadButton()
            configureTorchButton()
            configureDownSwipe()
        
            if scanningShards {
                label.text = "Scan SSKR UR"
                labelDetail.text = "Gordian Wallet allows you to scan UR SSKR shards to add a signer to your account."
                addTestingNodeButton.setTitle("more info please", for: .normal)
                configureLabel()
                configureDetailLabel()
                configureDontHaveAnodeButton()
                closeButton.alpha = 0
                
            
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
                closeButton.alpha = 0
                configureDontHaveAnodeButton()
                
            } else if scanningRecovery {
                
                label.text = "Scan an Account Map"
                labelDetail.text = "Gordian Wallet allows you to backup/export an Account Map QR code for each wallet you create. You can scan one at anytime to recreate the wallet as watch-only, you can then add signers to it."
                addTestingNodeButton.setTitle("more info please", for: .normal)
                configureLabel()
                configureDetailLabel()
                configureDontHaveAnodeButton()
                closeButton.alpha = 0
                
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
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects.count > 0 {
            
            let machineReadableCode = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if machineReadableCode.type == AVMetadataObject.ObjectType.qr {
                
                let stringURL = machineReadableCode.stringValue!
                self.stringToReturn = stringURL
                self.avCaptureSession.stopRunning()
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                completion()
                
                if keepRunning {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        
                        self.avCaptureSession.startRunning()
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.vc.dismiss(animated: true, completion: nil)
        }
    }
    
    func chooseQRCodeFromLibrary() {
        vc.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        if let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            
            let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
            let ciImage:CIImage = CIImage(image:pickedImage)!
            var qrCodeLink = ""
            let features = detector.features(in: ciImage)
            
            for feature in features as! [CIQRCodeFeature] {
                qrCodeLink += feature.messageString!
            }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            picker.dismiss(animated: true, completion: {
                
                self.qrString = qrCodeLink
                self.didChooseImage()
                
            })
            
        }
        
    }
    
    func removeScanner() {
        
        DispatchQueue.main.async {
            
            self.textField.removeFromSuperview()
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
