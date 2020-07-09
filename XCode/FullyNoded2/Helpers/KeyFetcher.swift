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
                if let mnemonic = BIP39Mnemonic(words) {
                    if let masterKey = HDKey((mnemonic.seedHex("")), chain) {
                        let fingerprint = masterKey.fingerprint.hexString
                        if let path = BIP32Path(derivation) {
                            do {
                                let account = try masterKey.derive(path)
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

                        if let masterKey = HDKey((mnemonic!.seedHex("")), chain) {

                            let fingerprint = masterKey.fingerprint.hexString

                            if let path = BIP32Path(derivation) {

                                do {

                                    let account = try masterKey.derive(path)
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

    class func accountXprv(completion: @escaping ((xprv: String?, error: Bool)) -> Void) {

        getActiveWalletNow() { (wallet, error) in

            if wallet != nil && !error {

                let derivationPath = wallet!.derivation
                Encryption.decryptData(dataToDecrypt: wallet!.seed) { (seed) in

                    if seed != nil {

                        let words = String(data: seed!, encoding: .utf8)!
                        MnemonicCreator.convert(words: words) { (mnemonic, error) in

                            if !error {

                                if let masterKey = HDKey((mnemonic!.seedHex("")), network(descriptor: wallet!.descriptor)) {

                                    if let path = BIP32Path(derivationPath) {

                                        do {

                                            let account = try masterKey.derive(path)

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

    class func musigAddress(completion: @escaping ((address: String?, error: Bool)) -> Void) {

        getActiveWalletNow { (wallet, error) in

            if wallet != nil && !error {

                let index = wallet!.index + 1
                let param = "\"\(wallet!.descriptor)\", [\(index),\(index)]"

                Reducer.makeCommand(walletName: wallet!.name!, command: .deriveaddresses, param: param) { (object, errorDesc) in

                    if let addresses = object as? NSArray {

                        updateIndex(wallet: wallet!)

                        if let address = addresses[0] as? String {

                            completion((address,false))

                        } else {

                            completion((nil,true))

                        }

                    } else {

                        completion((nil,true))

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

}
