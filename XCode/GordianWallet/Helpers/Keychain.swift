//
//  Keychain.swift
//  FullyNoded2
//
//  Created by Peter on 09/04/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class KeyChain {
    
    class func seeds() -> [Data]? {
        if let seeds = KeyChain.getSeed("seeds") {
            do {
                guard let encryptedSeeds = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(seeds) as? [Data] else {
                    fatalError("Can't get seeds")
                }
                return encryptedSeeds
            } catch {
                fatalError("Can't encode data: \(error)")
            }
        } else {
            return nil
        }
    }
    
    class func overWriteExistingSeeds(unencryptedSeeds: [String], completion: @escaping ((Bool)) -> Void) {
        var encrpytedSeeds:[Data] = []
        if unencryptedSeeds.count > 0 {
            for (i, unencryptedSeed) in unencryptedSeeds.enumerated() {
                Encryption.encryptData(dataToEncrypt: unencryptedSeed.dataUsingUTF8StringEncoding) { (encryptedData, error) in
                    if encryptedData != nil {
                        encrpytedSeeds.append(encryptedData!)
                        if i + 1 == unencryptedSeeds.count {
                            do {
                                let updatedEncryptedSeedArray = try NSKeyedArchiver.archivedData(withRootObject: encrpytedSeeds, requiringSecureCoding: true)
                                if KeyChain.setSeed(updatedEncryptedSeedArray, forKey: "seeds") {
                                    completion(true)
                                } else {
                                    completion(false)
                                }
                            } catch {
                                completion(false)
                            }
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        } else {
            do {
                let updatedEncryptedSeedArray = try NSKeyedArchiver.archivedData(withRootObject: [], requiringSecureCoding: true)
                if KeyChain.setSeed(updatedEncryptedSeedArray, forKey: "seeds") {
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }
    }
    
    class func saveNewSeed(encryptedSeed: Data) -> Bool {
        if let seeds = KeyChain.seeds() {
            var existingEncryptedSeeds = seeds
            existingEncryptedSeeds.append(encryptedSeed)
            do {
                let updatedEncryptedSeedArray = try NSKeyedArchiver.archivedData(withRootObject: existingEncryptedSeeds, requiringSecureCoding: true)
                if KeyChain.setSeed(updatedEncryptedSeedArray, forKey: "seeds") {
                    return true
                } else {
                    return false
                }
            } catch {
                return false
            }
        } else {
            /// Seed has never been added.
            do {
                let seedArray:NSArray = [encryptedSeed]
                let updatedEncryptedSeedArray = try NSKeyedArchiver.archivedData(withRootObject: seedArray, requiringSecureCoding: true)
                if KeyChain.setSeed(updatedEncryptedSeedArray, forKey: "seeds") {
                    return true
                } else {
                    return false
                }
            } catch {
                return false
            }
        }
    }
    
    class func setSeed(_ data: Data, forKey: String) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrSynchronizable as String : kCFBooleanFalse!,
            kSecAttrAccessible as String : kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccount as String : forKey,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == noErr {
            return true
        } else {
            if let err = SecCopyErrorMessageString(status, nil) {
                print("Set failed: \(err)")
            }
            return false
        }
    }
    
    class func getSeed(_ key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecAttrAccessible as String : kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String : kCFBooleanFalse!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            if let err = SecCopyErrorMessageString(status, nil) {
                print("Get failed: \(err)")
            }
            return nil
        }
    }

    class func set(_ data: Data, forKey: String) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrSynchronizable as String : kCFBooleanTrue!,
            kSecAttrAccessible as String : kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: "YZHG975W3A.com.blockchaincommons.sharedItems",
            kSecAttrAccount as String : forKey,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == noErr {
            return true
        } else {
            if let err = SecCopyErrorMessageString(status, nil) {
                print("Set failed: \(err)")
            }
            return false
        }
    }

    class func getData(_ key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecAttrAccessible as String : kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String : kCFBooleanTrue!,
            kSecAttrAccessGroup as String: "YZHG975W3A.com.blockchaincommons.sharedItems",
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            if let err = SecCopyErrorMessageString(status, nil) {
                print("Get failed: \(err)")
            }
            return nil
        }
    }
    
    class func remove(key: String) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrSynchronizable as String : kCFBooleanTrue!,
            kSecAttrAccessible as String : kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccount as String : key] as [String : Any]

        // Delete any existing items
        let status = SecItemDelete(query as CFDictionary)
        if (status != errSecSuccess) {
            if let err = SecCopyErrorMessageString(status, nil) {
                print("Remove failed: \(err)")
            }
            return false
        } else {
            return true
        }

    }
    
    class func removeAll() {
        let secItemClasses =  [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            SecItemDelete(spec)
        }
    }

    private func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)

        let swiftString: String = cfStr as String
        return swiftString
    }
}

extension Data {
    init<T>(value: T) {
        self = withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) -> Data in
            return Data(buffer: UnsafeBufferPointer(start: ptr, count: 1))
        }
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
}
