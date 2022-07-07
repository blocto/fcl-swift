//
//  File.swift
//
//
//  Created by Andrew Wang on 2022/7/6.
//

import Foundation

struct AuthnData: Decodable {
    let fclType: String?
    let fclVersion: String?
    let address: String
    let services: [Service]
//    let proposer: Service?
//    let payer: [Service]?
//    let authorization: [Service]?
//    let signature: String?

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address = "addr"
    }
}
