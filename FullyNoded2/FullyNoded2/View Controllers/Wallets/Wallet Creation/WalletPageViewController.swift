//
//  WalletPageViewController.swift
//  FullyNoded2
//
//  Created by Peter on 14/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class WalletPageViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    var mnemonic = ""
    var isAddingLabel = Bool()
    let saveLabelButton = UIButton()
    let tap = UITapGestureRecognizer()
    let logoView = UIImageView()
    let labelInput = UITextField()
    let savedButton = UIButton()
    let qrGenerator = QRGenerator()
    var titleLabel = UILabel()
    var textView = UITextView()
    var imageView = UIImageView()
    var wordView = UITextView()
    var qrView = UIImageView()
    var page: WalletPages
    var tapQRGesture = UITapGestureRecognizer()
    var tapTextViewGesture = UITapGestureRecognizer()
    
    init(with page: WalletPages) {
        
        self.page = page
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        textView.delegate = self
        labelInput.delegate = self
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        
        addLogo()
        addImageView()
        addTitleLabel()
        addTextView()
        
        switch page.index {
            
        case 0:
            addLabelInput()
            addSaveLabelButton()
            
        case 1:
            addQr()
            
        case 2:
            addWordView()
            addButton()
            
        default:
            break
            
        }

    }
    
    @objc func handleTap() {
        
        DispatchQueue.main.async {
            
            self.labelInput.resignFirstResponder()
            
        }
        
    }
    
    private func addQr() {
        
        qrView.frame = CGRect(x: 75, y: textView.frame.maxY, width: self.view.frame.width - 150, height: self.view.frame.width - 150)
        qrGenerator.textInput = page.recoveryItem
        qrView.image = qrGenerator.getQRCode()
        qrView.isUserInteractionEnabled = true
        view.addSubview(qrView)
        
        tapQRGesture = UITapGestureRecognizer(target: self,
                                              action: #selector(shareQRCode(_:)))
        
        qrView.addGestureRecognizer(tapQRGesture)
        
    }
    
    private func addImageView() {
        
        imageView.frame = CGRect(x: 16, y: logoView.frame.maxY + 5, width: 30, height: 30)
        imageView.image = page.image
        
        if page.index == 0 {
            
            imageView.tintColor = .systemGreen
            
        } else if page.index == 2 {
            
            imageView.tintColor = .systemTeal
            
        } else {
            
            imageView.tintColor = .white
            
        }
        
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
    }
    
    private func addLogo() {
        
        logoView.image = UIImage(imageLiteralResourceName: "1024.png")
        logoView.frame = CGRect(x: view.frame.midX - 25, y: 30, width: 40, height: 40)
        logoView.contentMode = .scaleAspectFit
        view.addSubview(logoView)
        
    }
    
    private func addTitleLabel() {
        
        titleLabel.frame = CGRect(x: imageView.frame.maxX + 5, y: imageView.frame.origin.y, width: (view.frame.width - 16) - (imageView.frame.width + 5), height: 30)
        titleLabel.textAlignment = NSTextAlignment.left
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 23, weight: .heavy)
        titleLabel.text = page.title
        titleLabel.textColor = .lightGray
        titleLabel.sizeToFit()
        view.addSubview(titleLabel)
        
    }
    
    private func addTextView() {
        
        textView.frame = CGRect(x: 16, y: titleLabel.frame.maxY + 5, width: view.frame.width - 32, height: view.frame.height - 350)
        
        if page.isMulti {
            
            textView.text = page.multiSigBody
            
        } else {
            
            textView.text = page.singleSigBody
            
        }
        
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = true
        textView.textAlignment = .left
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 13)
        textView.isEditable = false
        textView.sizeToFit()
        view.addSubview(textView)
        
    }
    
    private func addLabelInput() {
        
        labelInput.frame = CGRect(x: 32, y: textView.frame.maxY + 5, width: view.frame.width - 64, height: 70)
        labelInput.clipsToBounds = true
        labelInput.layer.cornerRadius = 8
        labelInput.backgroundColor = .lightGray//#colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
        labelInput.tintColor = .black
        labelInput.textColor = .black
        labelInput.attributedPlaceholder = NSAttributedString(string: " add wallet label here", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        labelInput.keyboardAppearance = .dark
        view.addSubview(labelInput)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    private func addSaveLabelButton() {
        
        saveLabelButton.frame = CGRect(x: 64, y: labelInput.frame.maxY + 5, width: view.frame.width - 128, height: 50)
        saveLabelButton.clipsToBounds = true
        saveLabelButton.layer.cornerRadius = 8
        saveLabelButton.setTitle("save label", for: .normal)
        saveLabelButton.backgroundColor = .darkGray
        saveLabelButton.setTitleColor(.systemTeal, for: .normal)
        saveLabelButton.addTarget(self, action: #selector(saveLabel), for: .touchUpInside)
        view.addSubview(saveLabelButton)
        
    }
    
    private func addWordView() {
        
        mnemonic = ""
        wordView.frame = CGRect(x: 32, y: textView.frame.maxY + 5, width: self.view.frame.width - 64, height: 100)
        wordView.isSelectable = false
        wordView.isEditable = false
        wordView.textColor = .systemTeal
        wordView.font = .systemFont(ofSize: 15, weight: .bold)
        let wordArray = page.recoveryItem.split(separator: " ")
        
        if !page.isMulti {
        
            mnemonic = "Derivation: \(page.derivationScheme + "/0")\n\n"
            
        }
        
        for (i, word) in wordArray.enumerated() {
            
            mnemonic += "\(i + 1). \(word)     "
            
        }
        
        wordView.text = mnemonic
        wordView.sizeToFit()
        view.addSubview(wordView)
        
        tapTextViewGesture = UITapGestureRecognizer(target: self,
                                                    action: #selector(shareRawText(_:)))
        
        wordView.addGestureRecognizer(tapTextViewGesture)
        
    }
    
    private func addButton() {
        
        savedButton.frame = CGRect(x: 32, y: wordView.frame.maxY + 5, width: view.frame.width - 64, height: 50)
        savedButton.clipsToBounds = true
        savedButton.layer.cornerRadius = 8
        savedButton.setTitle("I saved the QR and words", for: .normal)
        savedButton.titleLabel?.adjustsFontSizeToFitWidth = true
        savedButton.backgroundColor = .darkGray
        savedButton.setTitleColor(.systemGreen, for: .normal)
        savedButton.addTarget(self, action: #selector(accept), for: .touchUpInside)
        view.addSubview(savedButton)
        
    }
    
    private func impact() {
        
        DispatchQueue.main.async {
            
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            
        }
        
    }
    
    @objc func accept() {
        
        impact()
        
        DispatchQueue.main.async {
            
            self.savedButton.removeFromSuperview()
            self.wordView.removeFromSuperview()
            
            var message = ""
            
            if self.page.isMulti {
                
                message = "Once you tap \"Yes, I saved them\" the backup words will be gone forever! If you tap \"Oops, I forgot\" we will show them to you again so you may save them."
                
            } else {
                
                message = ""
                
            }
            
            let alert = UIAlertController(title: "Are you sure you saved the recovery items?", message: message, preferredStyle: .actionSheet)
            
            alert.view.superview?.subviews[0].isUserInteractionEnabled = false

            alert.addAction(UIAlertAction(title: "Yes, I saved them", style: .default, handler: { action in
                                
                DispatchQueue.main.async {
                    
                    self.dismiss(animated: true) {
                        
                        self.page.doneBlock!(true)
                        
                    }
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Oops, I forgot", style: .default, handler: { action in
                                
                DispatchQueue.main.async {
                    
                    self.addWordView()
                    self.addButton()
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                                
                DispatchQueue.main.async {
                    
                    self.addWordView()
                    self.addButton()
                    
                }
                
            }))
            
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.text != "" {
            
            saveLabel()
            
        }
        
        textField.resignFirstResponder()
        
        isAddingLabel = false
        
        return true
        
    }
    
    @objc func saveLabel() {
        
        if labelInput.text != "" {
            
            let cd = CoreDataService()
            cd.updateEntity(id: page.walletId, keyToUpdate: "label", newValue: labelInput.text!, entityName: .wallets) {
                
                if !cd.errorBool {
                    
                    showAlert(vc: self, title: "Wallet Label Saved", message: "Your wallet label has been updated!\n\nSwipe the screen to the left to go to the next step.")
                    
                } else {
                    
                    showAlert(vc: self, title: "Error", message: "Error saving wallet label: \(cd.errorDescription)")
                    
                }
                
            }
            
        } else {
            
            shakeAlert(viewToShake: labelInput)
            
        }
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        isAddingLabel = true
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        
        if isAddingLabel {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardSize.height
                }
            }
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        
        if isAddingLabel {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
        
    }
    
    @objc func shareRawText(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.wordView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.wordView.alpha = 1
                    
                })
                
            }
                            
            let textToShare = [self.mnemonic]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.qrView.alpha = 0
                
            }) { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.qrView.alpha = 1
                    
                })
                
            }
            
            let objectsToShare = [self.qrView.image!]
            
            let activityController = UIActivityViewController(activityItems: objectsToShare,
                                                              applicationActivities: nil)
            
            activityController.popoverPresentationController?.sourceView = self.view
            self.present(activityController, animated: true) {}
            
        }
        
    }

}

