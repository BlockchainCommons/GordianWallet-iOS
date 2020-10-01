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
        let cbor = Data(wrapper.encode())
        do {
            let rawUr = try UR(type: "crypto-seed", cbor: cbor)
            return UREncoder.encode(rawUr)
        } catch {
            return nil
        }
    }
    
    static func shardToUr(data: Data) -> String? {
        let wrapper:CBOR = .tagged(.init(rawValue: 309), .byteString(data.bytes))
        let cbor = Data(wrapper.encode())
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
        do {
            let ur = try URDecoder.decode(sskrUr)
            guard let decodedCbor = try? CBOR.decode(ur.cbor.bytes),
                case let CBOR.tagged(_, cborRaw) = decodedCbor,
                case let CBOR.byteString(byteString) = cborRaw else { return nil }
            return Data(byteString).hexString
        } catch {
            return nil
        }
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
}
