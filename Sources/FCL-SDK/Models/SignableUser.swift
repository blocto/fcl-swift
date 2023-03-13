//
//  SignableUser.swift
//  FCL-SDK
//
//  Created by Andrew Wang on 2022/8/16.
//

import Foundation
import Cadence

struct SignableUser: Codable {
    var address: Cadence.Address
    var keyId: UInt32
    var role: Role

    // Assigned in SignatureResolver
    var signature: String?
    // Assigned in SequenceNumberResolver
    var sequenceNum: UInt64?

    var tempId: String {
        address.hexString + "-" + String(keyId)
    }

    var signingFunction: (Data) async throws -> AuthResponse

    enum CodingKeys: String, CodingKey {
        case address = "addr"
        case keyId
        case role
        case signature
        case sequenceNum
        case tempId
    }

    init(
        address: Address,
        keyId: UInt32,
        role: Role,
        signature: String? = nil,
        sequenceNum: UInt64? = nil,
        signingFunction: @escaping (Data) async throws -> AuthResponse
    ) {
        self.address = address
        self.keyId = keyId
        self.role = role
        self.signature = signature
        self.sequenceNum = sequenceNum
        self.signingFunction = signingFunction
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        self.address = try container.decode(Cadence.Address.self, forKey: .address)
        self.keyId = try container.decode(UInt32.self, forKey: .keyId)
        self.role = try container.decode(Role.self, forKey: .role)
        self.signature = try container.decodeIfPresent(String.self, forKey: .signature)
        self.sequenceNum = try container.decodeIfPresent(UInt64.self, forKey: .sequenceNum)
        self.signingFunction = { _ in
            throw FCLError.unsupported
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address.hexString, forKey: .address)
        try container.encode(keyId, forKey: .keyId)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(signature, forKey: .signature)
        try container.encodeIfPresent(sequenceNum, forKey: .sequenceNum)
        try container.encode(tempId, forKey: .tempId)
    }
}
