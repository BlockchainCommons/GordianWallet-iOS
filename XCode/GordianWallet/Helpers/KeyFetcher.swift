//
//  KeyFetcher.swift
//  StandUp-iOS
//
//  Created by Peter on 12/01/19.
//  Copyright © 2019 BlockchainCommons. All rights reserved.
//

import Foundation
import LibWally

class KeyFetcher {
    
    class func accountKeys(seed: Data, chain: Network, derivation: String, completion: @escaping ((xprv: String?, xpub: String?, fingerprint: String?, error: Bool)) -> Void) {
        Encryption.decryptData(dataToDecrypt: seed) { (seed) in
            if seed != nil {
                let words = String(data: seed!, encoding: .utf8)!
                if let mnemonic = try? BIP39Mnemonic(words: words) {
                    if let masterKey = try? HDKey(seed: (mnemonic.seedHex(passphrase: "")), network: chain) {
                        let fingerprint = masterKey.fingerprint.hexString
                        if let path = try? BIP32Path(string: derivation) {
                            do {
                                let account = try masterKey.derive(using: path)
                                if let xprv = account.xpriv {
                                    completion((xprv, account.xpub, fingerprint, false))
                                }
                            } catch {
                                completion((nil, nil, nil, true))
                            }
                        } else {
                            completion((nil, nil, nil, true))
                        }
                    } else {
                        completion((nil, nil, nil, true))
                    }
                }
            } else {
                completion((nil, nil, nil, true))
            }
        }
    }

    class func xpub(seed: Data, chain: Network, derivation: String, completion: @escaping ((xpub: String?, fingerprint: String?, error: Bool)) -> Void) {

        Encryption.decryptData(dataToDecrypt: seed) { (seed) in

            if seed != nil {

                let words = String(data: seed!, encoding: .utf8)!
                
                MnemonicCreator.convert(words: words) { (mnemonic, error) in

                    if !error {

                        if let masterKey = try? HDKey(seed: (mnemonic!.seedHex(passphrase: "")), network: chain) {

                            let fingerprint = masterKey.fingerprint.hexString

                            if let path = try? BIP32Path(string: derivation) {

                                do {

                                    let account = try masterKey.derive(using: path)
                                    completion((account.xpub, fingerprint, false))

                                } catch {

                                    completion((nil, nil, true))

                                }

                            } else {

                                completion((nil, nil, true))

                            }

                        } else {

                            completion((nil, nil, true))

                        }

                    } else {

                        completion((nil, nil, true))

                    }

                }

            } else {

                completion((nil, nil, true))

            }

        }

    }

    class func accountXpub(descriptorStruct: DescriptorStruct, completion: @escaping ((xpub: String?, error: Bool)) -> Void) {

        if descriptorStruct.isMulti {

            if descriptorStruct.multiSigKeys.count > 0 {

                if descriptorStruct.multiSigKeys[1] != "" {

                    completion((descriptorStruct.multiSigKeys[1], false))

                } else {

                    completion(("", true))

                }

            } else {

                completion(("", true))

            }

        } else {

            let xpub = descriptorStruct.accountXpub
            completion((xpub, false))

        }

    }
    
    class func cosignerKey(_ words: String, completion: @escaping ((xpub: String?, error: Bool)) -> Void) {
        getActiveWalletNow() { (wallet, error) in
            guard let wallet = wallet else { completion((nil, true)); return }
            
            MnemonicCreator.convert(words: words) { (mnemonic, error) in
                guard let mnemonic = mnemonic else { completion((nil, true)); return }
                
                let chain = network(descriptor: wallet.descriptor)
                
                guard let masterKey = try? HDKey(seed: (mnemonic.seedHex(passphrase: "")), network: chain) else { completion((nil, true)); return }
                
                var coinType = 1
                
                if chain == .mainnet {
                    coinType = 0
                }
                
                guard let path = try? BIP32Path(string: "m/48h/\(coinType)h/0h/2h") else { completion((nil, true)); return }
                
                guard let account = try? masterKey.derive(using: path) else { completion((nil, true)); return }
                
                completion((account.xpub, false))
            }
        }
    }

    class func accountXprv(completion: @escaping ((xprv: String?, error: Bool)) -> Void) {

        getActiveWalletNow() { (wallet, error) in

            if wallet != nil && !error {

                let derivationPath = wallet!.derivation
                Encryption.decryptData(dataToDecrypt: wallet!.seed) { (seed) in

                    if seed != nil {

                        let words = String(data: seed!, encoding: .utf8)!
                        MnemonicCreator.convert(words: words) { (mnemonic, error) in

                            if !error {

                                if let masterKey = try? HDKey(seed: (mnemonic!.seedHex(passphrase: "")), network: network(descriptor: wallet!.descriptor)) {

                                    if let path = try? BIP32Path(string: derivationPath) {

                                        do {

                                            let account = try masterKey.derive(using: path)

                                            if let xprv = account.xpriv {

                                                completion((xprv,false))

                                            } else {

                                                completion((nil,true))

                                            }

                                        } catch {

                                            completion((nil,true))

                                        }

                                    } else {

                                        completion((nil,true))

                                    }

                                } else {

                                    completion((nil,true))

                                }

                            } else {

                                completion((nil,true))

                            }

                        }

                    } else {

                        completion((nil,true))

                    }

                }

            }

        }

    }

    class func musigAddress(completion: @escaping ((address: String?, errorMessage: String?)) -> Void) {

        getActiveWalletNow { (wallet, error) in

            if wallet != nil && !error {

                let index = wallet!.index + 1
                let param = "\"\(wallet!.descriptor)\", [\(index),\(index)]"

                Reducer.makeCommand(walletName: wallet!.name!, command: .deriveaddresses, param: param) { (object, errorDesc) in

                    if let addresses = object as? NSArray {

                        updateIndex(wallet: wallet!)

                        if let address = addresses[0] as? String {

                            completion((address,nil))

                        } else {

                            completion((nil, errorDesc))

                        }

                    } else {

                        completion((nil, errorDesc))

                    }

                }

            }

        }

    }

    class func musigChangeAddress(completion: @escaping ((address: String?, error: Bool, errorDescription: String?)) -> Void) {

        getActiveWalletNow { (wallet, error) in

            if wallet != nil && !error {

                let index = wallet!.index

                if wallet!.index < wallet!.maxRange {

                    let param = "\"\(wallet!.changeDescriptor)\", [\(index),\(index)]"

                    Reducer.makeCommand(walletName: wallet!.name!, command: .deriveaddresses, param: param) { (object, errorDesc) in

                        if let addresses = object as? NSArray {

                            if let address = addresses[0] as? String {

                                completion((address,false,nil))

                            } else {

                                completion((nil,true,"error fecthing change address"))

                            }

                        } else {

                            completion((nil,true,"error deriving addresses: \(errorDesc ?? "")"))

                        }

                    }

                } else {

                    completion((nil,true,"You need to refill the keypool in order to create more transactions"))

                }

            }

        }

    }

    class func updateIndex(wallet: WalletStruct) {
        CoreDataService.updateEntity(id: wallet.id!, keyToUpdate: "index", newValue: wallet.index + 1, entityName: .wallets) { (success, errorDescription) in
            if !success {
                print("error updating index: \(errorDescription ?? "unknown error")")
            }
        }
    }
    
    class func fetchAddresses(words: String, derivation: String, completion: @escaping (([String]?)) -> Void) {
        var addresses:[String] = []
        if let bip39mnemonic = try? BIP39Mnemonic(words: words) {
            let seed = bip39mnemonic.seedHex(passphrase: "")
            var addressType:AddressType!
            if let mk = try? HDKey(seed: seed, network: .testnet) {
                if derivation.contains("49") {
                    addressType = .payToScriptHashPayToWitnessPubKeyHash
                } else if derivation.contains("44") {
                    addressType = .payToPubKeyHash
                } else if derivation.contains("84") {
                    addressType = .payToWitnessPubKeyHash
                } else {
                    completion(nil)
                }
                if let path = try? BIP32Path(string: derivation) {
                    do {
                        let key = try mk.derive(using: path)
                        let address = key.address(type: addressType)
                        addresses.append(address.description)
                        completion(addresses)
                    } catch {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }

}
