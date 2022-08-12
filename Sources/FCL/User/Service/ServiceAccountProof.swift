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
    let signatures: [FCLCompositeSignature]

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address
        case nonce
        case signatures
    }

}
