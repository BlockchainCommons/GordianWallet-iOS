//
//  RefillMultisigViewController.swift
//  FullyNoded2
//
//  Created by Peter on 29/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import LibWally
import UIKit

class RefillMultisigViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var wordsView: UIView!
    @IBOutlet var textField: UITextField!
    var multiSigRefillDoneBlock: ((Bool) -> Void)?
    let label = UILabel()
    let tap = UITapGestureRecognizer()
    var autoCompleteCharacterCount = 0
    var timer = Timer()
    var addedWords = [String]()
    var justWords = [String]()
    var bip39Words = [String]()
    var wallet:WalletStruct!
    let connectingView = ConnectingView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        textField.delegate = self
        titleLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.adjustsFontSizeToFitWidth = true
        wordsView.layer.cornerRadius = 8
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        let wordList = Bip39Words()
        bip39Words = wordList.validWords
    }
    
    @objc func handleTap() {
        
        DispatchQueue.main.async {
            
            self.textField.resignFirstResponder()
            
        }
        
    }
    
    func processTextfieldInput() {
        
        let impact = UIImpactFeedbackGenerator()
        
        DispatchQueue.main.async {
            
            impact.impactOccurred()
            
        }
        
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
    
    @IBAction func minusAction(_ sender: Any) {
        
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
                
                if self.justWords.count == 12 {
                    
                    self.validWordsAdded()
                    
                }
                
            }
            
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
            
            timer = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { (timer) in //7
                
                self.textField.text = substring
                
                if let _ = BIP39Mnemonic(self.processedCharacters(self.textField.text!)) {
                    
                    self.textField.textColor = .systemGreen
                    self.validWordsAdded()
                    
                } else {
                    
                    self.textField.textColor = .systemRed
                    
                }
                
                
            })
            
            autoCompleteCharacterCount = 0
            
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
            
            if self.justWords.count == 12 {
                
                self.validWordsAdded()
                
            }
            
        }
        
    }
    
    private func validWordsAdded() {
        
        DispatchQueue.main.async {
            
            self.textField.resignFirstResponder()
                        
        }
        
        connectingView.addConnectingView(vc: self, description: "verifying your xpub matches")
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet.descriptor)
        let backupXpub = str.multiSigKeys[0]
        let derivation = self.wallet.derivation
        
        let mnemonicCreator = MnemonicCreator()
        mnemonicCreator.convert(words: justWords.joined(separator: " ")) { (mnemonic, error) in
            
            if !error && mnemonic != nil {
                
                let seed = mnemonic!.seedHex()
                if let mk = HDKey(seed, network(path: derivation)) {
                    
                    if let path = BIP32Path(derivation) {
                        
                        do {
                            
                            let hdKey = try mk.derive(path)
                            let xpub = hdKey.xpub
                            
                            if xpub == backupXpub {
                                
                                // from here we can refill
                                DispatchQueue.main.async {
                                   self.connectingView.label.text = "xpub's match, refilling keypool"
                                }
                                
                                self.refillMulti(hdKey: hdKey)
                                
                            } else {
                                
                                self.connectingView.removeConnectingView()
                                showAlert(vc: self, title: "Error", message: "that recovery phrase does not match the required recovery phrase for this wallet")
                                
                            }
                            
                        } catch {
                            
                            self.connectingView.removeConnectingView()
                            showAlert(vc: self, title: "Error", message: "error deriving xpub from master key")
                            
                        }
                        
                    } else {
                        
                        self.connectingView.removeConnectingView()
                        showAlert(vc: self, title: "Error", message: "error converting derivation to bip32 path")
                        
                    }
                    
                } else {
                    
                    self.connectingView.removeConnectingView()
                    showAlert(vc: self, title: "Error", message: "error deriving master key")
                    
                }
                
            } else {
                
                self.connectingView.removeConnectingView()
                showAlert(vc: self, title: "Error", message: "error converting your words to a valid mnemonic")
                
            }
            
        }
        
    }
    
    private func refillMulti(hdKey: HDKey) {
        
        let backUpXpub = hdKey.xpub
        if let backUpXprv = hdKey.xpriv {
            
            let refillMultiSig = RefillMultiSig()
            refillMultiSig.refill(wallet: wallet, recoveryXprv: backUpXprv, recoveryXpub: backUpXpub) { (success, error) in
                
                if success {
                    
                    self.connectingView.removeConnectingView()
                    
                    DispatchQueue.main.async {
                        
                        self.dismiss(animated: true) {
                            
                            self.multiSigRefillDoneBlock!(true)
                            
                        }
                        
                    }
                    
                } else {
                    
                    self.connectingView.removeConnectingView()
                    showAlert(vc: self, title: "Error", message: error!)
                    
                }
                
            }
            
        } else {
            
            self.connectingView.removeConnectingView()
            showAlert(vc: self, title: "Error", message: "error deriving your backup xprv")
            
        }
        
    }
    
    private func processedCharacters(_ string: String) -> String {
        
        var result = string.filter("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ".contains)
        result = result.condenseWhitespace()
        return result
        
    }
    
    @IBAction func addAction(_ sender: Any) {
        
        processTextfieldInput()
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
