//
//  ServiceAccountProof.swift
//  
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public struct ServiceAccountProof: Decodable {
    let fclType: String
    let fclVersion: String
    let address: String
    let nonce: String
    let signatures: [CompositeSignature]
    let timestamp: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case fclType = "fType"
        case fclVersion = "fVsn"
        case address
        case nonce
        case signatures
        case timestamp
    }
}
