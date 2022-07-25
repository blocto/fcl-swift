//
//  File.swift
//
//
//  Created by Andrew Wang on 2022/7/11.
//

import Foundation
import Cadence

public struct FCLAccountProofData {
    /// A human-readable string e.g. "Blocto", "NBA Top Shot"
    public let appId: String
    /// minimum 32-byte random nonce
    public let nonce: String

    public init(appId: String, nonce: String) {
        self.appId = appId
        self.nonce = nonce
    }

}

public struct AccountProofSignatureData {

    let address: Address
    let nonce: String
    let signatures: [FCLCompositeSignature]

    public init(
        address: Address,
        nonce: String,
        signatures: [FCLCompositeSignature]
    ) {
        self.address = address
        self.nonce = nonce
        self.signatures = signatures
    }
}
