//
//  XpubConverter.swift
//  FullyNoded2
//
//  Created by Peter on 05/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import Foundation

class XpupConverter {
    
    class func convert(xpub: String) {
        
        //let xpubPrefix = "0488b21e"
//        let tpubPrefix = "043587cf"
        
//        let otherPrefixes =
//            [
//                "ypub": "049d7cb2",
//                "Ypub": "0295b43f",
//                "zpub": "04b24746",
//                "Zpub": "02aa7ed3",
//                "upub": "044a5262",
//                "Upub": "024289ef",
//                "vpub": "045f1cf6",
//                "Vpub": "02575483"
//        ]
        
//        var b58 = Base58.decode(xpub)
//        b58.removeFirst(4)
//        var prefix = Data(tpubPrefix)!
//        prefix.append(contentsOf: b58)
//        let array = [UInt8](prefix)
//        let tpub = Base58.encode(array)
//        print("tpub = \(tpub)")
        
        //let tpubwithoutchecksum = "tpubDF1KdVPYeyvXCb1B7B9SkvWBcpeqQqJwenDDprb7khy8JcHhYkL3TapsSPUvsBx68jDP1qc1hbDi5doNbbAHVDf1X4DfSixMNUHNC"
        
        // Original:
        // tpubDF1KdVPYeyvXCb1B7B9SkvWBcpeqQqJwenDDprb7khy8JcHhYkL3TapsSPUvsBx68jDP1qc1hbDi5doNbbAHVDf1X4DfSixMNUHNCDSgUzS
        
        // Converts to (using Lopps tool):
        // Vpub5msFd9xUDJSUembTvw45xuKcfZJYkZWUbCE9pn1k2ZHt5JZSjcY7A8hgxeSSuJuum1Wqmtu98P54k3hQ4Zdy9nxBZFBuzn898nqYF1Z5Dwk
        
        // Results in:
        // tpubDF1KdVPYeyvXCb1B7B9SkvWBcpeqQqJwenDDprb7khy8JcHhYkL3TapsSPUvsBx68jDP1qc1hbDi5doNbbAHVDf1X4DfSixMNUHNCFWtSLW
                
    }
}

/// Just some example code to help...

/*
 private static String xlatXPUB(String xpub, boolean isBIP84) throws AddressFormatException {

     final int MAGIC_XPUB = 0x0488B21E;
     final int MAGIC_TPUB = 0x043587CF;
     final int MAGIC_YPUB = 0x049D7CB2;
     final int MAGIC_UPUB = 0x044A5262;
     final int MAGIC_ZPUB = 0x04B24746;
     final int MAGIC_VPUB = 0x045F1CF6;

     byte[] xpubBytes = Base58.decodeChecked(xpub);

     ByteBuffer bb = ByteBuffer.wrap(xpubBytes);
     int ver = bb.getInt();
     if(ver != MAGIC_XPUB && ver != MAGIC_TPUB && ver != MAGIC_YPUB && ver != MAGIC_UPUB && ver != MAGIC_ZPUB && ver != MAGIC_VPUB)   {
         throw new AddressFormatException("invalid xpub version");
     }

     int xlatVer = 0;
     switch(ver)    {
         case MAGIC_XPUB:
             xlatVer = isBIP84 ? MAGIC_ZPUB : MAGIC_YPUB;
             break;
         case MAGIC_YPUB:
             xlatVer = MAGIC_XPUB;
             break;
         case MAGIC_TPUB:
             xlatVer = isBIP84 ? MAGIC_VPUB : MAGIC_UPUB;
             break;
         case MAGIC_UPUB:
             xlatVer = MAGIC_TPUB;
             break;
         case MAGIC_ZPUB:
             xlatVer = MAGIC_XPUB;
             break;
         case MAGIC_VPUB:
             xlatVer = MAGIC_TPUB;
             break;
     }

     ByteBuffer b = ByteBuffer.allocate(4);
     b.putInt(xlatVer);
     byte[] bVer = b.array();

     System.arraycopy(bVer, 0, xpubBytes, 0, bVer.length);

     // append checksum
     byte[] checksum = Arrays.copyOfRange(Sha256Hash.hashTwice(xpubBytes), 0, 4);
     byte[] xlatXpub = new byte[xpubBytes.length + checksum.length];
     System.arraycopy(xpubBytes, 0, xlatXpub, 0, xpubBytes.length);
     System.arraycopy(checksum, 0, xlatXpub, xlatXpub.length - 4, checksum.length);

     String ret = Base58.encode(xlatXpub);

     return ret;
 }
 */
