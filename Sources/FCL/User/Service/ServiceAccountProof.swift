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
    let timestamp: TimeInterval

    enum CodingKeys: String, CodingKey {
        case fclType = "fType"
        case fclVersion = "fVsn"
        case address
        case nonce
        case signatures
        case timestamp
    }

    public init(
        address: String,
        nonce: String,
        signatures: [FCLCompositeSignature],
        timestamp: TimeInterval = 0
    ) {
        self.fclType = Pragma.servicePragma.fclType
        self.fclVersion = Pragma.servicePragma.fclVersion
        self.address = address
        self.nonce = nonce
        self.signatures = signatures
        self.timestamp = timestamp
    }
}
