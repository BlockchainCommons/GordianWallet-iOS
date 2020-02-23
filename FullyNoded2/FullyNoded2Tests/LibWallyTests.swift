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

}
