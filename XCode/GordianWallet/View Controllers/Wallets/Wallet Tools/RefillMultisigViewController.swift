//
//  RefillMultisigViewController.swift
//  FullyNoded2
//
//  Created by Peter on 29/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import LibWally
import UIKit
import SSKR

class RefillMultisigViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var lostWordsOutlet: UIButton!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var wordsView: UIView!
    @IBOutlet var textField: UITextField!
    var addSeed = Bool()
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
    var rawShards = [String]()
    var shards = [Shard]()
    
    var groupShares = [[SSKRShare]]()
    var shares = [SSKRShare]()

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
        descriptionLabel.adjustsFontSizeToFitWidth = true
        wordsView.layer.cornerRadius = 8
        tap.addTarget(self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        bip39Words = Bip39Words.validWords
        updatePlaceHolder(wordNumber: 1)
        
        if addSeed {
            navigationItem.title = "Add Signer"
            descriptionLabel.text = "You can add a 12 or 24 word BIP39 seed phrase which can sign for this account, or you can scan SSKR UR shards by tapping the QR scanner."
            lostWordsOutlet.alpha = 0
            
        }
        
    }
    
    @IBAction func scanShardsAction(_ sender: Any) {
        goScan()
    }
    
    // Checks if we are complete or not
    private func processShard(_ shard: Shard) -> (complete: Bool, entropy: Data?, totalSharesRemainingInGroup: Int) {
        let totalGroupsRequired = shard.groupThreshold
        let totalMembersRequired = shard.memberThreshold
        let group = shard.groupIndex
        
        var existingShardsInGroup = 0
        
        
        for s in shards {
            if s.groupIndex == group {
                existingShardsInGroup += 1
            }
        }
        
        let totalSharesRemainingInGroup = totalMembersRequired - existingShardsInGroup
        
        var groups = [Int]()
        
        if existingShardsInGroup == totalMembersRequired {
            for s in shards {
                groups.append(s.groupIndex)
            }
        } else {
            return (false, nil, totalSharesRemainingInGroup)
        }
        
        let uniqueGroups = Array(Set(groups))
        
        if uniqueGroups.count == totalGroupsRequired {
            // DING DING DING DING DING DING DING DING DING DING
            guard let recoveredEntropy = try? SSKRCombine(shares: shares) else { return (false, nil, totalSharesRemainingInGroup) }
            
            return (true, recoveredEntropy, totalSharesRemainingInGroup)
        } else {
            
            return (false, nil, totalSharesRemainingInGroup)
        }
    }
    
    private func deriveMnemonicFromEntropy(_ entropy: Data) {
        guard let recoveredEntropy = BIP39Entropy(entropy.hexString) else { return }
        guard let mnemonic = BIP39Mnemonic(recoveredEntropy) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.textField.text = mnemonic.description
            self?.processTextfieldInput()
        }
    }
    
    private func parseUr(_ ur: String) -> (valid: Bool, alreadyAdded: Bool, shard: String) {
        let shard = URHelper.urToShard(sskrUr: ur) ?? ""
        guard shard != "" else { return (false, false, shard) }
        guard shardAlreadyAdded(shard) == false else { return (true, true, shard) }
        rawShards.append(shard)
        let share = SSKRShare(data: [UInt8](Data(shard)!))
        shares.append(share)
        return (true, false, shard)
    }
    
    private func shardAlreadyAdded(_ shard: String) -> Bool {
        guard rawShards.count > 0 else { return false }
        var shardAlreadyExists = false
        for s in rawShards {
            if shard == s {
                shardAlreadyExists = true
            }
        }
        return shardAlreadyExists
    }
    
    private func parseShard(_ shard: String) -> Shard? {
        let id = shard.prefix(4)
        let shareValue = shard.replacingOccurrences(of: shard.prefix(10), with: "") /// the length of this value should equal the length of the master seed
        let array = Array(shard)
        
        guard let groupThresholdIndex = Int("\(array[4])"),                         /// required # of groups
            let groupCountIndex = Int("\(array[5])"),                               /// total # of possible groups
            let groupIndex = Int("\(array[6])"),                                    /// # the group this share belongs to
            let memberThresholdIndex = Int("\(array[7])"),                          /// # of shares required from this group
            let reserved = Int("\(array[8])"),                                      /// MUST be 0
            let memberIndex = Int("\(array[9])") else { return nil }                ///  the shares member # within its group
        
        let dict = [
            
            "id": id,
            "shareValue": shareValue,                                               /// the length of this value should equal the length of the master seed
            "groupThreshold": groupThresholdIndex + 1,                              /// required # of groups
            "groupCount": groupCountIndex + 1,                                      /// total # of possible groups
            "groupIndex": groupIndex + 1,                                           /// the group this share belongs to
            "memberThreshold": memberThresholdIndex + 1,                            /// # of shares required from this group
            "reserved": reserved,                                                   /// MUST be 0
            "memberIndex": memberIndex + 1,                                         /// the shares member # within its group
            "raw": shard
            
        ] as [String:Any]
        
        return Shard(dictionary: dict)
    }
    
    private func promptToScanAnotherShard(_ totalSharesRemainingInGroup: Int) {
        DispatchQueue.main.async { [weak self] in
            var alertStyle = UIAlertController.Style.actionSheet
            
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            
            var message = "You still need \(totalSharesRemainingInGroup) more shards from this group."
            
            if totalSharesRemainingInGroup == 0 {
                message = "You need to add more shards from another group."
            }
            
            let alert = UIAlertController(title: "Valid SSKR shard scanned ✓", message: message, preferredStyle: alertStyle)
            
            alert.addAction(UIAlertAction(title: "Scan another shard", style: .default, handler: { action in
                self?.goScan()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                self?.connectingView.removeConnectingView()
            }))
            
            alert.popoverPresentationController?.sourceView = self?.view
            alert.popoverPresentationController?.sourceRect = self!.view.bounds
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    private func goScan() {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: "segueToScanShards", sender: self)
        }
    }
    
    private func updatePlaceHolder(wordNumber: Int) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.textField.attributedPlaceholder = NSAttributedString(string: "add word #\(wordNumber)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
    }
    
    @objc func handleTap() {
        DispatchQueue.main.async {
            self.textField.resignFirstResponder()
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
    
    @IBAction func minusAction(_ sender: Any) {
        
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
                vc.label.frame = CGRect(x: 16, y: 0, width: vc.wordsView.frame.width - 32, height: vc.wordsView.frame.height - 10)
                vc.label.numberOfLines = 0
                vc.label.sizeToFit()
                vc.wordsView.addSubview(vc.label)
                
                if vc.justWords.count == 12 {
                    
                    vc.validWordsAdded()
                    
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
            
            timer = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { [unowned vc = self] (timer) in
                
                let autocompleteResult = vc.formatAutocompleteResult(substring: substring, possibleMatches: suggestions)
                vc.putColorFormattedTextInTextField(autocompleteResult: autocompleteResult, userQuery : userQuery)
                vc.moveCaretToEndOfUserQueryPosition(userQuery: userQuery)
                
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
            vc.label.frame = CGRect(x: 16, y: 0, width: vc.wordsView.frame.width - 32, height: vc.wordsView.frame.height - 10)
            vc.label.numberOfLines = 0
            vc.label.sizeToFit()
            vc.wordsView.addSubview(vc.label)
            
            if vc.justWords.count == 12 {
                
                if let _ = BIP39Mnemonic(vc.justWords.joined(separator: " ")) {
                    
                    vc.validWordsAdded()
                    
                } else {
                    
                    showAlert(vc: vc, title: "Invalid", message: "Just so you know that is not a valid recovery phrase, if you are inputting a 24 word phrase ignore this message and keep adding your words.")
                    
                }
                
            }
            
        }
        
    }
    
    private func addSeedNow(xprv: String) {
        
        func add() {
            let words = justWords.joined(separator: " ")
            let unencryptedData = words.dataUsingUTF8StringEncoding
            Encryption.encryptData(dataToEncrypt: unencryptedData) { [unowned vc = self] (encryptedSeed, error) in
                if encryptedSeed != nil {
                    if KeyChain.saveNewSeed(encryptedSeed: encryptedSeed!) {
                        var xprvs:[Data] = []
                        Encryption.encryptData(dataToEncrypt: xprv.dataUsingUTF8StringEncoding) { [unowned vc = self] (encryptedXprv, error) in
                            if encryptedXprv != nil {
                                if vc.wallet.xprvs != nil {
                                    xprvs = vc.wallet.xprvs!
                                }
                                xprvs.append(encryptedXprv!)
                                CoreDataService.updateEntity(id: vc.wallet.id!, keyToUpdate: "xprvs", newValue: xprvs, entityName: .wallets) { (success, errorDesc) in
                                    if success {
                                        DispatchQueue.main.async { [unowned vc = self] in
                                            vc.updatePlaceHolder(wordNumber: 1)
                                            vc.label.text = ""
                                            NotificationCenter.default.post(name: .seedAdded, object: nil, userInfo: nil)
                                        }
                                        showAlert(vc: vc, title: "Success!", message: "Signer added, the device will now be able to sign for this wallet.")
                                        vc.connectingView.removeConnectingView()
                                    } else {
                                        showAlert(vc: vc, title: "Error", message: "We had an error saving your seed")
                                        vc.connectingView.removeConnectingView()
                                    }
                                }
                            } else {
                                showAlert(vc: vc, title: "Error", message: "We had an error saving your seed")
                                vc.connectingView.removeConnectingView()
                            }
                        }
                    } else {
                        showAlert(vc: vc, title: "Error", message: "We had an error saving your seed")
                        vc.connectingView.removeConnectingView()
                    }
                }
            }
        }
        
        DispatchQueue.main.async { [unowned vc = self] in
            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
              alertStyle = UIAlertController.Style.alert
            }
            
            let alert = UIAlertController(title: "That mnemonic matches one of your wallets xpubs", message: "Would you like to add it as a signer?", preferredStyle: alertStyle)
            
            alert.addAction(UIAlertAction(title: "Add signer", style: .default, handler: { action in
                
                add()
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                
                vc.connectingView.removeConnectingView()
                
            }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    private func validWordsAdded() {
        
        DispatchQueue.main.async { [unowned vc = self] in
            
            vc.textField.text = ""
            vc.textField.resignFirstResponder()
            
        }
        
        connectingView.addConnectingView(vc: self, description: "verifying your xpub matches")
        let parser = DescriptorParser()
        let str = parser.descriptor(wallet.descriptor)
        let derivation = wallet.derivation
        
        MnemonicCreator.convert(words: justWords.joined(separator: " ")) { [unowned vc = self] (mnemonic, error) in
            
            if !error && mnemonic != nil {
                let seed = mnemonic!.seedHex()
                
                if let mk = HDKey(seed, network(descriptor: vc.wallet.descriptor)) {
                    
                    if let path = BIP32Path(derivation) {
                        
                        do {
                            
                            let hdKey = try mk.derive(path)
                            let xpub = hdKey.xpub
                            var existingXpubs = [String]()
                            
                            if vc.wallet.type == "MULTI" {
                                existingXpubs = str.multiSigKeys
                                
                            } else {
                                existingXpubs.append(str.accountXpub)
                                
                            }
                            
                            var xpubsMatch = false
                            
                            for (x, existingXpub) in existingXpubs.enumerated() {
                                
                                if xpub == existingXpub {
                                    
                                    xpubsMatch = true
                                    
                                }
                                
                                if x + 1 == existingXpubs.count {
                                    
                                    if xpubsMatch {
                                        
                                        if !vc.addSeed {
                                            
                                            if xpub == str.multiSigKeys[0] || xpub == str.multiSigKeys[2] {
                                                
                                                DispatchQueue.main.async {
                                                    vc.connectingView.label.text = "xpub's match, refilling keypool"
                                                }
                                                vc.refillMulti(hdKey: hdKey)
                                                
                                            } else {
                                                
                                                vc.connectingView.removeConnectingView()
                                                showAlert(vc: vc, title: "Error", message: "That xpub matches your device's xpub, in order to add private keys to your node to refill the keypool we need to use one of the offline recovery phrases.")
                                            }
                                                                                        
                                        } else {
                                            
                                            DispatchQueue.main.async {
                                                vc.connectingView.removeConnectingView()
                                            }
                                            if let xprv = hdKey.xpriv {
                                                vc.addSeedNow(xprv: xprv)
                                            } else {
                                                showAlert(vc: vc, title: "Error", message: "There was an error deriving your xprv.")
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        vc.connectingView.removeConnectingView()
                                        showAlert(vc: vc, title: "Error", message: "that recovery phrase does not match the required recovery phrase for this wallet")
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        } catch {
                            
                            vc.connectingView.removeConnectingView()
                            showAlert(vc: vc, title: "Error", message: "error deriving xpub from master key")
                            
                        }
                        
                    } else {
                        
                        vc.connectingView.removeConnectingView()
                        showAlert(vc: vc, title: "Error", message: "error converting derivation to bip32 path")
                        
                    }
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: "error deriving master key")
                    
                }
                
            } else {
                
                vc.connectingView.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: "error converting your words to a valid mnemonic")
                
            }
            
        }
        
    }
    
    private func refillMulti(hdKey: HDKey) {
        
        let backUpXpub = hdKey.xpub
        if let backUpXprv = hdKey.xpriv {
            
            let refillMultiSig = RefillMultiSig()
            refillMultiSig.refill(wallet: wallet, recoveryXprv: backUpXprv, recoveryXpub: backUpXpub) { [unowned vc = self] (success, error) in
                
                if success {
                    
                    CoreDataService.updateEntity(id: vc.wallet.id!, keyToUpdate: "nodeIsSigner", newValue: true, entityName: .wallets) { _ in
                        
                        vc.connectingView.removeConnectingView()
                        
                        DispatchQueue.main.async {
                            
                            vc.dismiss(animated: true) {
                                
                                vc.multiSigRefillDoneBlock!(true)
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    vc.connectingView.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: error!)
                    
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
    
    @IBAction func lostWords(_ sender: Any) {
        
        showAlert(vc: self, title: "Lost your offline recovery words?", message: "If you lost your offline recovery words don't worry, you can still create a new multi-sig wallet then use the \"sweep to\" tool to send all your funds to the new wallet.\n\nMake sure you keep safe backups of the QR and words this time!")
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "segueToScanShards" {
            guard let vc = segue.destination as? ScannerViewController else { return }
            vc.scanningShards = true
            
            vc.returnStringBlock = { [weak self] ur in
                guard let self = self else { return }
                
                let (isValid, alreadyAdded, s) = self.parseUr(ur)
                
                if isValid && !alreadyAdded {
                    if let shardStruct = self.parseShard(s) {
                        self.shards.append(shardStruct)
                        
                        let (complete, entropy, totalRemaining) = self.processShard(shardStruct)
                        if !complete {
                            self.promptToScanAnotherShard(totalRemaining)
                        } else if entropy != nil {
                            self.deriveMnemonicFromEntropy(entropy!)
                        } else {
                            showAlert(vc: self, title: "Error!", message: "There was an error converting those shards to entropy")
                        }
                    }
                } else {
                    
                }
            }
        }
    }
    

}


