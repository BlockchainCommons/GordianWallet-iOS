//
//  UniformResource.swift
//  GordianWallet
//
//  Created by Peter on 09/08/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation
import URKit

enum URHelper {
    
    static func entropyToUr(data: Data) -> String? {
        let wrapper:CBOR = .map([
            .unsignedInt(1) : .byteString(data.bytes),
        ])
        let cbor = Data(wrapper.cborEncode())
        do {
            let rawUr = try UR(type: "crypto-seed", cbor: cbor)
            return UREncoder.encode(rawUr)
        } catch {
            return nil
        }
    }
    
    static func shardToUr(data: Data) -> String? {
        let wrapper:CBOR = .tagged(.init(rawValue: 309), .byteString(data.bytes))
        let cbor = Data(wrapper.cborEncode())
        do {
            let rawUr = try UR(type: "crypto-sskr", cbor: cbor)
            return UREncoder.encode(rawUr)
        } catch {
            return nil
        }
    }
    
    static func urToEntropy(urString: String) -> (data: Data?, birthdate: UInt64?) {
        do {
            let ur = try URDecoder.decode(urString)
            let decodedCbor = try CBOR.decode(ur.cbor.bytes)
            guard case let CBOR.map(dict) = decodedCbor! else { return (nil, nil) }
            var data:Data?
            var birthdate:UInt64?
            for (key, value) in dict {
                switch key {
                case 1:
                    guard case let CBOR.byteString(byteString) = value else { fallthrough }
                    data = Data(byteString)
                case 2:
                    guard case let CBOR.unsignedInt(n) = value else { fallthrough }
                    birthdate = n
                default:
                    break
                }
            }
            return (data, birthdate)
        } catch {
            return (nil, nil)
        }
    }
    
    static func urToShard(sskrUr: String) -> String? {
        guard let ur = try? URDecoder.decode(sskrUr),
            let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
            case let CBOR.tagged(_, cborRaw) = decodedCbor,
            case let CBOR.byteString(byteString) = cborRaw else { return nil }
        return Data(byteString).hexString
    }
    
    static func urToHdkey(urString: String) -> (isMaster: Bool?, keyData: String?, chainCode: String?) {
        do {
            let ur = try URDecoder.decode(urString)
            let decodedCbor = try CBOR.decode(ur.cbor.bytes)
            guard case let CBOR.map(dict) = decodedCbor! else { return (nil, nil, nil) }
            var isMaster:Bool?
            var keyData:String?
            var chainCode:String?
            for (key, value) in dict {
                switch key {
                case 1:
                    guard case let CBOR.boolean(b) = value else { fallthrough }
                    isMaster = b
                case 3:
                    guard case let CBOR.byteString(bs) = value else { fallthrough }
                    keyData = Data(bs).hexString
                case 4:
                    guard case let CBOR.byteString(bs) = value else { fallthrough }
                    chainCode = Data(bs).hexString
                default:
                    break
                }
            }
            return (isMaster, keyData, chainCode)
        } catch {
            return (nil, nil, nil)
        }
    }
    
    static func psbtUr(_ data: Data) -> UR? {
        let cbor = CBOR.byteString(data.bytes).cborEncode().data
        
        return try? UR(type: "crypto-psbt", cbor: cbor)
    }
    
    static func psbtUrToBase64Text(_ ur: UR) -> String? {
        guard let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
            case let CBOR.byteString(bytes) = decodedCbor else {
                return nil
        }
        
        return Data(bytes).base64EncodedString()
    }
    
    static func xpubToUrHdkey(_ xpub: String, _ fingerprint: String, _ cointype: UInt64) -> String? {
        /// Decodes our original extended key to base58 data.
        let b58 = Base58.decode(xpub)
        let b58Data = Data(b58)
        let depth = b58Data.subdata(in: Range(4...4))
        let parentFingerprint = b58Data.subdata(in: Range(5...8))
        let childIndex = b58Data.subdata(in: Range(9...12))
        guard childIndex.hexString == "80000002" else { return nil }
        let chaincode = b58Data.subdata(in: Range(13...44))
        let keydata = b58Data.subdata(in: Range(45...77))
        
        var originsArray:[OrderedMapEntry] = []
        originsArray.append(.init(key: 1, value: .array([.unsignedInt(48), true, .unsignedInt(cointype), true, .unsignedInt(0), true, .unsignedInt(2), true])))
        originsArray.append(.init(key: 2, value: .unsignedInt(UInt64(fingerprint, radix: 16) ?? 0)))
        originsArray.append(.init(key: 3, value: .unsignedInt(UInt64(depth.hexString) ?? 0)))
        let originsWrapper = CBOR.orderedMap(originsArray)
        
        let useInfoWrapper:CBOR = .map([
            .unsignedInt(2) : .unsignedInt(cointype)
        ])
        
        guard let hexValue = UInt64(parentFingerprint.hexString, radix: 16) else { return nil }
        
        var hdkeyArray:[OrderedMapEntry] = []
        hdkeyArray.append(.init(key: 1, value: .boolean(false)))
        hdkeyArray.append(.init(key: 2, value: .boolean(false)))
        hdkeyArray.append(.init(key: 3, value: .byteString([UInt8](keydata))))
        hdkeyArray.append(.init(key: 4, value: .byteString([UInt8](chaincode))))
        hdkeyArray.append(.init(key: 5, value: .tagged(CBOR.Tag(rawValue: 305), useInfoWrapper)))
        hdkeyArray.append(.init(key: 6, value: .tagged(CBOR.Tag(rawValue: 304), originsWrapper)))
        hdkeyArray.append(.init(key: 8, value: .unsignedInt(hexValue)))
        let hdKeyWrapper = CBOR.orderedMap(hdkeyArray)
        
        guard let rawUr = try? UR(type: "crypto-hdkey", cbor: hdKeyWrapper) else { return nil }
        
        return UREncoder.encode(rawUr)
    }
}
