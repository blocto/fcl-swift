//
//  AuthData.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/6.
//

import Foundation

public struct AuthData: Codable {
    let fclType: String?
    let fclVersion: String?
    let address: String? // exist in dapper wallet authn response, blocto api/flow/payer
    let services: [Service]?
    let keyId: Int? // exist in user signature
    let signature: String? // exist in blocto api/flow/payer

    // pre-authz response (blocto only)
    let proposer: Service?
    let payer: [Service]?
    let authorization: [Service]?

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address = "addr"
        case services
        case keyId
        case signature
        case proposer
        case payer
        case authorization
    }

    public init(
        address: String,
        services: [Service]
    ) {
        self.fclType = nil
        self.fclVersion = nil
        self.address = address
        self.services = services
        self.keyId = nil
        self.signature = nil
        self.proposer = nil
        self.payer = nil
        self.authorization = nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fclType = try container.decodeIfPresent(String.self, forKey: .fclType)
        self.fclVersion = try container.decodeIfPresent(String.self, forKey: .fclVersion)
        self.address = try container.decodeIfPresent(String.self, forKey: .address)
        self.services = try container.decodeIfPresent([Service].self, forKey: .services)
        self.keyId = try container.decodeIfPresent(Int.self, forKey: .keyId)
        self.signature = try container.decodeIfPresent(String.self, forKey: .signature)
        self.proposer = try container.decodeIfPresent(Service.self, forKey: .proposer)
        self.payer = try container.decodeIfPresent([Service].self, forKey: .payer) ?? []
        self.authorization = try container.decodeIfPresent([Service].self, forKey: .authorization) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(fclType, forKey: .fclType)
        try container.encodeIfPresent(fclVersion, forKey: .fclVersion)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(services, forKey: .services)
        try container.encodeIfPresent(keyId, forKey: .keyId)
        try container.encodeIfPresent(signature, forKey: .signature)
        try container.encodeIfPresent(proposer, forKey: .proposer)
        try container.encodeIfPresent(payer, forKey: .payer)
        try container.encodeIfPresent(authorization, forKey: .authorization)
    }

    init(
        proposer: Service?,
        payer: [Service]?,
        authorization: [Service]?
    ) {
        self.fclType = nil
        self.fclVersion = nil
        self.address = nil
        self.services = nil
        self.keyId = nil
        self.signature = nil
        self.proposer = proposer
        self.payer = payer
        self.authorization = authorization
    }
}
