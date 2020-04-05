//
//  WalletRecoverViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class WalletRecoverViewController: UIViewController, UITextFieldDelegate {
    
    var derivation = ""
    var qrValid = false
    var recoveryDict = [String:Any]()
    var addedWords = [String]()
    var justWords = [String]()
    var bip39Words = [String]()
    var onDoneBlock: ((Bool) -> Void)?
    let label = UILabel()
    let tap = UITapGestureRecognizer()
    var autoCompleteCharacterCount = 0
    var timer = Timer()
    @IBOutlet var textField: UITextField!
    @IBOutlet var scanButton: UIButton!
    @IBOutlet var wordsView: UIView!
    @IBOutlet var recoverNowOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recoverNowOutlet.alpha = 0
        textField.delegate = self
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        scanButton.layer.cornerRadius = 8
        recoverNowOutlet.layer.cornerRadius = 8
        wordsView.layer.cornerRadius = 8
        let wordList = Bip39Words()
        bip39Words = wordList.validWords
        
       textField.attributedPlaceholder = NSAttributedString(string: "recovery words",
                                                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "showInfo", sender: self)
            
        }
        
    }
    
    @IBAction func recoverNow(_ sender: Any) {
        
        weak var enc = Encryption.sharedInstance
        enc?.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                if vc.qrValid {
                    
                    vc.confirm()
                    
                } else {
                    
                    DispatchQueue.main.async {
                        
                        let network = node!.network
                        var chain = ""
                        
                        let alert = UIAlertController(title: "Choose a derivation", message: "When only using words to recover you need to let us know which derivation scheme you want to utilize, if you are not sure you can recover the wallet three times, once for each derivation.", preferredStyle: .actionSheet)
                        
                        switch network {
                        case "testnet":
                            chain = "1'"
                        case "mainnet":
                            chain = "0'"
                        default:
                            break
                        }
                                                
                        alert.addAction(UIAlertAction(title: "Segwit - BIP84 - m/84'/\(chain)/0'/0", style: .default, handler: { action in
                            
                            switch network {
                            case "testnet":
                                vc.derivation = "m/84'/1'/0'"
                            case "mainnet":
                                vc.derivation = "m/84'/0'/0'"
                            default:
                                break
                            }
                            
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.confirm()
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Legacy - BIP44 - m/44'/\(chain)/0'/0", style: .default, handler: { action in
                            
                            switch network {
                            case "testnet":
                                vc.derivation = "m/44'/1'/0'"
                            case "mainnet":
                                vc.derivation = "m/44'/0'/0'"
                            default:
                                break
                            }
                            
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.confirm()
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Nested Segwit - BIP49 - m/49'/\(chain)/0'/0", style: .default, handler: { action in
                            
                            switch network {
                            case "testnet":
                                vc.derivation = "m/49'/1'/0'"
                            case "mainnet":
                                vc.derivation = "m/49'/0'/0'"
                            default:
                                break
                            }
                            
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.confirm()
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        
                        alert.popoverPresentationController?.sourceView = vc.view
                        vc.present(alert, animated: true, completion: nil)
                        
                    }
                    
                }
                
            } else {
                
                displayAlert(viewController: vc, isError: true, message: "No active node, please connect to a node and activate it first")
                
            }
            
        }
        
    }
    
    @objc func handleTap() {
        
        DispatchQueue.main.async {
            
            self.textField.resignFirstResponder()
            
        }
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
        
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func scanAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "scanRecovery", sender: self)
            
        }
        
    }
    
    func processTextfieldInput() {
        
        if textField.text != "" {
            
            //check if user pasted more then one word
            let processed = processedCharacters(textField.text!)
            let userAddedWords = (processed).split(separator: " ")
            
            if userAddedWords.count > 1 {
                
                //user add multiple words
                for (i, word) in userAddedWords.enumerated() {
                    
                    var isValid = false
                    
                    for bip39Word in bip39Words {
                        
                        if word == bip39Word {
                            
                            isValid = true
                            
                        }
                        
                    }
                    
                    if i + 1 == userAddedWords.count {
                        
                        // we finished our checks
                        if isValid {
                            
                            // they are valid bip39 words
                            for word in userAddedWords {
                                
                                addWord(word: "\(word)")
                                
                            }
                            
                            textField.text = ""
                            
                        } else {
                            
                            //they are not all valid bip39 words
                            textField.text = ""
                            
                            showAlert(vc: self, title: "Error", message: "At least one of those words is not a valid BIP39 word. We suggest inputting them one at a time so you can utilize our autosuggest feature which will prevent typos.")
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                //its one word
                let processedWord = textField.text!.replacingOccurrences(of: " ", with: "")
                
                for word in bip39Words {
                    
                    if processedWord == word {
                        
                        addWord(word: processedWord)
                        textField.text = ""
                        
                    }
                    
                }
                
            }
            
        } else {
            
            shakeAlert(viewToShake: textField)
            
        }
    }
    
    @IBAction func addWord(_ sender: Any) {
        
        processTextfieldInput()
        
    }
    
    @IBAction func removeWord(_ sender: Any) {
        
        if self.justWords.count > 0 {
            
            DispatchQueue.main.async {
                
                self.label.removeFromSuperview()
                self.label.text = ""
                self.addedWords.removeAll()
                self.justWords.remove(at: self.justWords.count - 1)
                
                for (i, word) in self.justWords.enumerated() {
                    
                    self.addedWords.append("\(i + 1). \(word) ")
                    
                }
                
                self.label.textColor = .systemGreen
                self.label.text = self.addedWords.joined(separator: " ")
                self.label.frame = CGRect(x: 16, y: 0, width: self.wordsView.frame.width - 32, height: self.wordsView.frame.height - 10)
                self.label.numberOfLines = 0
                self.label.sizeToFit()
                self.wordsView.addSubview(self.label)
                
                if self.justWords.count == 12 || self.justWords.count == 24 {
                    
                    self.recoverNowOutlet.alpha = 1
                    self.validWordsAdded()
                    
                } else {
                    
                    self.recoverNowOutlet.alpha = 0
                    
                }
                
            }
            
        }
        
    }
    
    func validRecoveryScanned() {
        
        DispatchQueue.main.async {
            
            self.qrValid = true
            self.recoverNowOutlet.alpha = 1
            self.scanButton.setTitle("  RecoveryQR is Valid", for: .normal)
            self.scanButton.setTitleColor(.systemGreen, for: .normal)
            self.scanButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
            self.scanButton.tintColor = .systemGreen
            self.scanButton.isEnabled = false
            
        }
        
    }
    
    private func formatSubstring(subString: String) -> String {
        
        let formatted = String(subString.dropLast(autoCompleteCharacterCount)).lowercased()
        return formatted
        
    }
    
    private func resetValues() {
        
        textField.textColor = .white
        autoCompleteCharacterCount = 0
        textField.text = ""
        
    }
    
    func searchAutocompleteEntriesWIthSubstring(substring: String) {
        
        let userQuery = substring
        let suggestions = getAutocompleteSuggestions(userText: substring)
        self.textField.textColor = .white
        
        if suggestions.count > 0 {
            
            timer = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { (timer) in
                
                let autocompleteResult = self.formatAutocompleteResult(substring: substring, possibleMatches: suggestions)
                self.putColorFormattedTextInTextField(autocompleteResult: autocompleteResult, userQuery : userQuery)
                self.moveCaretToEndOfUserQueryPosition(userQuery: userQuery)
                
            })
            
        } else {
            
            timer = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { [unowned vc = self] (timer) in //7
                
                vc.textField.text = substring
                
                if let _ = BIP39Mnemonic(vc.processedCharacters(vc.textField.text!)) {
                    
                    vc.textField.textColor = .systemGreen
                    vc.validWordsAdded()
                    
                } else {
                    
                    vc.textField.textColor = .systemRed
                    
                }
                
                
            })
            
            autoCompleteCharacterCount = 0
            
        }
        
    }
    
    private func validWordsAdded() {
        
        DispatchQueue.main.async {
            
            self.textField.resignFirstResponder()
            
            showAlert(vc: self, title: "Valid mnemonic", message: "Thats a valid recovery phrase, you can now tap \"Tap to recover\" to recover with just words.")
            
        }
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var subString = (textField.text!.capitalized as NSString).replacingCharacters(in: range, with: string)
        subString = formatSubstring(subString: subString)
        
        if subString.count == 0 {
            
            resetValues()
            
        } else {
            
            searchAutocompleteEntriesWIthSubstring(substring: subString)
            
        }
        
        return true
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        processTextfieldInput()
        
        return true
        
    }
    
    func getAutocompleteSuggestions(userText: String) -> [String]{
        
        var possibleMatches: [String] = []
        
        for item in bip39Words {
            
            let myString:NSString! = item as NSString
            let substringRange:NSRange! = myString.range(of: userText)
            
            if (substringRange.location == 0) {
                
                possibleMatches.append(item)
                
            }
            
        }
        
        return possibleMatches
        
    }
    
    func putColorFormattedTextInTextField(autocompleteResult: String, userQuery : String) {
        
        let coloredString: NSMutableAttributedString = NSMutableAttributedString(string: userQuery + autocompleteResult)
        
        coloredString.addAttribute(NSAttributedString.Key.foregroundColor,
                                   value: UIColor.systemGreen,
                                   range: NSRange(location: userQuery.count,length:autocompleteResult.count))
        
        self.textField.attributedText = coloredString
        
    }
    
    func moveCaretToEndOfUserQueryPosition(userQuery : String) {
        
        if let newPosition = self.textField.position(from: self.textField.beginningOfDocument, offset: userQuery.count) {
            
            self.textField.selectedTextRange = self.textField.textRange(from: newPosition, to: newPosition)
            
        }
        
        let selectedRange: UITextRange? = textField.selectedTextRange
        textField.offset(from: textField.beginningOfDocument, to: (selectedRange?.start)!)
        
    }
    
    func formatAutocompleteResult(substring: String, possibleMatches: [String]) -> String {
        
        var autoCompleteResult = possibleMatches[0]
        autoCompleteResult.removeSubrange(autoCompleteResult.startIndex..<autoCompleteResult.index(autoCompleteResult.startIndex, offsetBy: substring.count))
        autoCompleteCharacterCount = autoCompleteResult.count
        return autoCompleteResult
        
    }
    
    private func addWord(word: String) {
        
        DispatchQueue.main.async {
            
            self.label.removeFromSuperview()
            self.label.text = ""
            self.addedWords.removeAll()
            self.justWords.append(word)
            
            for (i, word) in self.justWords.enumerated() {
                
                self.addedWords.append("\(i + 1). \(word) ")
                
            }
            
            self.label.textColor = .systemGreen
            self.label.text = self.addedWords.joined(separator: " ")
            self.label.frame = CGRect(x: 16, y: 0, width: self.wordsView.frame.width - 32, height: self.wordsView.frame.height - 10)
            self.label.numberOfLines = 0
            self.label.sizeToFit()
            self.wordsView.addSubview(self.label)
            
            if self.justWords.count == 12 || self.justWords.count == 24 {
                
                self.recoverNowOutlet.alpha = 1
                self.validWordsAdded()
                
            } else {
                
                self.recoverNowOutlet.alpha = 0
                
            }
            
        }
        
    }
    
    @IBAction func moreinfo(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "showInfo", sender: self)
            
        }
        
    }
    
    private func confirm() {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "goConfirm", sender: self)
            
        }
        
    }
    
    private func recover(dict: [String:Any]) {
        
        DispatchQueue.main.async {
            
            self.textField.resignFirstResponder()
            
        }
        
        let connectingView = ConnectingView()
        connectingView.addConnectingView(vc: self, description: "recovering your wallet")
        let recovery = RecoverWallet()
        
        let enc = Encryption.sharedInstance
        enc.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                recovery.node = node!
                
                if vc.justWords.count == 12 || vc.justWords.count == 24 {
                    
                    recovery.words = vc.justWords.joined(separator: " ")
                    
                }
                
                if dict["descriptor"] != nil {
                    
                    recovery.json = dict
                    
                } else {
                    
                    recovery.derivation = vc.derivation
                    
                }
                
                recovery.recover { (success, error) in
                    
                    if success {
                        
                        connectingView.removeConnectingView()
                        
                        DispatchQueue.main.async {
                            
                            vc.dismiss(animated: true) {
                                
                                vc.onDoneBlock!(true)
                                
                            }
                            
                        }
                        
                    } else {
                        
                        connectingView.removeConnectingView()
                        
                        if error != nil {
                            
                            showAlert(vc: vc, title: "Error!", message: "Wallet recovery error: \(error!)")
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                connectingView.removeConnectingView()
                
                showAlert(vc: vc, title: "Error!", message: "Recovering wallets requires an active node!")
                
            }
            
        }
        
    }
    
    private func processedCharacters(_ string: String) -> String {
        
        var result = string.filter("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ".contains)
        result = result.condenseWhitespace()
        return result
        
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "goConfirm":
            
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                
                if self.justWords.count == 12 || self.justWords.count == 24 {
                    
                    vc.words = self.justWords.joined(separator: " ")
                    
                }
                
                vc.walletDict = self.recoveryDict
                vc.confirmedDoneBlock = { [unowned thisVc = self] result in
                    
                    if result {
                        
                        thisVc.recover(dict: thisVc.recoveryDict)
                        
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            thisVc.dismiss(animated: true, completion: nil)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        case "scanRecovery":
            
            if let vc = segue.destination as? ScannerViewController {
                
                vc.isRecovering = true
                vc.onDoneRecoveringBlock = { [unowned thisVc = self] dict in
                    
                    thisVc.recoveryDict = dict
                    thisVc.validRecoveryScanned()
                    
                    DispatchQueue.main.async {
                        
                        thisVc.recoverNowOutlet.isEnabled = true
                        showAlert(vc: thisVc, title: "Valid Recovery QR", message: "You can now tap \"Tap to recover\"")

                    }
                    
                }
                
            }
            
        default:
            
            break
            
        }
        
    }

}

extension String {
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}