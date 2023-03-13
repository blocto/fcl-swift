//
//  ServiceIdentity.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public struct ServiceIdentity: Codable {
    public let fclType: String? // proposer, payer, authorization in PreAuthzResponse do not have this key.
    public let fclVersion: String? // proposer, payer, authorization in PreAuthzResponse do not have this key.
    public let address: String
    let keyId: UInt32?

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address
        case keyId
    }

    public init(
        fclType: String? = nil,
        fclVersion: String? = nil,
        address: String,
        keyId: UInt32? = nil
    ) {
        self.fclType = fclType
        self.fclVersion = fclVersion
        self.address = address
        self.keyId = keyId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(fclType, forKey: .fclType)
        try container.encodeIfPresent(fclVersion, forKey: .fclVersion)
        try container.encode(address, forKey: .address)
        try container.encode(keyId, forKey: .keyId)
    }
}
