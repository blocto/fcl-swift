//
//  File.swift
//
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation
import Cadence

public struct User: Decodable {

    var fclType: String = Pragma.userPragma.fclType
    var fclVersion: String = Pragma.userPragma.fclVersion
    let address: Address
    var loggedIn: Bool = false
    let expiresAt: TimeInterval
    var accountProof: AccountProofSignatureData?
    let services: [Service]

    var expiresAtDate: Date {
        Date(timeIntervalSince1970: expiresAt)
    }

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address = "addr"
        case loggedIn
        case expiresAt
        case services
    }

    init(
        fclType: String,
        fclVersion: String,
        address: Address,
        accountProof: AccountProofSignatureData?,
        loggedIn: Bool = false,
        expiresAt: TimeInterval,
        services: [Service]
    ) {
        self.fclType = fclType
        self.fclVersion = fclVersion
        self.address = address
        self.accountProof = accountProof
        self.loggedIn = loggedIn
        self.expiresAt = expiresAt
        self.services = services
    }
    
    init(
        address: Address,
        accountProof: AccountProofSignatureData?,
        loggedIn: Bool = false,
        expiresAt: TimeInterval,
        services: [Service]
    ) {
        self.address = address
        self.accountProof = accountProof
        self.loggedIn = loggedIn
        self.expiresAt = expiresAt
        self.services = services
    }

}
