//
//  PreAuthzResponse.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public struct PreAuthzResponse: Decodable {
    public let fType: String
    public let fVsn: String
    let status: Status
    let proposer: null // Singular Authz Service,
    let payer: [] // Multiple Authz Services (for same Flow Address (different KeyId))
    let authorization: [] // Multiple Authz Services (for same Flow Address (different KeyId))
//    let data: AuthData
}
