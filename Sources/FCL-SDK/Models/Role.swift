//
//  Role.swift
//  FCL-SDK
//
//  Created by Andrew Wang on 2022/8/16.
//

import Foundation

struct Role: Encodable {
    var proposer: Bool = false
    var authorizer: Bool = false
    var payer: Bool = false
    var param: Bool?
    
    mutating func merge(role: Role) {
        proposer = proposer || role.proposer
        authorizer = authorizer || role.authorizer
        payer = payer || role.payer
    }
}
