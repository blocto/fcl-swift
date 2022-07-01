//
//  CompositeSignature.swift
//  
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

struct CompositeSignature: Decodable {
    let fclType: String
    let fclVersion: String
    let address: String
    let keyId: UInt
    // hex string
    let signature: String
    
    enum CodingKeys: String, CodingKey {
        case fType
        case fVsn
        case address = "addr"
        case keyId
        case signature
    }
}
