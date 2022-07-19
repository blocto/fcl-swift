//
//  CompositeSignature.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public struct FCLCompositeSignature: Decodable {

    let fclType: String
    let fclVersion: String
    let address: String
    let keyId: Int
    // hex string
    let signature: String

    enum CodingKeys: String, CodingKey {
        case fclType = "fType"
        case fclVersion = "fVsn"
        case address = "addr"
        case keyId
        case signature
    }

    public init(
        address: String,
        keyId: Int,
        signature: String
    ) {
        self.fclType = "CompositeSignature"
        self.fclVersion = "1.0.0"
        self.address = address
        self.keyId = keyId
        self.signature = signature
    }

}
