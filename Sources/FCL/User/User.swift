//
//  File.swift
//
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation
import Cadence

public struct User: Decodable {

    var fclType: String = "USER"
    var fclVersion: String = "1.0.0"
    let address: Address
    var loggedIn: Bool = false
    let expiresAt: TimeInterval
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

    internal init(
        fclType: String = "USER",
        fclVersion: String = "1.0.0",
        address: Address,
        loggedIn: Bool = false,
        expiresAt: TimeInterval,
        services: [Service]
    ) {
        self.fclType = fclType
        self.fclVersion = fclVersion
        self.address = address
        self.loggedIn = loggedIn
        self.expiresAt = expiresAt
        self.services = services
    }

}
