//
//  ServiceIdentity.swift
//  
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

struct ServiceIdentity: Decodable {
    public let fclType: String? // proposer, payer, authorization in PreAuthzResponse do not have this key.
    public let fclVersion: String? // proposer, payer, authorization in PreAuthzResponse do not have this key.
    public let address: String
    let keyId: UInt32
    
    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address
        case keyId
    }
}
