//
//  File.swift
//
//
//  Created by Andrew Wang on 2022/7/11.
//

import Foundation

 public struct FCLAccountProofData {
     /// A human-readable string e.g. "Blocto", "NBA Top Shot"
     public let appId: String
     /// minimum 32-byte random nonce
     public let nonce: String
 }

public struct AccountProofSignatureData {

    let address: String
    let nonce: String
    let signatures: [FCLCompositeSignature]

    public init(
        address: String,
        nonce: String,
        signatures: [FCLCompositeSignature]
    ) {
        self.address = address
        self.nonce = nonce
        self.signatures = signatures
    }
}
