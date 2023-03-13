//
//  FCLCompositeSignature.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public protocol CompositeSignatureVerifiable {
    var address: String { get }
    var keyId: Int { get }
    var signature: String { get }
}

public struct FCLCompositeSignature: CompositeSignatureVerifiable, Codable {

    public let fclType: String
    public let fclVersion: String
    public let address: String
    public let keyId: Int
    // hex string
    public let signature: String

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address = "addr"
        case keyId
        case signature
    }

    public init(
        address: String,
        keyId: Int,
        signature: String
    ) {
        self.fclType = Pragma.compositeSignature.fclType
        self.fclVersion = Pragma.compositeSignature.fclVersion
        self.address = address
        self.keyId = keyId
        self.signature = signature
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fclType, forKey: .fclType)
        try container.encode(fclVersion, forKey: .fclVersion)
        try container.encode(address, forKey: .address)
        try container.encode(keyId, forKey: .keyId)
        try container.encode(signature, forKey: .signature)
    }

}
