//
//  LibWallyTests.swift
//  FullyNoded2Tests
//
//  Created by Peter on 22/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import XCTest
@testable import LibWally

class LibwallyTests: XCTestCase {
    
    let words = "unfold light protect unfold pulp like vintage drive receive egg dune sketch"
    let seed = "a7885414fe0b3b948a10b2de777e6ba8cfd38c4e1b7c63d3d87cc03c6886f7ec2a7f6962dded7212ef37d09ebafefb23a526208ed3e9c0b5300103ecf43ea48c"
    let masterKey = "tprv8ZgxMBicQKsPfBdpunno9R8wKwtH2dvKSTJoKVTTGCsBY59eGDhdC978G4xwtGCDQ2DoT7w5YRtbXmj6obgwLzkL3paqjr7LBqGioFdV6kN"
    let fingerprint = "253110e5"
    let expectedEntropy = "ed3032b2f69ad7037d0a1ab388d91065"
    
    func testMnemonicToEntropy() {
        let mnemonic = BIP39Mnemonic(words)!
        let entropy = BIP39Entropy(mnemonic.entropy.data)
        XCTAssertEqual(entropy.description, expectedEntropy)
    }
    
    func testEntropyToMnemonic() {
        let entropy = BIP39Entropy(expectedEntropy)!
        let mnemonic = BIP39Mnemonic(entropy)!
        XCTAssertEqual(mnemonic.words, words.components(separatedBy: " "))
    }
    
    func testMnemonicIsValid() {
        XCTAssertTrue(BIP39Mnemonic.isValid(words))
    }
    
    func testInitializeMnemonic() {
        let mnemonic = BIP39Mnemonic(words)
        XCTAssertNotNil(mnemonic)
        if (mnemonic != nil) {
            XCTAssertEqual(mnemonic!.words, words.components(separatedBy: " "))
        }
    }
    
    func testSeedToHDKey() {
        let hdKey = HDKey(BIP39Seed(seed)!, .testnet)
        XCTAssertEqual(hdKey!.xpriv, masterKey)
    }
    
    func testXpriv() {
        let hdKey = HDKey(masterKey)!
        XCTAssertEqual(hdKey.xpriv, masterKey)
    }
    
    func testFingerPrint() {
        let hdKey = HDKey(BIP39Seed(seed)!, .testnet)!
        XCTAssertEqual(hdKey.fingerprint.hexString, fingerprint)
    }
    
    func testMultiSigAddress() {
        
        let tpub0 = "tpubDCBcQ43ekkpE1B4jXEy3yAoQkhzLuByCNKF6DhayBCY69rFsgkvhvvSASckYXvef7eiAd2L38cn9rSMUidFBVprTBVcFRmEC9JUxL3iNbGc"
        let tpub1 = "tpubDDVoCgKo9RNvQ6SaYvED5euuZCBhcvkoCD2k9mfSgggDiAhfJLJgFaWXQKaNVzmapLHRGa8oPAVYrAo7vGWPM2YQV4EEWbocJrYE53DaUEk"
        let tpub2 = "tpubDC3sqNTgS8JMz5a9mXmKk2gw12faUjgzBMW3twAQDmWSJnkcXuGCzwzm1FUCyUZ2pV61D953yiitZtcro9jGdBYNbuXt45vpBAFgRwyJ4fS"
        let expectedMultiSigAddress = "tb1q76makhc2gr5lucx648escf834wdja3a04z9xd6ep0cypm2d5m4psremyjg"
        let expectedScriptPubKey = "52210291c75ac8c56747b59fb2d08c7f64cd6fff95af330e155d2eaf751f981f7f3501210369cd6d885b93195f98277af61b898c6576914b868e5acac8c7b8309e9091cec421027df2261c3470b5da88a5a6ada675658a46e3b51f6e72d52a7af13968d9a4314753ae"
        
        let masterKey0 = HDKey(tpub0)!
        let masterKey1 = HDKey(tpub1)!
        let masterKey2 = HDKey(tpub2)!
        
        do {
            
            let path = BIP32Path("0/0")!
            let key0 = try masterKey0.derive(path)
            let key1 = try masterKey1.derive(path)
            let key2 = try masterKey2.derive(path)
            let pubKeyArray = [key0.pubKey, key1.pubKey, key2.pubKey]
            let scriptPubKey = ScriptPubKey(multisig: pubKeyArray, threshold: 2, bip67: false)
            let address = Address(scriptPubKey, .testnet)!
            XCTAssertEqual(scriptPubKey, ScriptPubKey(expectedScriptPubKey)!)
            XCTAssertEqual("\(address)", expectedMultiSigAddress)
            
        } catch {
            
            XCTAssertEqual("fail", "we failed")
            XCTAssertEqual("fail", "we failed")
            
        }
        
    }

}
