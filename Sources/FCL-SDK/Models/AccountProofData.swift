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

public protocol AccountProofVerifiable {
    var address: Address { get }
    var nonce: String { get }
    var signatures: [CompositeSignatureVerifiable] { get }
}

public struct AccountProofSignatureData: AccountProofVerifiable {

    public let address: Address
    public let nonce: String
    public let signatures: [CompositeSignatureVerifiable]

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
