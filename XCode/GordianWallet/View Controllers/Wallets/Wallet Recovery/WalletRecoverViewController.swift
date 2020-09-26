//
//  WalletRecoverViewController.swift
//  FullyNoded2
//
//  Created by Peter on 26/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import LibWally
import SSKR

class WalletRecoverViewController: UIViewController, UITextFieldDelegate {
    
    var testingWords = Bool()
    var str:DescriptorStruct!
    let connectingView = ConnectingView()
    var walletName = ""
    var recoveryDict = [String:Any]()
    var onQrDoneBlock: ((Bool) -> Void)?
    var alertStyle = UIAlertController.Style.actionSheet
    var rawShards = [String]()
    var shards = [Shard]()
    var groupShares = [[SSKRShare]]()
    var shares = [SSKRShare]()
    var words = ""
    
    @IBOutlet weak var seedWordsOutlet: UIButton!
    @IBOutlet weak var xpubsOutlet: UIButton!
    @IBOutlet var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanButton.layer.cornerRadius = 8
        seedWordsOutlet.layer.cornerRadius = 8
        xpubsOutlet.layer.cornerRadius = 8
        if (UIDevice.current.userInterfaceIdiom == .pad) {
          alertStyle = UIAlertController.Style.alert
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if UIPasteboard.general.hasImages {
            
            if let image = UIPasteboard.general.image {
                
                let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
                let ciImage:CIImage = CIImage(image: image)!
                var qrCodeLink = ""
                let features = detector.features(in: ciImage)
                for feature in features as! [CIQRCodeFeature] {
                    qrCodeLink += feature.messageString!
                }
                
                if let data = qrCodeLink.data(using: .utf8) {
                    
                    Encryption.getNode { (node, error) in
                        
                        if !error && node != nil {
                            
                            do {
                                
                                let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                                if let _ = dict["descriptor"] as? String {
                                    if let _ = dict["blockheight"] as? Int {
                                        DispatchQueue.main.async { [unowned vc = self] in
                                            let alert = UIAlertController(title: "There is a valid Account Map QR image on your clipboard", message: "Would you like to upload this image as a Account Map QR?", preferredStyle: vc.alertStyle)
                                            alert.addAction(UIAlertAction(title: "Upload Account Map QR", style: .default, handler: { action in
                                                vc.processImport(importItem: qrCodeLink)
                                            }))
                                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                            alert.popoverPresentationController?.sourceView = self.view
                                            vc.present(alert, animated: true, completion: nil)
                                        }
                                    }
                                }
                                
                            } catch  {}
                        }
                    }
                }
            }
            
        } else if UIPasteboard.general.hasStrings {
            
            if let value = UIPasteboard.general.string {
                if let data = value.data(using: .utf8) {
                    Encryption.getNode { (node, error) in
                        if !error && node != nil {
                            do {
                                let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                                if let _ = dict["descriptor"] as? String {
                                    if let _ = dict["blockheight"] as? Int {
                                        DispatchQueue.main.async { [unowned vc = self] in
                                            let alert = UIAlertController(title: "There is a valid Account Map text on your clipboard", message: "Would you like to upload this text as a Account Map QR?", preferredStyle: vc.alertStyle)
                                            alert.addAction(UIAlertAction(title: "Upload Account Map QR text", style: .default, handler: { action in
                                                vc.processImport(importItem: value)
                                            }))
                                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
                                            alert.popoverPresentationController?.sourceView = self.view
                                            vc.present(alert, animated: true, completion: nil)
                                        }
                                    }
                                }
                                
                            } catch {}
                            
                        }
                        
                    }
                                
                }
                
            }
            
        }
        
    }
    
    @IBAction func addXpubsManually(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToManualXpubRecovery", sender: vc)
        }        
    }
    
    @IBAction func getWordsAction(_ sender: Any) {
        getWords()
    }
    
    @IBAction func scanAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "scanRecovery", sender: vc)
        }
    }
    
    @IBAction func scanSskrNow(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: "scanSskrSegue", sender: self)
        }
    }
    
    @IBAction func moreinfo(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "showInfo", sender: vc)
        }
    }
    
    private func confirm() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "goConfirmQr", sender: vc)
        }
    }
    
    private func getWords() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "getWords", sender: vc)
        }
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
        self.words = mnemonic.description
        getWords()
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
            self?.performSegue(withIdentifier: "scanSskrSegue", sender: self)
        }
    }
    
    private func processImport(importItem: String) {
        let cv = ConnectingView()
        cv.addConnectingView(vc: self, description: "processing...")
        if importItem.hasPrefix("ur:crypto-sskr/") {
            
            cv.removeConnectingView()
            
            let (isValid, alreadyAdded, s) = self.parseUr(importItem)
            
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
            }
            
        } else if let data = importItem.data(using: .utf8) {
            do {
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                if let _ = dict["descriptor"] as? String {
                    if let _ = dict["blockheight"] as? Int {
                        /// It is an Account Map.
                        Import.importAccountMap(accountMap: dict) { walletDict in
                            if walletDict != nil {
                                DispatchQueue.main.async { [unowned vc = self] in
                                    vc.recoveryDict = walletDict!
                                    vc.walletName = walletDict!["name"] as! String
                                    vc.performSegue(withIdentifier: "goConfirmQr", sender: vc)
                                }
                            }
                        }
                    }
                }
            } catch {
                /// It is not an Account Map.
                Import.importDescriptor(descriptor: importItem) { [unowned vc = self] walletDict in
                    if walletDict != nil {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.recoveryDict = walletDict!
                            vc.walletName = walletDict!["name"] as! String
                            vc.performSegue(withIdentifier: "goConfirmQr", sender: vc)
                        }
                    } else {
                        cv.removeConnectingView()
                        showAlert(vc: vc, title: "Error", message: "error importing that account")
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
        case "segueToManualXpubRecovery":
            if let vc = segue.destination as? AddExtendedKeyViewController {
                vc.isRecovering = true
            }
            
        case "getWords":
            if let vc = segue.destination as? WordRecoveryViewController {
                vc.testingWords = testingWords
                vc.recoveryDict = recoveryDict
                vc.walletNameHash = walletName
                vc.words = words
            }
            
        case "goConfirmQr":
            if let vc = segue.destination as? ConfirmRecoveryViewController {
                vc.walletNameHash = walletName
                vc.walletDict = recoveryDict
                vc.isImporting = true
            }
            
        case "scanRecovery":
            if let vc = segue.destination as? ScannerViewController {
                vc.isRecovering = true
                vc.returnStringBlock = { [unowned thisVc = self] importItem in
                    thisVc.processImport(importItem: importItem)
                }
            }
            
        case "scanSskrSegue":
            if let vc = segue.destination as? ScannerViewController {
                vc.scanningShards = true
                vc.returnStringBlock = { [unowned thisVc = self] importItem in
                    thisVc.processImport(importItem: importItem)
                }
            }
            
        default:
            
            break
            
        }
        
    }

}
