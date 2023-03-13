//
//  ServiceAccountProof.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public struct ServiceAccountProof: Codable {

    let fclType: String
    let fclVersion: String
    let address: String
    let nonce: String
    let signatures: [FCLCompositeSignature]

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address
        case nonce
        case signatures
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fclType, forKey: .fclType)
        try container.encode(fclVersion, forKey: .fclVersion)
        try container.encode(address, forKey: .address)
        try container.encode(nonce, forKey: .nonce)
        try container.encode(signatures, forKey: .signatures)
    }

}
