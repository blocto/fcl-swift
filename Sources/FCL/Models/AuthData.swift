//
//  AuthData.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/6.
//

import Foundation

struct AuthData: Decodable {
    let fclType: String?
    let fclVersion: String?
    let address: String? // exist in dapper wallet authn response, blocto api/flow/payer
    let services: [Service]
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
        case signature
        case proposer
        case payer
        case authorization
    }
}
