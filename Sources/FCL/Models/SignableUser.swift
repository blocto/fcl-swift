//
//  SignableUser.swift
//  FCL-SDK
//
//  Created by Andrew Wang on 2022/8/16.
//

import Foundation
import Cadence

struct SignableUser: Encodable {
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address.hexString, forKey: .address)
        try container.encode(keyId, forKey: .keyId)
        try container.encode(role, forKey: .role)
        try container.encode(signature, forKey: .signature)
        try container.encode(sequenceNum, forKey: .sequenceNum)
        try container.encode(tempId, forKey: .tempId)
    }
}
