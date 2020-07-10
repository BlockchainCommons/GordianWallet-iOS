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
    var addingIndpendentSeed = Bool()
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var wordView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        textField.delegate = self
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        wordView.layer.cornerRadius = 8
        bip39Words = Bip39Words.validWords
        updatePlaceHolder(wordNumber: 1)
        
        if addingSeed || addingIndpendentSeed {
            
            navigationItem.title = "Add BIP39 Phrase"
            
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
        processTextfieldInput()
    }
    
    private func chooseDerivation() {
        
        Encryption.getNode { [unowned vc = self] (node, error) in
            
            if !error && node != nil {
                
                DispatchQueue.main.async {
                    
                    let network = node!.network
                    vc.recoveryDict["nodeId"] = node!.id
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
                        vc.buildDescriptor()
                        
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
                        vc.buildDescriptor()
                        
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
                        vc.buildDescriptor()
                        
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                    
                    alert.popoverPresentationController?.sourceView = vc.view
                    vc.present(alert, animated: true, completion: nil)
                    
                }
                
            }
            
        }
        
    }
    
    private func processTextfieldInput() {
        print("processTextfieldInput")
        
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
    
    private func validWordsAdded() {
        
        //if !addingSeed && !addingIndpendentSeed {
            
            DispatchQueue.main.async { [unowned vc = self] in
                
                vc.textField.resignFirstResponder()
                vc.verify()
                
            }
            
//        } else if addingIndpendentSeed {
//
//            DispatchQueue.main.async { [unowned vc = self] in
//                vc.textField.resignFirstResponder()
//
//            }
//
//            let unencryptedSeed = (justWords.joined(separator: " ")).dataUsingUTF8StringEncoding
//
//            Encryption.encryptData(dataToEncrypt: unencryptedSeed) { [unowned vc = self] (encryptedSeed, error) in
//
//                if encryptedSeed != nil {
//
//
//                    let dict = ["seed":encryptedSeed!,"id":UUID()] as [String:Any]
//                    CoreDataService.saveEntity(dict: dict, entityName: .seeds) { (success, errorDesc) in
//
//                        if success {
//
//                            DispatchQueue.main.async { [unowned vc = self] in
//                                vc.textField.text = ""
//                                vc.label.text = ""
//                                vc.justWords.removeAll()
//                                vc.addedWords.removeAll()
//                                vc.updatePlaceHolder(wordNumber: 1)
//                                NotificationCenter.default.post(name: .seedAdded, object: nil, userInfo: nil)
//                            }
//
//                            showAlert(vc: vc, title: "Seed saved!", message: "You may go back or add another seed.")
//
//                        } else {
//
//                           showAlert(vc: vc, title: "Error", message: "We had an error saving that seed.")
//
//                        }
//
//                    }
//
//                }
//
//            }
                
        //} else {
            
//            DispatchQueue.main.async { [unowned vc = self] in
//
//                if vc.justWords.count == 12 {
//
//                    let alert = UIAlertController(title: "That is a valid BIP39 mnemonic", message: "You may now create your wallet", preferredStyle: .actionSheet)
//
//                    alert.addAction(UIAlertAction(title: "Create wallet", style: .default, handler: { action in
//
//                        DispatchQueue.main.async { [unowned vc = self] in
//
//                            vc.onSeedDoneBlock!(vc.justWords.joined(separator: " "))
//                            vc.navigationController!.popViewController(animated: true)
//
//                        }
//
//                    }))
//
//                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
//                    alert.popoverPresentationController?.sourceView = self.view
//                    vc.present(alert, animated: true, completion: nil)
//
//                }
//
//            }
            
        //}
        
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
                    if let mk = HDKey(seed, network(descriptor: desc)) {
                        
                        if let path = BIP32Path(derivation) {
                            
                            do {
                                
                                let hdKey = try mk.derive(path)
                                let xpub = hdKey.xpub
                                
                                if xpub == backupXpub {
                                    
                                    DispatchQueue.main.async { [unowned vc = self] in
                                                    
                                        let alert = UIAlertController(title: "Recovery words match your wallets xpub!", message: "You may now go to the next step", preferredStyle: .actionSheet)

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
                    let alert = UIAlertController(title: "Seed added, you may now add another.", message: "", preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in }))
                    alert.popoverPresentationController?.sourceView = self.view
                    vc.present(alert, animated: true, completion: nil)
                }
            }
            
            if !recoveringMultiSigWithWordsOnly {
                DispatchQueue.main.async { [unowned vc = self] in
                    let alert = UIAlertController(title: "That is a valid recovery phrase", message: "Are you recovering a multi-sig account or single-sig account?", preferredStyle: .actionSheet)
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
                    
                    let alert = UIAlertController(title: "That is a valid recovery phrase", message: "Add another seed phrase or recover this multi-sig account now? When recovering multi-sig accounts with words only we utilize BIP67 by default.", preferredStyle: .actionSheet)

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
    
    private func buildDescriptor() {
        
        cv.addConnectingView(vc: self, description: "building your wallets descriptor")
        MnemonicCreator.convert(words: words!) { [unowned vc = self] (mnemonic, error) in
            
            if !error && mnemonic != nil {
                
                var network:Network!
                if vc.derivation!.contains("1") {
                    network = .testnet
                } else {
                    network = .mainnet
                }
                
                let mk = HDKey(mnemonic!.seedHex(), network)!
                let fingerprint = mk.fingerprint.hexString
                var param = ""
                
                do {
                    
                    if let xprv = try mk.derive(BIP32Path(vc.derivation!)!).xpriv {
                        Encryption.encryptData(dataToEncrypt: xprv.dataUsingUTF8StringEncoding) { (encryptedData, error) in
                            if encryptedData != nil {
                                vc.recoveryDict["xprvs"] = [encryptedData!]
                                do {
                                    let xpub = try mk.derive(BIP32Path(vc.derivation!)!).xpub
                                    
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
                                    
                                    let changeDesc = param.replacingOccurrences(of: "/0/*", with: "/1/*")
                                    
                                    Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: param) { [unowned vc = self] (object, errorDesc) in
                                        
                                        if let dict = object as? NSDictionary {
                                            
                                            let desc = dict["descriptor"] as! String
                                            vc.walletNameHash = Encryption.sha256hash(desc)
                                            vc.recoveryDict["descriptor"] = desc
                                            vc.recoveryDict["type"] = "DEFAULT"
                                            vc.recoveryDict["id"] = UUID()
                                            vc.recoveryDict["blockheight"] = Int32(0)
                                            vc.recoveryDict["maxRange"] = 2500
                                            CoreDataService.retrieveEntity(entityName: .wallets) { (wallets, errorDescription) in
                                                if wallets != nil {
                                                    if wallets!.count == 0 {
                                                        vc.recoveryDict["isActive"] = true
                                                    } else {
                                                        vc.recoveryDict["isActive"] = false
                                                    }
                                                }
                                            }
                                            vc.recoveryDict["lastUsed"] = Date()
                                            vc.recoveryDict["isArchived"] = false
                                            vc.recoveryDict["birthdate"] = keyBirthday()
                                            vc.recoveryDict["name"] = vc.walletNameHash
                                            vc.recoveryDict["nodeIsSigner"] = false
                                            
                                            Reducer.makeCommand(walletName: "", command: .getdescriptorinfo, param: changeDesc) { [unowned vc = self] (object, errorDescription) in
                                                
                                                if let dict = object as? NSDictionary {
                                                    let changedescriptor = dict["descriptor"] as! String
                                                    vc.recoveryDict["changeDescriptor"] = changedescriptor
                                                    vc.cv.removeConnectingView()
                                                    vc.confirm()
                                                    
                                                } else {
                                                    vc.cv.removeConnectingView()
                                                    displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                                                }
                                            }
                                            
                                        } else {
                                            vc.cv.removeConnectingView()
                                            displayAlert(viewController: vc, isError: true, message: errorDesc ?? "unknown error")
                                            
                                        }
                                    }
                                } catch {
                                    
                                }
                                
                            }
                        }
                    }
                    
                    
                                        
                } catch {
                    vc.cv.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: "error constructing descriptor")
                    
                }
                
            } else {
                vc.cv.removeConnectingView()
                displayAlert(viewController: vc, isError: true, message: "error deriving mnemonic")
                
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
