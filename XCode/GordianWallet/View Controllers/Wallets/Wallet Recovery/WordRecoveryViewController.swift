//
//  WordRecoveryViewController.swift
//  FullyNoded2
//
//  Created by Peter on 12/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally

class WordRecoveryViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    var urToRecover = ""
    var seedArray = [String]()/// Used to recover multi-sig wallets with seed words only.
    var recoveringMultiSigWithWordsOnly = Bool()
    let cv = ConnectingView()
    var testingWords = Bool()
    var words:String?
    var walletNameHash = ""
    var derivation:String?
    var recoveryDict = [String:Any]()
    var addedWords = [String]()
    var justWords = [String]()
    var bip39Words = [String]()
    let label = UILabel()
    let tap = UITapGestureRecognizer()
    var autoCompleteCharacterCount = 0
    var timer = Timer()
    var onWordsDoneBlock: ((Bool) -> Void)?
    var onSeedDoneBlock: ((String) -> Void)?
    var addingSeed = Bool()
    var index = 0
    var processedPrimaryDescriptors:[String] = []
    var processedChangeDescriptors:[String] = []
    var derivationFieldEditing = false
    var network:Network!
    
    @IBOutlet weak var derivationField: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var wordView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        derivationField.delegate = self
        textField.delegate = self
        textField.returnKeyType = .done
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        wordView.layer.cornerRadius = 8
        bip39Words = Bip39Words.validWords
        updatePlaceHolder(wordNumber: 1)
        
        if addingSeed {
            navigationItem.title = "Add BIP39 words"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        
        if urToRecover != "" {
            parse(text: urToRecover)
            
        } else if words != "" {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.textField.text = self.words
                self.processTextfieldInput()
            }
            
        }
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        hideKeyboards()
    }
    
    func hideKeyboards() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.derivationField.resignFirstResponder()
            vc.textField.resignFirstResponder()
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
           if derivationFieldEditing {
               if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                   if self.view.frame.origin.y == 0 {
                       self.view.frame.origin.y -= keyboardSize.height
                   }
               }
           }
       }
       
    @objc func keyboardWillHide(notification: NSNotification) {
        if derivationFieldEditing {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    private func updatePlaceHolder(wordNumber: Int) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.textField.attributedPlaceholder = NSAttributedString(string: "add word #\(wordNumber)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
    }
    
    @objc func handleTap() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.textField.resignFirstResponder()
        }
    }
    
    @IBAction func removeWordAction(_ sender: Any) {
        
        if self.justWords.count > 0 {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.label.removeFromSuperview()
                vc.label.text = ""
                vc.addedWords.removeAll()
                vc.justWords.remove(at: vc.justWords.count - 1)
                
                for (i, word) in vc.justWords.enumerated() {
                    
                    vc.addedWords.append("\(i + 1). \(word)\n")
                    if i == 0 {
                        vc.updatePlaceHolder(wordNumber: i + 1)
                    } else {
                        vc.updatePlaceHolder(wordNumber: i + 2)
                    }
                }
                
                vc.label.textColor = .systemGreen
                vc.label.text = vc.addedWords.joined(separator: "")
                vc.label.frame = CGRect(x: 16, y: 0, width: vc.wordView.frame.width - 32, height: vc.wordView.frame.height - 10)
                vc.label.numberOfLines = 0
                vc.label.sizeToFit()
                vc.wordView.addSubview(vc.label)
                
                if vc.justWords.count == 12 || vc.justWords.count == 24 {
                    
                    vc.validWordsAdded()
                    
                }
                
            }
            
        }
        
    }
    
    @IBAction func addWordAction(_ sender: Any) {
        if textField.text != "" {
            parse(text: textField.text!)
        } else {
            if justWords.count == 24 || justWords.count == 12 {
                if let _ = BIP39Mnemonic(justWords.joined(separator: " ")) {
                    validWordsAdded()
                }
            }
        }
    }
    
    private func chooseDerivation() {
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                DispatchQueue.main.async {
                    var chain = ""
                    switch node!.network {
                    case "testnet":
                        chain = "1'"
                        vc.network = .testnet
                    case "mainnet":
                        chain = "0'"
                        vc.network = .mainnet
                    default:
                        break
                    }
                    vc.recoveryDict["nodeId"] = node!.id
                    if vc.derivationField.text == "" {
                        var alertStyle = UIAlertController.Style.actionSheet
                        if (UIDevice.current.userInterfaceIdiom == .pad) {
                          alertStyle = UIAlertController.Style.alert
                        }
                        let alert = UIAlertController(title: "Choose a derivation", message: "When only using words to recover you need to let us know which derivation scheme you want to utilize, if you are not sure you can recover the wallet three times, once for each derivation.", preferredStyle: alertStyle)
                        
                        
                        
                        alert.addAction(UIAlertAction(title: "Segwit - BIP84 - m/84'/\(chain)/0'/0", style: .default, handler: { action in
                            
                            vc.derivation = "m/84'/\(chain)/0'"
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.cv.addConnectingView(vc: self, description: "building your wallets descriptors, this can take a minute..")
                            let (primDescriptors, changeDescriptors) = vc.descriptors()
                            vc.buildPrimDescriptors(primDescriptors, changeDescriptors)
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Legacy - BIP44 - m/44'/\(chain)/0'/0", style: .default, handler: { action in
                            
                            vc.derivation = "m/44'/\(chain)/0'"
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.cv.addConnectingView(vc: self, description: "building your wallets descriptors, this can take a minute..")
                            let (primDescriptors, changeDescriptors) = vc.descriptors()
                            vc.buildPrimDescriptors(primDescriptors, changeDescriptors)
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Nested Segwit - BIP49 - m/49'/\(chain)/0'/0", style: .default, handler: { action in
                            
                            vc.derivation = "m/49'/\(chain)/0'"
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.cv.addConnectingView(vc: self, description: "building your wallets descriptors, this can take a minute..")
                            let (primDescriptors, changeDescriptors) = vc.descriptors()
                            vc.buildPrimDescriptors(primDescriptors, changeDescriptors)
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        alert.popoverPresentationController?.sourceView = vc.view
                        vc.present(alert, animated: true, completion: nil)
                        
                    } else {
                        var alertStyle = UIAlertController.Style.actionSheet
                        if (UIDevice.current.userInterfaceIdiom == .pad) {
                          alertStyle = UIAlertController.Style.alert
                        }
                        
                        let alert = UIAlertController(title: "Choose an address format", message: "When recovering a custom derivation path you need to let us know which address format to utilize.", preferredStyle: alertStyle)
                        
                        alert.addAction(UIAlertAction(title: "Segwit - bc1", style: .default, handler: { action in
                            
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.cv.addConnectingView(vc: self, description: "building your wallets descriptors, this can take a minute..")
                            let (primDescriptors, changeDescriptors) = vc.customDescriptors(prefix: "wpkh")
                            vc.buildPrimDescriptors(primDescriptors, changeDescriptors)
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Legacy - 1", style: .default, handler: { action in
                            
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.cv.addConnectingView(vc: self, description: "building your wallets descriptors, this can take a minute..")
                            let (primDescriptors, changeDescriptors) = vc.customDescriptors(prefix: "pkh")
                            vc.buildPrimDescriptors(primDescriptors, changeDescriptors)
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Nested Segwit - 3", style: .default, handler: { action in
                            
                            vc.recoveryDict["derivation"] = vc.derivation
                            vc.cv.addConnectingView(vc: self, description: "building your wallets descriptors, this can take a minute..")
                            let (primDescriptors, changeDescriptors) = vc.customDescriptors(prefix: "sh(wpkh")
                            vc.buildPrimDescriptors(primDescriptors, changeDescriptors)
                            
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                        
                        alert.popoverPresentationController?.sourceView = vc.view
                        vc.present(alert, animated: true, completion: nil)
                    }                    
                    
                }
                
            }
            
        }
        
    }
    
    private func processTextfieldInput() {
        if textField.text != "" {
            
            //check if user pasted more then one word
            let processed = processedCharacters(textField.text!)
            let userAddedWords = processed.split(separator: " ")
            var multipleWords = [String]()
            
            if userAddedWords.count > 1 {
                
                //user add multiple words
                for (i, word) in userAddedWords.enumerated() {
                    
                    var isValid = false
                    
                    for bip39Word in bip39Words {
                        
                        if word == bip39Word {
                            isValid = true
                            multipleWords.append("\(word)")
                        }
                        
                    }
                    
                    if i + 1 == userAddedWords.count {
                        
                        // we finished our checks
                        if isValid {
                            
                            // they are valid bip39 words
                            addMultipleWords(words: multipleWords)
                            
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
        if !substring.hasPrefix("ur:crypto-seed/") {
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
                        
                        vc.processTextfieldInput()
                        vc.textField.textColor = .systemGreen
                        vc.validWordsAdded()
                        
                    } else {
                        
                        vc.textField.textColor = .systemRed
                        
                    }
                    
                    
                })
                
                autoCompleteCharacterCount = 0
                
            }
        }
    }
    
    private func validWordsAdded() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.textField.resignFirstResponder()
            vc.verify()
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == derivationField {
            derivationFieldEditing = true
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == derivationField {
            derivationFieldEditing = false
            if derivationField.text != "" {
                if derivationField.text!.hasPrefix("m") {
                    if let path = BIP32Path(derivationField.text!) {
                        self.derivation = path.description
                    } else {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.derivationField.text = ""
                        }
                        showAlert(vc: self, title: "Invalid derivation", message: "")
                    }
                } else {
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.derivationField.text = ""
                    }
                    showAlert(vc: self, title: "Invalid derivation", message: "Custom derivation paths needs to start with an m, an example would be: \"m/0'/0'\", if you do not have a good understanding of what this implies then leave the custom derivation field blank to utilize the defaults.")
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField != derivationField {
            var subString = (textField.text!.capitalized as NSString).replacingCharacters(in: range, with: string)
            subString = formatSubstring(subString: subString)
            if subString.count == 0 {
                resetValues()
            } else {
                searchAutocompleteEntriesWIthSubstring(substring: subString)
            }
        }
        return true
    }
    
    private func parse(text: String) {
        if text.hasPrefix("ur:crypto-seed/") {
            if let data = URHelper.urToEntropy(urString: text).data {
                let entropy = BIP39Entropy(data)
                if let mnemonic = BIP39Mnemonic(entropy) {
                    let words = mnemonic.words.joined(separator: " ")
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.textField.text = words
                        vc.processTextfieldInput()
                    }
                }
            }
        } else {
            processTextfieldInput()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == derivationField {
            derivationField.endEditing(true)
        } else {
            if textField.text != "" {
                parse(text: textField.text!)
            }
        }
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
    
    private func addMultipleWords(words: [String]) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.label.removeFromSuperview()
            vc.label.text = ""
            vc.addedWords.removeAll()
            vc.justWords = words
            
            for (i, word) in vc.justWords.enumerated() {
                vc.addedWords.append("\(i + 1). \(word)\n")
                vc.updatePlaceHolder(wordNumber: i + 2)
            }
            
            vc.label.textColor = .systemGreen
            vc.label.text = vc.addedWords.joined(separator: "")
            vc.label.frame = CGRect(x: 16, y: 0, width: vc.wordView.frame.width - 32, height: vc.wordView.frame.height - 10)
            vc.label.numberOfLines = 0
            vc.label.sizeToFit()
            vc.wordView.addSubview(vc.label)
            
            
            if vc.justWords.count == 24 || vc.justWords.count == 12 {
                
                if let _ = BIP39Mnemonic(vc.justWords.joined(separator: " ")) {
                    
                    vc.validWordsAdded()
                    
                } else {
                                        
                    showAlert(vc: vc, title: "Invalid", message: "Just so you know that is not a valid recovery phrase, if you are inputting a 24 word phrase ignore this message and keep adding your words.")
                    
                }
                
            }
            
        }
        
    }
    
    private func addWord(word: String) {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.label.removeFromSuperview()
            vc.label.text = ""
            vc.addedWords.removeAll()
            vc.justWords.append(word)
            
            for (i, word) in vc.justWords.enumerated() {
                
                vc.addedWords.append("\(i + 1). \(word)\n")
                vc.updatePlaceHolder(wordNumber: i + 2)
                
            }
            
            vc.label.textColor = .systemGreen
            vc.label.text = vc.addedWords.joined(separator: "")
            vc.label.frame = CGRect(x: 16, y: 0, width: vc.wordView.frame.width - 32, height: vc.wordView.frame.height - 10)
            vc.label.numberOfLines = 0
            vc.label.sizeToFit()
            vc.wordView.addSubview(vc.label)
            
            
            if vc.justWords.count == 24 || vc.justWords.count == 12 {
                
                if let _ = BIP39Mnemonic(vc.justWords.joined(separator: " ")) {
                    
                    vc.validWordsAdded()
                    
                } else {
                                        
                    showAlert(vc: vc, title: "Invalid", message: "Just so you know that is not a valid recovery phrase, if you are inputting a 24 word phrase ignore this message and keep adding your words.")
                    
                }
                
            }
            
        }
        
    }
    
    private func processedCharacters(_ string: String) -> String {
        var result = string.filter("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ".contains)
        result = result.condenseWhitespace()
        return result
    }
    
    private func confirm() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.label.text = ""
            vc.performSegue(withIdentifier: "confirmFromWords", sender: vc)
        }
    }
    
    private func verify() {
        
        let parser = DescriptorParser()
        words = justWords.joined(separator: " ")
        if let desc = recoveryDict["descriptor"] as? String {
            
            let str = parser.descriptor(desc)
            let backupXpub = str.multiSigKeys[0]
            let derivation = str.derivationArray[0]
            
            MnemonicCreator.convert(words: words!) { [unowned vc = self] (mnemonic, error) in
                
                if !error && mnemonic != nil {
                    
                    let seed = mnemonic!.seedHex()
                    if let mk = HDKey(seed, vc.network) {
                        
                        if let path = BIP32Path(derivation) {
                            
                            do {
                                
                                let hdKey = try mk.derive(path)
                                let xpub = hdKey.xpub
                                
                                if xpub == backupXpub {
                                    
                                    DispatchQueue.main.async { [unowned vc = self] in
                                        
                                        var alertStyle = UIAlertController.Style.actionSheet
                                        if (UIDevice.current.userInterfaceIdiom == .pad) {
                                          alertStyle = UIAlertController.Style.alert
                                        }
                                                    
                                        let alert = UIAlertController(title: "Recovery words match your wallets xpub!", message: "You may now go to the next step", preferredStyle: alertStyle)

                                        alert.addAction(UIAlertAction(title: "Next", style: .default, handler: { action in
                                            
                                            if vc.testingWords {
                                                
                                                vc.words = nil
                                                
                                            }
                                            
                                            vc.confirm()
                                            
                                        }))
                                        
                                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                        alert.popoverPresentationController?.sourceView = self.view
                                        vc.present(alert, animated: true, completion: nil)
                                        
                                    }
                                    
                                    
                                } else {
                                    
                                    showAlert(vc: vc, title: "Error", message: "that recovery phrase does not match the required recovery phrase for this wallet")
                                    
                                }
                                
                            } catch {
                                
                                showAlert(vc: vc, title: "Error", message: "error deriving xpub from master key")
                                
                            }
                            
                        } else {
                            
                            showAlert(vc: vc, title: "Error", message: "error converting derivation to bip32 path")
                            
                        }
                        
                    } else {
                        
                        showAlert(vc: vc, title: "Error", message: "error deriving master key")
                        
                    }
                    
                } else {
                    
                    showAlert(vc: vc, title: "Error", message: "error converting your words to a valid mnemonic")
                    
                }
                
            }
            
        } else {
            /// It's words only
            func addSeed() {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.seedArray.append(vc.justWords.joined(separator: " "))
                    vc.justWords.removeAll()
                    vc.addedWords.removeAll()
                    vc.textField.text = ""
                    vc.label.text = ""
                    vc.updatePlaceHolder(wordNumber: 1)
                }
            }
            
            func seedAddedAddAnother() {
                DispatchQueue.main.async { [unowned vc = self] in
                    var alertStyle = UIAlertController.Style.actionSheet
                    if (UIDevice.current.userInterfaceIdiom == .pad) {
                      alertStyle = UIAlertController.Style.alert
                    }
                    let alert = UIAlertController(title: "Seed added, you may now add another.", message: "", preferredStyle: alertStyle)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
                    alert.popoverPresentationController?.sourceView = self.view
                    vc.present(alert, animated: true, completion: nil)
                }
            }
            
            if words != "" {
                chooseDerivation()
            
            } else if !recoveringMultiSigWithWordsOnly {
                DispatchQueue.main.async { [unowned vc = self] in
                    var alertStyle = UIAlertController.Style.actionSheet
                    if (UIDevice.current.userInterfaceIdiom == .pad) {
                      alertStyle = UIAlertController.Style.alert
                    }
                    let alert = UIAlertController(title: "That is a valid recovery phrase", message: "Are you recovering a multi-sig account or single-sig account?", preferredStyle: alertStyle)
                    alert.addAction(UIAlertAction(title: "Single-sig", style: .default, handler: { action in
                        vc.chooseDerivation()
                    }))
                    alert.addAction(UIAlertAction(title: "Multi-sig", style: .default, handler: { action in
                        vc.recoveringMultiSigWithWordsOnly = true
                        addSeed()
                        seedAddedAddAnother()
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    alert.popoverPresentationController?.sourceView = self.view
                    vc.present(alert, animated: true, completion: nil)
                }
            } else {
                /// Adding multiple sets of words to recover multi-sig with only words.
                DispatchQueue.main.async { [unowned vc = self] in
                    var alertStyle = UIAlertController.Style.actionSheet
                    if (UIDevice.current.userInterfaceIdiom == .pad) {
                      alertStyle = UIAlertController.Style.alert
                    }
                    
                    let alert = UIAlertController(title: "That is a valid recovery phrase", message: "Add another seed phrase or recover this multi-sig account now? When recovering multi-sig accounts with words only we utilize BIP67 by default.", preferredStyle: alertStyle)

                    alert.addAction(UIAlertAction(title: "Add another seed", style: .default, handler: { action in
                        vc.seedArray.append(vc.justWords.joined(separator: " "))
                        vc.justWords.removeAll()
                        vc.addedWords.removeAll()
                        vc.textField.text = ""
                        vc.label.text = ""
                        vc.updatePlaceHolder(wordNumber: 1)
                        seedAddedAddAnother()
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Recover Now", style: .default, handler: { action in
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.seedArray.append(vc.justWords.joined(separator: " "))
                            vc.justWords.removeAll()
                            vc.addedWords.removeAll()
                            vc.textField.text = ""
                            vc.updatePlaceHolder(wordNumber: 1)
                            vc.performSegue(withIdentifier: "segueToNumberOfSigners", sender: vc)
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    alert.popoverPresentationController?.sourceView = self.view
                    vc.present(alert, animated: true, completion: nil)
                    
                }
            }
        }
    }
    
    private func mnemonic() -> BIP39Mnemonic? {
        if words != nil {
            return BIP39Mnemonic(words!)
        } else {
            return nil
        }
    }
    
    private func masterKey(mnemonic: BIP39Mnemonic) -> HDKey? {
        return HDKey(mnemonic.seedHex(""), network)
    }
    
    private func path(deriv: String) -> BIP32Path? {
        return BIP32Path(deriv)
    }
    
    private func fingerprint(key: HDKey) -> String {
        return key.fingerprint.hexString
    }
    
    private func xpub(path: BIP32Path) -> String? {
        if mnemonic() != nil {
            if let mk = masterKey(mnemonic: mnemonic()!) {
                do {
                    return try mk.derive(path).xpub
                } catch {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func xprv(path: BIP32Path) -> String? {
        if mnemonic() != nil {
            if let mk = masterKey(mnemonic: mnemonic()!) {
                do {
                    return try mk.derive(path).xpriv
                } catch {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func accountlessPath() -> String {
        var accountLessPath = ""
        if derivation != nil {
            let arr = derivation!.split(separator: "/")
            for (i, item) in arr.enumerated() {
                if i < 3 {
                    accountLessPath += item + "/"
                }
            }
        }
        return accountLessPath
    }
    
    private func customDescriptors(prefix: String) -> (primaryDescriptors: [String], changeDescriptors: [String]) {
        var primDescs:[String] = []
        var changeDescs:[String] = []
        if words != nil {
            if let mnemonic = mnemonic() {
                if let mk = masterKey(mnemonic: mnemonic) {
                    if let path = path(deriv: self.derivationField.text!) {
                        let pathWithFingerprint = (path.description).replacingOccurrences(of: "m", with: fingerprint(key: mk))
                        if let xpub = xpub(path: path) {
                            var primDesc = ""
                            switch prefix {
                            case "wpkh":
                                primDesc = "\"wpkh([\(pathWithFingerprint)]\(xpub)/0/*)\""
                                
                            case "pkh":
                                primDesc = "\"pkh([\(pathWithFingerprint)]\(xpub)/0/*)\""
                                
                            case "sh(wpkh":
                                primDesc = "\"sh(wpkh([\(pathWithFingerprint)]\(xpub)/0/*))\""
                                 
                            default:
                                break
                            }
                            primDescs.append(primDesc)
                            changeDescs.append(primDesc.replacingOccurrences(of: "/0/*", with: "/1/*"))
                        }
                    }
                }
            }
        }
        return (primDescs, changeDescs)
    }
    
    private func descriptors() -> (primaryDescriptors: [String], changeDescriptors: [String]) {
        var primDescs:[String] = []
        var changeDescs:[String] = []
        if words != nil {
            if let mnemonic = mnemonic() {
                if let mk = masterKey(mnemonic: mnemonic) {
                    for i in 0...9 {
                        if let path = path(deriv: accountlessPath() + "\(i)'") {
                            let pathWithFingerprint = (path.description).replacingOccurrences(of: "m", with: fingerprint(key: mk))
                            if let xpub = xpub(path: path) {
                                var primDesc = ""
                                switch self.derivation {
                                case "m/84'/1'/0'":
                                    primDesc = "\"wpkh([\(pathWithFingerprint)]\(xpub)/0/*)\""
                                    
                                case "m/84'/0'/0'":
                                    primDesc = "\"wpkh([\(pathWithFingerprint)]\(xpub)/0/*)\""
                                    
                                case "m/44'/1'/0'":
                                    primDesc = "\"pkh([\(pathWithFingerprint)]\(xpub)/0/*)\""
                                     
                                case "m/44'/0'/0'":
                                    primDesc = "\"pkh([\(pathWithFingerprint)]\(xpub)/0/*)\""
                                    
                                case "m/49'/1'/0'":
                                    primDesc = "\"sh(wpkh([\(pathWithFingerprint)]\(xpub)/0/*))\""
                                    
                                case "m/49'/0'/0'":
                                    primDesc = "\"sh(wpkh([\(pathWithFingerprint)]\(xpub)/0/*))\""
                                    
                                default:
                                    primDesc = "\"wpkh([\(pathWithFingerprint)]\(xpub)/0/*)\""
                                    
                                }
                                primDescs.append(primDesc)
                                changeDescs.append(primDesc.replacingOccurrences(of: "/0/*", with: "/1/*"))
                            }
                        }
                    }
                }
            }
        }
        return (primDescs, changeDescs)
    }
    
    private func setCustomXprvs(completion: @escaping ((Bool)) -> Void) {
        if words != nil {
            var encryptedXprvs:[Data] = []
            if let path = path(deriv: derivationField.text!) {
                if let xprv = xprv(path: path) {
                    Encryption.encryptData(dataToEncrypt: xprv.dataUsingUTF8StringEncoding) { [unowned vc = self] (encryptedData, error) in
                        if encryptedData != nil {
                            encryptedXprvs.append(encryptedData!)
                            vc.recoveryDict["xprvs"] = encryptedXprvs
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    private func setXprvs(completion: @escaping ((Bool)) -> Void) {
        if words != nil {
            var encryptedXprvs:[Data] = []
            for i in 0...9 {
                if let path = path(deriv: accountlessPath() + "\(i)'") {
                    if let xprv = xprv(path: path) {
                        Encryption.encryptData(dataToEncrypt: xprv.dataUsingUTF8StringEncoding) { [unowned vc = self] (encryptedData, error) in
                            if encryptedData != nil {
                                encryptedXprvs.append(encryptedData!)
                                if i == 9 {
                                    vc.recoveryDict["xprvs"] = encryptedXprvs
                                    completion(true)
                                }
                            } else {
                                completion(false)
                            }
                        }
                    } else {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        } else {
            completion(false)
        }
    }
    
    private func getDescriptorInfo(desc: String, completion: @escaping ((descriptor: String?, errorMessage: String?)) -> Void) {
        Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: "\(desc)") { (object, errorDescription) in
            if let dict = object as? NSDictionary {
                if let descriptor = dict["descriptor"] as? String {
                    completion((descriptor, nil))
                } else {
                    completion((nil, errorDescription ?? "unknown"))
                }
            } else {
                completion((nil, errorDescription ?? "unknown"))
            }
        }
    }
    
    private func buildChangeDescriptors(_ descriptors: [String]) {
        if index < descriptors.count {
            getDescriptorInfo(desc: descriptors[index]) { [unowned vc = self] (descriptor, errorMessage) in
                if descriptor != nil {
                    vc.processedChangeDescriptors.append(descriptor!)
                    vc.index += 1
                    vc.buildChangeDescriptors(descriptors)
                } else {
                    showAlert(vc: vc, title: "Error", message: "Error getting descriptor info: \(errorMessage ?? "unknown")")
                    vc.cv.removeConnectingView()
                }
            }
        } else {
            setWalletDict()
        }
    }
    
    private func buildPrimDescriptors(_ descriptors: [String], _ changeDescriptors: [String]) {
        if index < descriptors.count {
            getDescriptorInfo(desc: descriptors[index]) { [unowned vc = self] (descriptor, errorMessage) in
                if descriptor != nil {
                    vc.processedPrimaryDescriptors.append(descriptor!)
                    vc.index += 1
                    vc.buildPrimDescriptors(descriptors, changeDescriptors)
                } else {
                    showAlert(vc: vc, title: "Error", message: "Error getting descriptor info: \(errorMessage ?? "unknown")")
                    vc.cv.removeConnectingView()
                }
            }
        } else {
            index = 0
            buildChangeDescriptors(changeDescriptors)
        }
    }
    
    private func setWalletDict() {
        
        CoreDataService.retrieveEntity(entityName: .wallets) { [unowned vc = self] (wallets, errorDescription) in
            
            if wallets != nil {
                
                if wallets!.count == 0 {
                    vc.recoveryDict["isActive"] = true
                } else {
                    vc.recoveryDict["isActive"] = false
                }
                
                vc.recoveryDict["type"] = "DEFAULT"
                vc.recoveryDict["id"] = UUID()
                vc.recoveryDict["blockheight"] = Int32(0)
                vc.recoveryDict["maxRange"] = 2500
                vc.recoveryDict["lastUsed"] = Date()
                vc.recoveryDict["isArchived"] = false
                vc.recoveryDict["birthdate"] = keyBirthday()
                vc.recoveryDict["nodeIsSigner"] = false
                
                for (i, desc) in vc.processedPrimaryDescriptors.enumerated() {
                    
                    DispatchQueue.main.async { [unowned vc = self] in
                        if vc.derivationField.text != "" {
                            
                            if desc.contains("/0/*") {
                                vc.walletNameHash = Encryption.sha256hash(desc)
                                vc.recoveryDict["descriptor"] = desc
                                vc.recoveryDict["name"] = vc.walletNameHash
                            } else if desc.contains("/1/*") {
                                vc.recoveryDict["changeDescriptor"] = desc
                            }
                            if i + 1 == vc.processedPrimaryDescriptors.count {
                                vc.setCustomXprvs { (success) in
                                    if success {
                                        vc.cv.removeConnectingView()
                                        vc.confirm()
                                    } else {
                                        vc.cv.removeConnectingView()
                                        showAlert(vc: vc, title: "Error", message: "There was an error encrypting your xprvs.")
                                    }
                                }
                            }
                            
                        } else {
                            
                            if desc.contains("/84'/1'/0'") || desc.contains("/84'/0'/0'") || desc.contains("/44'/1'/0'") || desc.contains("/44'/0'/0'") || desc.contains("/49'/1'/0'") || desc.contains("/49'/0'/0'") {
                                if desc.contains("/0/*") {
                                    vc.walletNameHash = Encryption.sha256hash(desc)
                                    vc.recoveryDict["descriptor"] = desc
                                    vc.recoveryDict["name"] = vc.walletNameHash
                                } else if desc.contains("/1/*") {
                                    vc.recoveryDict["changeDescriptor"] = desc
                                }
                            }
                            
                            if i + 1 == vc.processedPrimaryDescriptors.count {
                                vc.setXprvs { (success) in
                                    if success {
                                        vc.cv.removeConnectingView()
                                        vc.confirm()
                                    } else {
                                        vc.cv.removeConnectingView()
                                        showAlert(vc: vc, title: "Error", message: "There was an error encrypting your xprvs.")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "segueToNumberOfSigners":
            if let vc = segue.destination as? ChooseNumberOfSignersViewController {
                vc.seedArray = seedArray
            }
            
        case "confirmFromWords":
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                vc.walletNameHash = self.walletNameHash
                vc.walletDict = self.recoveryDict
                vc.words = self.words
                vc.derivation = self.derivation
                vc.changeDescriptors = processedChangeDescriptors
                vc.primaryDescriptors = processedPrimaryDescriptors
                vc.updateDerivationBlock = { [unowned thisVc = self] dict in
                    thisVc.cv.addConnectingView(vc: self, description: "building your account descriptors, this can take a minute..")
                    if let wrds = dict["words"], let der = dict["derivation"] {
                        Encryption.getNode { (node, error) in
                            if node != nil {
                                thisVc.index = 0
                                thisVc.recoveryDict = [:]
                                thisVc.recoveryDict["nodeId"] = node!.id
                                thisVc.walletNameHash = ""
                                thisVc.processedChangeDescriptors.removeAll()
                                thisVc.processedPrimaryDescriptors.removeAll()
                                thisVc.words = wrds
                                thisVc.derivation = der.replacingOccurrences(of: "/0/0", with: "")
                                thisVc.derivation = thisVc.derivation!.condenseWhitespace()
                                thisVc.recoveryDict["derivation"] = thisVc.derivation
                                let (primDescriptors, changeDescriptors) = thisVc.descriptors()
                                thisVc.buildPrimDescriptors(primDescriptors, changeDescriptors)
                            }
                        }
                    }
                }
            }
            
        default:
            break
            
        }
    }

}
